"""Noise/drift injection, centered moving-average compensation, and metrics."""

from __future__ import annotations

import csv
import math
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from numpy.typing import NDArray

from soil_sensor.model import admittance
from soil_sensor.parameters import SensorParameters


@dataclass(frozen=True, slots=True)
class CompensationMetrics:
    """Summary error metrics comparing raw vs. compensated EC estimates."""

    rmse_raw: float
    rmse_comp: float
    rmse_raw_pct: float
    rmse_comp_pct: float
    max_err_raw: float
    max_err_comp: float
    std_err_raw: float
    std_err_comp: float
    mean_err_raw: float
    mean_err_comp: float


@dataclass(frozen=True, slots=True)
class ArchivedCompensationSummary:
    """Verification metrics derived from archived compensation_signals.csv."""

    samples: int
    max_movmean_diff_a: float
    full_metrics: CompensationMetrics
    short_window_rmse_s_cm: float
    short_window_rmse_pct: float
    edge_start_std_raw: float
    edge_start_std_comp: float
    edge_end_std_raw: float
    edge_end_std_comp: float
    edge_start_rmse_raw: float
    edge_start_rmse_comp: float
    edge_end_rmse_raw: float
    edge_end_rmse_comp: float


def matlab_movmean(x: NDArray[np.float64], window: int) -> NDArray[np.float64]:
    """Centered moving average matching MATLAB's movmean(x, k) boundary truncation."""
    if window < 1:
        raise ValueError(f"Moving average window must be >= 1, got {window}")
    n = len(x)
    left = window // 2
    right = window - 1 - left
    cs = np.concatenate(([0.0], np.cumsum(x, dtype=np.float64)))
    idx = np.arange(n)
    lo = np.maximum(0, idx - left)
    hi = np.minimum(n - 1, idx + right)
    return (cs[hi + 1] - cs[lo]) / (hi - lo + 1)


def generate_ec_trajectory(
    t_vec: NDArray[np.float64],
    r_soil_levels: tuple[float, ...],
    switch_times_s: tuple[float, ...],
    params: SensorParameters,
) -> tuple[NDArray[np.float64], NDArray[np.float64], NDArray[np.float64]]:
    """Generate piecewise-constant EC_true [S/cm], R_soil_true [Ohm], and I_true [A]."""
    if len(r_soil_levels) != len(switch_times_s):
        raise ValueError("r_soil_levels and switch_times_s must have the same length")
    r_levels = np.asarray(r_soil_levels, dtype=np.float64)
    ec_levels = params.cell_constant_cm_inv / r_levels
    i_levels = np.array(
        [
            abs(admittance(params, float(r_val), params.excitation_freq_hz)) * params.peak_voltage_v
            for r_val in r_soil_levels
        ],
        dtype=np.float64,
    )
    indices = np.searchsorted(switch_times_s, t_vec, side="right") - 1
    indices = np.clip(indices, 0, len(ec_levels) - 1)
    return ec_levels[indices], r_levels[indices], i_levels[indices]


def add_noise_and_drift(
    i_true: NDArray[np.float64],
    t_vec: NDArray[np.float64],
    snr_db: float = 30.0,
    drift_amp: float = 0.08,
    drift_freq_hz: float = 0.05,
    rng: np.random.Generator | None = None,
) -> tuple[NDArray[np.float64], NDArray[np.float64], NDArray[np.float64]]:
    """Inject AWGN at snr_db and sinusoidal baseline drift onto ideal current."""
    generator = rng if rng is not None else np.random.default_rng(42)
    p_signal = float(np.mean(i_true**2))
    p_noise = p_signal / (10.0 ** (snr_db / 10.0))
    noise = math.sqrt(p_noise) * generator.standard_normal(len(i_true))
    i_mean = float(np.mean(np.abs(i_true)))
    drift = (drift_amp * i_mean) * np.sin(2.0 * math.pi * drift_freq_hz * t_vec)
    i_meas = i_true + drift + noise
    return i_meas, noise, drift


def apply_compensation_filter(
    i_meas: NDArray[np.float64],
    window_noise: int = 500,
    window_drift: int = 5000,
) -> tuple[NDArray[np.float64], NDArray[np.float64], NDArray[np.float64]]:
    """Reproduce compensation_filter.m: short/long movmean and I_comp = I_lowpass."""
    i_filt = matlab_movmean(i_meas, window_noise)
    i_lowpass = matlab_movmean(i_meas, window_drift)
    b_est = i_lowpass - i_filt
    return i_lowpass, i_filt, b_est


