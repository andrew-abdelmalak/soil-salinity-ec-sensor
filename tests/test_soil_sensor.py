"""Verification tests for soil_sensor against theory and MATLAB/Octave outputs."""

from __future__ import annotations

import csv
import math
from pathlib import Path

import numpy as np
import pytest

from soil_sensor import (
    BASELINE_PARAMS,
    DECISION_CRITERIA,
    OPTIMIZED_PARAMS,
    add_noise_and_drift,
    admittance,
    apply_compensation_filter,
    compute_error_metrics,
    damping_ratio,
    evaluate_archived_compensation,
    frequency_response,
    generate_ec_trajectory,
    invert_calibration_lookup,
    linearity_metrics,
    matlab_movmean,
    natural_frequency_hz,
    poles,
    sensitivity_r,
    simulate_dynamic_ode,
    static_calibration,
    step_response_analytical,
    time_constants,
    weighted_decision_totals,
)
from soil_sensor.cli import main as cli_main
from soil_sensor.parameters import SensorParameters

REPO_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = REPO_ROOT / "matlab" / "results" / "data"


def _read_numeric_csv(name: str) -> np.ndarray:
    return np.loadtxt(DATA_DIR / name, delimiter=",")


def test_natural_frequencies_match_paper() -> None:
    _, fn_base = natural_frequency_hz(BASELINE_PARAMS)
    _, fn_opt = natural_frequency_hz(OPTIMIZED_PARAMS)
    assert math.isclose(fn_base, 29057.5841566274, rel_tol=1e-9)
    assert math.isclose(fn_opt, 20546.81480205, rel_tol=1e-9)
    assert math.isclose(fn_opt / OPTIMIZED_PARAMS.excitation_freq_hz, 20.5468, rel_tol=1e-4)


def test_damping_ratios_across_salinity_range() -> None:
    zeta_salty = damping_ratio(BASELINE_PARAMS, BASELINE_PARAMS.r_soil_salty_ohm)
    zeta_nom = damping_ratio(BASELINE_PARAMS, BASELINE_PARAMS.r_soil_nominal_ohm)
    zeta_fresh = damping_ratio(BASELINE_PARAMS, BASELINE_PARAMS.r_soil_fresh_ohm)
    assert math.isclose(zeta_salty, 45.643546, rel_tol=1e-6)
    assert math.isclose(zeta_nom, 9128.709292, rel_tol=1e-6)
    assert math.isclose(zeta_fresh, 136930.639376, rel_tol=1e-6)


def test_poles_vieta_product_equals_omega_n_squared() -> None:
    omega_n, _ = natural_frequency_hz(BASELINE_PARAMS)
    p_slow, p_fast = poles(BASELINE_PARAMS, BASELINE_PARAMS.r_soil_fresh_ohm)
    assert p_slow.imag == 0.0 and p_fast.imag == 0.0
    assert math.isclose(abs(p_slow.real * p_fast.real), omega_n**2, rel_tol=1e-12)
    tau_rc, tau_l = time_constants(BASELINE_PARAMS, BASELINE_PARAMS.r_soil_fresh_ohm)
    assert math.isclose(-1.0 / p_slow.real, tau_rc, rel_tol=1e-9)
    assert math.isclose(-1.0 / p_fast.real, tau_l, rel_tol=1e-9)


def test_geometric_optimization_gains() -> None:
    tau_rc_base, _ = time_constants(BASELINE_PARAMS, BASELINE_PARAMS.r_soil_fresh_ohm)
    tau_rc_opt, _ = time_constants(OPTIMIZED_PARAMS, OPTIMIZED_PARAMS.r_soil_fresh_ohm)
    assert math.isclose(tau_rc_base, 1.5, rel_tol=1e-12)
    assert math.isclose(tau_rc_opt, 0.3, rel_tol=1e-12)
    assert math.isclose(tau_rc_base / tau_rc_opt, 5.0, rel_tol=1e-12)

    i_base = abs(admittance(BASELINE_PARAMS, BASELINE_PARAMS.r_soil_fresh_ohm, 1e3))
    i_opt = abs(admittance(OPTIMIZED_PARAMS, OPTIMIZED_PARAMS.r_soil_fresh_ohm, 1e3))
    assert math.isclose(i_base * 1e6, 6.666666, rel_tol=1e-4)
    assert math.isclose(i_opt * 1e6, 66.66666, rel_tol=1e-4)
    assert math.isclose(i_opt / i_base, 10.0, rel_tol=1e-5)


