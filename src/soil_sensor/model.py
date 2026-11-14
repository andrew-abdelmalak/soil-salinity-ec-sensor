"""Series-RLC admittance model, ODE solver, frequency, step, and sensitivity analysis."""

from __future__ import annotations

import math
from dataclasses import dataclass

import numpy as np
from numpy.typing import NDArray
from scipy.integrate import solve_ivp

from soil_sensor.parameters import SensorParameters


@dataclass(frozen=True, slots=True)
class LinearityResult:
    """Polynomial fit linearity summary."""

    coefficients: NDArray[np.float64]
    max_error_a: float
    fso_a: float
    nonlinearity_pct_fso: float
    r_squared: float


def _require_positive_r(r_soil_ohm: float) -> None:
    if r_soil_ohm <= 0:
        raise ValueError(f"Soil resistance must be positive, got {r_soil_ohm}")


def admittance(
    params: SensorParameters,
    r_soil_ohm: float,
    freq_hz: float | NDArray[np.float64],
) -> complex | NDArray[np.complex128]:
    """Evaluate complex admittance H(j*2*pi*f) = jw*C / (1 - w^2*L*C + jw*R*C)."""
    _require_positive_r(r_soil_ohm)
    s = 1j * 2.0 * np.pi * np.asarray(freq_hz, dtype=np.float64)
    l_h = params.lead_inductance_h
    c_f = params.double_layer_capacitance_f
    num = c_f * s
    den = l_h * c_f * (s**2) + r_soil_ohm * c_f * s + 1.0
    result = num / den
    if np.ndim(freq_hz) == 0:
        return complex(result)
    return result


def natural_frequency_hz(params: SensorParameters) -> tuple[float, float]:
    """Return (omega_n [rad/s], f_n [Hz]) = 1 / sqrt(L * C_dl)."""
    omega_n = 1.0 / math.sqrt(params.lead_inductance_h * params.double_layer_capacitance_f)
    return omega_n, omega_n / (2.0 * math.pi)


def damping_ratio(params: SensorParameters, r_soil_ohm: float) -> float:
    """Return dimensionless damping ratio zeta = (R / 2) * sqrt(C_dl / L)."""
    _require_positive_r(r_soil_ohm)
    return (
        0.5 * r_soil_ohm * math.sqrt(params.double_layer_capacitance_f / params.lead_inductance_h)
    )


def poles(params: SensorParameters, r_soil_ohm: float) -> tuple[complex, complex]:
    """Return (slow_pole, fast_pole) of L*C*s^2 + R*C*s + 1 = 0 using Vieta stability."""
    _require_positive_r(r_soil_ohm)
    l_h = params.lead_inductance_h
    c_f = params.double_layer_capacitance_f
    b = r_soil_ohm / l_h
    c0 = 1.0 / (l_h * c_f)
    disc = b * b - 4.0 * c0
    if disc >= 0.0:
        s_fast = -0.5 * (b + math.sqrt(disc))
        s_slow = c0 / s_fast
        return complex(s_slow), complex(s_fast)
    sqrt_neg = math.sqrt(-disc)
    return complex(-0.5 * b, 0.5 * sqrt_neg), complex(-0.5 * b, -0.5 * sqrt_neg)


def time_constants(params: SensorParameters, r_soil_ohm: float) -> tuple[float, float]:
    """Return (tau_rc, tau_l) in seconds: double-layer charging R*C and rise L/R."""
    _require_positive_r(r_soil_ohm)
    return (
        r_soil_ohm * params.double_layer_capacitance_f,
        params.lead_inductance_h / r_soil_ohm,
    )


def frequency_response(
    params: SensorParameters,
    r_soil_ohm: float,
    freqs_hz: NDArray[np.float64],
) -> tuple[NDArray[np.float64], NDArray[np.float64], NDArray[np.float64]]:
    """Return (magnitude_abs, magnitude_db, unwrapped_phase_deg) over freqs_hz."""
    h_jw = np.asarray(admittance(params, r_soil_ohm, freqs_hz), dtype=np.complex128)
    mag_abs = np.abs(h_jw)
    mag_db = 20.0 * np.log10(mag_abs)
    phase_deg = np.unwrap(np.angle(h_jw)) * (180.0 / np.pi)
    return mag_abs, mag_db, phase_deg