def invert_calibration_lookup(
    i_samples: NDArray[np.float64],
    r_min_ohm: float,
    r_max_ohm: float,
    params: SensorParameters,
    n_grid: int = 500,
) -> tuple[NDArray[np.float64], NDArray[np.float64]]:
    """Invert current samples back to (R_est [Ohm], EC_est [S/cm]) via logspace lookup."""
    r_calib = np.logspace(math.log10(r_min_ohm), math.log10(r_max_ohm), n_grid)
    i_calib = np.array(
        [
            abs(admittance(params, float(r), params.excitation_freq_hz)) * params.peak_voltage_v
            for r in r_calib
        ],
        dtype=np.float64,
    )
    order = np.argsort(i_calib)
    i_sorted = i_calib[order]
    r_sorted = r_calib[order]
    # Linear extrapolation at ends matching MATLAB interp1(..., 'linear', 'extrap')
    r_est = np.interp(i_samples, i_sorted, r_sorted)
    low_mask = i_samples < i_sorted[0]
    high_mask = i_samples > i_sorted[-1]
    if np.any(low_mask):
        slope_lo = (r_sorted[1] - r_sorted[0]) / (i_sorted[1] - i_sorted[0])
        r_est[low_mask] = r_sorted[0] + slope_lo * (i_samples[low_mask] - i_sorted[0])
    if np.any(high_mask):
        slope_hi = (r_sorted[-1] - r_sorted[-2]) / (i_sorted[-1] - i_sorted[-2])
        r_est[high_mask] = r_sorted[-1] + slope_hi * (i_samples[high_mask] - i_sorted[-1])
    ec_est = params.cell_constant_cm_inv / r_est
    return r_est, ec_est


def compute_error_metrics(
    ec_true: NDArray[np.float64],
    ec_raw: NDArray[np.float64],
    ec_est: NDArray[np.float64],
) -> CompensationMetrics:
    """Compute raw vs. compensated EC error metrics matching error_metrics.m."""
    err_raw = ec_raw - ec_true
    err_comp = ec_est - ec_true
    rmse_raw = float(np.sqrt(np.mean(err_raw**2)))
    rmse_comp = float(np.sqrt(np.mean(err_comp**2)))
    ec_mean = float(np.mean(ec_true))
    return CompensationMetrics(
        rmse_raw=rmse_raw,
        rmse_comp=rmse_comp,
        rmse_raw_pct=(rmse_raw / ec_mean) * 100.0,
        rmse_comp_pct=(rmse_comp / ec_mean) * 100.0,
        max_err_raw=float(np.max(np.abs(err_raw))),
        max_err_comp=float(np.max(np.abs(err_comp))),
        std_err_raw=float(np.std(err_raw, ddof=1)),
        std_err_comp=float(np.std(err_comp, ddof=1)),
        mean_err_raw=float(np.mean(err_raw)),
        mean_err_comp=float(np.mean(err_comp)),
    )


def evaluate_archived_compensation(
    csv_path: Path,
    params: SensorParameters,
) -> ArchivedCompensationSummary:
    """Verify archived compensation_signals.csv and compute steady-state edge slices."""
    with csv_path.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))

    t_vec = np.array([float(r["Time_s"]) for r in rows], dtype=np.float64)
    ec_true = np.array([float(r["EC_true"]) for r in rows], dtype=np.float64)
    i_meas = np.array([float(r["I_meas_A"]) for r in rows], dtype=np.float64)
    i_comp_csv = np.array([float(r["I_comp_A"]) for r in rows], dtype=np.float64)
    ec_raw = np.array([float(r["EC_raw"]) for r in rows], dtype=np.float64)
    ec_est = np.array([float(r["EC_est"]) for r in rows], dtype=np.float64)

    i_comp_repro, i_filt_500, _ = apply_compensation_filter(i_meas, 500, 5000)
    max_diff = float(np.max(np.abs(i_comp_csv - i_comp_repro)))
    full_metrics = compute_error_metrics(ec_true, ec_raw, ec_est)

    _, ec_short = invert_calibration_lookup(i_filt_500, 10e3, 100e3, params)
    short_rmse = float(np.sqrt(np.mean((ec_short - ec_true) ** 2)))
    short_rmse_pct = (short_rmse / float(np.mean(ec_true))) * 100.0

    # Intervals >=2.5 s away from interior 4 s step edges (where 5 s centered window stays flat)
    m_start = (t_vec >= 0.0) & (t_vec <= 1.5)
    m_end = (t_vec >= 18.5) & (t_vec <= 20.0)

    return ArchivedCompensationSummary(
        samples=len(rows),
        max_movmean_diff_a=max_diff,
        full_metrics=full_metrics,
        short_window_rmse_s_cm=short_rmse,
        short_window_rmse_pct=short_rmse_pct,
        edge_start_std_raw=float(np.std(ec_raw[m_start])),
        edge_start_std_comp=float(np.std(ec_est[m_start])),
        edge_end_std_raw=float(np.std(ec_raw[m_end])),
        edge_end_std_comp=float(np.std(ec_est[m_end])),
        edge_start_rmse_raw=float(np.sqrt(np.mean((ec_raw[m_start] - ec_true[m_start]) ** 2))),
        edge_start_rmse_comp=float(np.sqrt(np.mean((ec_est[m_start] - ec_true[m_start]) ** 2))),
        edge_end_rmse_raw=float(np.sqrt(np.mean((ec_raw[m_end] - ec_true[m_end]) ** 2))),
        edge_end_rmse_comp=float(np.sqrt(np.mean((ec_est[m_end] - ec_true[m_end]) ** 2))),
    )