def test_passband_admittance_at_1khz() -> None:
    h_nom = admittance(BASELINE_PARAMS, 10e3, 1e3)
    assert math.isclose(abs(h_nom) * 1e6, 99.999874, rel_tol=1e-5)


def test_static_linearity_matches_paper_and_csv() -> None:
    r_sweep = np.logspace(np.log10(5.0), np.log10(200e3), 100)
    i_sweep = static_calibration(BASELINE_PARAMS, r_sweep)
    lin1 = linearity_metrics(r_sweep, i_sweep, degree=1)
    lin2 = linearity_metrics(r_sweep, i_sweep, degree=2)
    assert math.isclose(lin1.nonlinearity_pct_fso, 76.8, abs_tol=0.1)
    assert math.isclose(lin2.nonlinearity_pct_fso, 73.9, abs_tol=0.2)

    csv_static = _read_numeric_csv("static_response_data.csv")
    assert np.allclose(csv_static[:, 0], r_sweep, rtol=1e-12)
    assert np.allclose(csv_static[:, 1], i_sweep, rtol=1e-12)

    csv_static_v2 = _read_numeric_csv("static_response_data_v2.csv")
    i_sweep_v2 = static_calibration(OPTIMIZED_PARAMS, r_sweep)
    assert np.allclose(csv_static_v2[:, 1], i_sweep_v2, rtol=1e-12)


def test_bode_csv_matches_analytical_frequency_response() -> None:
    csv_bode = _read_numeric_csv("bode_plot_data.csv")
    freqs = csv_bode[:, 0]
    mag_abs, mag_db, phase_deg = frequency_response(BASELINE_PARAMS, 10e3, freqs)
    assert np.allclose(csv_bode[:, 1], mag_abs, rtol=1e-11)
    assert np.allclose(csv_bode[:, 2], mag_db, atol=1e-9)
    assert np.allclose(csv_bode[:, 3], phase_deg, atol=1e-9)


def test_sensitivity_csv_matches_analytical_derivative() -> None:
    csv_sens = _read_numeric_csv("sensitivity_data.csv")
    r_vals = csv_sens[:, 0]
    sens_py = np.array([sensitivity_r(BASELINE_PARAMS, float(r)) for r in r_vals])
    assert np.allclose(csv_sens[:, 2], sens_py, rtol=1e-11)


def test_stiff_bdf_ode_matches_ac_steady_state_amplitude() -> None:
    t_eval = np.linspace(0.0, 0.01, 5001)
    _, _, i_out = simulate_dynamic_ode(
        OPTIMIZED_PARAMS, OPTIMIZED_PARAMS.r_soil_fresh_ohm, t_span=(0.0, 0.01), t_eval=t_eval
    )
    tail = i_out[t_eval >= 0.005]
    expected_peak = (
        abs(admittance(OPTIMIZED_PARAMS, OPTIMIZED_PARAMS.r_soil_fresh_ohm, 1e3))
        * OPTIMIZED_PARAMS.peak_voltage_v
    )
    assert math.isclose(float(np.max(np.abs(tail))), expected_peak, rel_tol=1e-3)


def test_octave_dynamic_csv_matches_bdf_ode() -> None:
    dyn_v2 = _read_numeric_csv("dynamic_response_data_v2.csv")
    t_vals, y_octave = dyn_v2[:, 0], dyn_v2[:, 1]
    tail = y_octave[t_vals >= 0.01]
    expected_peak = (
        abs(admittance(OPTIMIZED_PARAMS, OPTIMIZED_PARAMS.r_soil_fresh_ohm, 1e3))
        * OPTIMIZED_PARAMS.peak_voltage_v
    )
    assert math.isclose(float(np.max(np.abs(tail))), expected_peak, rel_tol=1e-2)

    _, _, y_bdf = simulate_dynamic_ode(
        OPTIMIZED_PARAMS,
        OPTIMIZED_PARAMS.r_soil_fresh_ohm,
        t_span=(float(t_vals[0]), float(t_vals[-1])),
        t_eval=t_vals,
    )
    assert np.allclose(y_octave, y_bdf, rtol=1e-2, atol=1e-6)