def static_calibration(
    params: SensorParameters, r_values_ohm: NDArray[np.float64]
) -> NDArray[np.float64]:
    """Compute steady-state peak output current [A] across r_values_ohm at f_ex."""
    currents = np.empty_like(r_values_ohm, dtype=np.float64)
    for idx, r_val in enumerate(r_values_ohm):
        h_val = admittance(params, float(r_val), params.excitation_freq_hz)
        currents[idx] = abs(h_val) * params.peak_voltage_v
    return currents


def linearity_metrics(
    x_values: NDArray[np.float64],
    y_values: NDArray[np.float64],
    degree: int = 1,
) -> LinearityResult:
    """Compute polynomial fit, max deviation, % FSO non-linearity, and R^2."""
    coeffs = np.polyfit(x_values, y_values, degree)
    y_fit = np.polyval(coeffs, x_values)
    err = y_values - y_fit
    max_err = float(np.max(np.abs(err)))
    fso = float(np.max(y_values) - np.min(y_values))
    pct_fso = (max_err / fso) * 100.0 if fso > 0 else 0.0
    ss_res = float(np.sum(err**2))
    ss_tot = float(np.sum((y_values - np.mean(y_values)) ** 2))
    r2 = 1.0 - (ss_res / ss_tot) if ss_tot > 0 else 1.0
    return LinearityResult(
        coefficients=coeffs,
        max_error_a=max_err,
        fso_a=fso,
        nonlinearity_pct_fso=pct_fso,
        r_squared=r2,
    )


def sensitivity_r(params: SensorParameters, r_soil_ohm: float) -> float:
    """Return analytical measurand sensitivity dI_peak/dR_soil [A/Ohm] at f_ex."""
    _require_positive_r(r_soil_ohm)
    s = 1j * 2.0 * np.pi * params.excitation_freq_hz
    l_h = params.lead_inductance_h
    c_f = params.double_layer_capacitance_f
    den = l_h * c_f * (s**2) + r_soil_ohm * c_f * s + 1.0
    y_s = (c_f * s) / den
    dy_dr = -(c_f * s) * (c_f * s) / (den**2)
    return float(params.peak_voltage_v * np.real(np.conj(y_s) * dy_dr) / abs(y_s))


def simulate_dynamic_ode(
    params: SensorParameters,
    r_soil_ohm: float,
    t_span: tuple[float, float] = (0.0, 0.1),
    t_eval: NDArray[np.float64] | None = None,
) -> tuple[NDArray[np.float64], NDArray[np.float64], NDArray[np.float64]]:
    """Integrate the stiff second-order RLC ODE using BDF (matching MATLAB ode15s)."""
    _require_positive_r(r_soil_ohm)
    l_h = params.lead_inductance_h
    c_f = params.double_layer_capacitance_f
    omega_ex = 2.0 * math.pi * params.excitation_freq_hz
    v_peak = params.peak_voltage_v

    def rhs(t: float, y: NDArray[np.float64]) -> list[float]:
        q, current = float(y[0]), float(y[1])
        v_in = v_peak * math.sin(omega_ex * t)
        q_ddot = (v_in - r_soil_ohm * current - q / c_f) / l_h
        return [current, q_ddot]

    def jac(_t: float, _y: NDArray[np.float64]) -> NDArray[np.float64]:
        return np.array([[0.0, 1.0], [-1.0 / (l_h * c_f), -r_soil_ohm / l_h]], dtype=np.float64)

    sol = solve_ivp(
        rhs,
        t_span,
        y0=[0.0, 0.0],
        method="BDF",
        jac=jac,
        t_eval=t_eval,
        rtol=1e-6,
        atol=1e-12,
    )
    if not sol.success:
        raise RuntimeError(f"Stiff ODE integration failed: {sol.message}")
    return sol.t, sol.y[0], sol.y[1]


def step_response_analytical(
    params: SensorParameters,
    r_soil_ohm: float,
    t: NDArray[np.float64],
) -> NDArray[np.float64]:
    """Compute exact unit-voltage step current response I(t) [A/V] for H(s)."""
    p1, p2 = poles(params, r_soil_ohm)
    if abs(p1 - p2) < 1e-15:
        raise ValueError("Repeated poles encountered in step response")
    prefactor = 1.0 / (params.lead_inductance_h * (p1 - p2))
    return np.real(prefactor * (np.exp(p1 * t) - np.exp(p2 * t)))