def test_step_response_matches_csv_and_has_no_nan_inf() -> None:
    for fname, params, r_val in [
        ("step_response_fresh.csv", BASELINE_PARAMS, BASELINE_PARAMS.r_soil_fresh_ohm),
        ("step_response_salty.csv", BASELINE_PARAMS, BASELINE_PARAMS.r_soil_salty_ohm),
        ("step_response_fresh_v2.csv", OPTIMIZED_PARAMS, OPTIMIZED_PARAMS.r_soil_fresh_ohm),
    ]:
        data = _read_numeric_csv(fname)
        t_vals, y_csv = data[:, 0], data[:, 1]
        y_py = step_response_analytical(params, r_val, t_vals)
        assert np.allclose(y_csv, y_py, rtol=1e-10, atol=1e-14)

    for comp_name in ("step_response_comparison.csv", "step_response_comparison_v2.csv"):
        text = (DATA_DIR / comp_name).read_text(encoding="utf-8")
        assert "NaN" not in text and "Inf" not in text


def test_matlab_movmean_edge_truncation() -> None:
    x = np.array([1.0, 2.0, 3.0, 4.0, 5.0])
    m3 = matlab_movmean(x, 3)
    assert np.allclose(m3, [1.5, 2.0, 3.0, 4.0, 4.5])
    m4 = matlab_movmean(x, 4)
    assert np.allclose(m4, [1.5, 2.0, 2.5, 3.5, 4.0])


def test_archived_compensation_csv_matches_paper_table_iv() -> None:
    summary = evaluate_archived_compensation(
        DATA_DIR / "compensation_signals.csv", OPTIMIZED_PARAMS
    )
    assert summary.samples == 20001
    assert summary.max_movmean_diff_a < 1e-15

    m = summary.full_metrics
    assert math.isclose(m.rmse_raw, 3.118213e-7, rel_tol=1e-5)
    assert math.isclose(m.rmse_comp, 1.253469e-6, rel_tol=1e-5)
    assert math.isclose(m.rmse_raw_pct, 6.7783, rel_tol=1e-3)
    assert math.isclose(m.rmse_comp_pct, 27.2477, rel_tol=1e-3)
    assert math.isclose(m.max_err_raw, 9.7710e-7, rel_tol=1e-4)
    assert math.isclose(m.max_err_comp, 3.6467e-6, rel_tol=1e-4)
    assert math.isclose(m.mean_err_raw, 3.6580e-9, rel_tol=1e-3)
    assert math.isclose(m.mean_err_comp, -4.0926e-9, rel_tol=1e-3)

    # On flat edge plateaus away from step boundaries, the 5 s filter cuts noise std >9x
    assert summary.edge_start_std_raw / summary.edge_start_std_comp > 9.0
    assert summary.edge_end_std_raw / summary.edge_end_std_comp > 9.0
    assert summary.edge_start_rmse_comp < summary.edge_start_rmse_raw
    assert summary.edge_end_rmse_comp < summary.edge_end_rmse_raw


def test_archived_compensation_metrics_csv_matches_python() -> None:
    summary = evaluate_archived_compensation(
        DATA_DIR / "compensation_signals.csv", OPTIMIZED_PARAMS
    )
    with (DATA_DIR / "compensation_metrics.csv").open("r", encoding="utf-8") as handle:
        rows = {r["Metric"]: r for r in csv.DictReader(handle)}
    m = summary.full_metrics
    assert math.isclose(float(rows["RMSE"]["Raw_Noisy"]), m.rmse_raw, rel_tol=1e-12)
    assert math.isclose(float(rows["RMSE"]["Compensated"]), m.rmse_comp, rel_tol=1e-12)
    assert math.isclose(float(rows["Mean_Error"]["Raw_Noisy"]), m.mean_err_raw, rel_tol=1e-11)
    assert math.isclose(float(rows["Mean_Error"]["Compensated"]), m.mean_err_comp, rel_tol=1e-11)


def test_synthetic_compensation_pipeline_snr_and_drift() -> None:
    t_vec = np.linspace(0.0, 20.0, 20001)
    r_levels = (15e3, 50e3, 100e3, 30e3, 10e3)
    switch_t = (0.0, 4.0, 8.0, 12.0, 16.0)
    ec_true, _, i_true = generate_ec_trajectory(t_vec, r_levels, switch_t, OPTIMIZED_PARAMS)
    i_meas, noise, drift = add_noise_and_drift(i_true, t_vec, rng=np.random.default_rng(7))
    snr_actual = 10.0 * math.log10(float(np.mean(i_true**2) / np.var(noise)))
    assert abs(snr_actual - 30.0) < 0.3
    assert math.isclose(float(np.max(np.abs(drift)) / np.mean(i_true)), 0.08, rel_tol=1e-4)

    i_comp, _, _ = apply_compensation_filter(i_meas, 500, 5000)
    _, ec_raw = invert_calibration_lookup(i_meas, 10e3, 100e3, OPTIMIZED_PARAMS)
    _, ec_est = invert_calibration_lookup(i_comp, 10e3, 100e3, OPTIMIZED_PARAMS)
    metrics = compute_error_metrics(ec_true, ec_raw, ec_est)
    assert 5.0 < metrics.rmse_raw_pct < 9.0
    assert 24.0 < metrics.rmse_comp_pct < 30.0


def test_weighted_decision_matrix_matches_paper_table_vi() -> None:
    assert math.isclose(sum(w for _, w in DECISION_CRITERIA), 1.0, abs_tol=1e-12)
    totals = weighted_decision_totals()
    assert totals == {
        "Atlas Scientific K 1.0": 9.00,
        "Vernier CON-BTA": 7.05,
        "METER 5TE": 7.80,
        "Optimized Design (K=0.1)": 8.75,
    }


def test_invalid_inputs_fail_fast() -> None:
    with pytest.raises(ValueError, match="positive"):
        admittance(BASELINE_PARAMS, 0.0, 1e3)
    with pytest.raises(ValueError, match="positive"):
        damping_ratio(BASELINE_PARAMS, -5.0)
    with pytest.raises(ValueError, match="window"):
        matlab_movmean(np.array([1.0, 2.0]), 0)
    with pytest.raises(ValueError, match="same length"):
        generate_ec_trajectory(np.array([0.0, 1.0]), (10e3,), (0.0, 1.0), OPTIMIZED_PARAMS)


def test_frequency_response_magnitude_and_phase() -> None:
    freqs = np.logspace(0.0, 8.0, 81)
    mag_abs, mag_db, phase_deg = frequency_response(
        OPTIMIZED_PARAMS, OPTIMIZED_PARAMS.r_soil_salty_ohm, freqs
    )
    assert np.allclose(mag_db, 20.0 * np.log10(mag_abs))
    # Bandpass magnitude peaks near f_n with 1/R admittance and +90 to -90 deg phase sweep
    assert math.isclose(
        float(np.max(mag_abs)), 1.0 / OPTIMIZED_PARAMS.r_soil_salty_ohm, rel_tol=5e-2
    )
    assert phase_deg[0] > 80.0
    assert phase_deg[-1] < -80.0


def test_poles_underdamped_complex_branch() -> None:
    p1, p2 = poles(OPTIMIZED_PARAMS, 1e-6)
    assert p1.imag > 0.0
    assert p2.imag < 0.0
    assert math.isclose(p1.real, p2.real, rel_tol=1e-12)


def test_step_response_analytical_rejects_repeated_poles() -> None:
    crit = SensorParameters(
        name="crit",
        cell_constant_cm_inv=0.1,
        lead_inductance_h=1e-6,
        double_layer_capacitance_f=1e-6,
        excitation_freq_hz=1e3,
        peak_voltage_v=1.0,
        r_soil_min_ohm=1.0,
        r_soil_max_ohm=10.0,
        r_soil_nominal_ohm=2.0,
        r_soil_fresh_ohm=2.0,
        r_soil_salty_ohm=2.0,
    )
    with pytest.raises(ValueError, match="Repeated poles"):
        step_response_analytical(crit, 2.0, np.array([0.0, 1e-6]))


def test_cli_main_runs_and_prints_summary(capsys: pytest.CaptureFixture[str]) -> None:
    cli_main()
    out = capsys.readouterr().out
    assert "Natural frequency (MS1):" in out
    assert "Fresh-water R_soil:" in out
    assert "Full-window raw RMSE:" in out
    assert "Atlas Scientific K 1.0" in out
