"""Command-line verification report for the soil salinity EC sensor models."""

from __future__ import annotations

from pathlib import Path

import numpy as np

from soil_sensor.compensation import evaluate_archived_compensation
from soil_sensor.model import (
    admittance,
    damping_ratio,
    linearity_metrics,
    natural_frequency_hz,
    simulate_dynamic_ode,
    static_calibration,
    time_constants,
)
from soil_sensor.parameters import (
    BASELINE_PARAMS,
    OPTIMIZED_PARAMS,
    weighted_decision_totals,
)


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def main() -> None:
    """Print verified MS1 vs. MS2 physics, compensation, and benchmark summary."""
    _, fn_base = natural_frequency_hz(BASELINE_PARAMS)
    _, fn_opt = natural_frequency_hz(OPTIMIZED_PARAMS)

    tau_rc_base, tau_l_base = time_constants(BASELINE_PARAMS, BASELINE_PARAMS.r_soil_fresh_ohm)
    tau_rc_opt, tau_l_opt = time_constants(OPTIMIZED_PARAMS, OPTIMIZED_PARAMS.r_soil_fresh_ohm)

    i_fresh_base = abs(
        admittance(
            BASELINE_PARAMS,
            BASELINE_PARAMS.r_soil_fresh_ohm,
            BASELINE_PARAMS.excitation_freq_hz,
        )
    )
    i_fresh_opt = abs(
        admittance(
            OPTIMIZED_PARAMS,
            OPTIMIZED_PARAMS.r_soil_fresh_ohm,
            OPTIMIZED_PARAMS.excitation_freq_hz,
        )
    )

    zeta_salty_base = damping_ratio(BASELINE_PARAMS, BASELINE_PARAMS.r_soil_salty_ohm)
    zeta_fresh_base = damping_ratio(BASELINE_PARAMS, BASELINE_PARAMS.r_soil_fresh_ohm)

    r_sweep = np.logspace(np.log10(5.0), np.log10(200e3), 100)
    i_sweep_base = static_calibration(BASELINE_PARAMS, r_sweep)
    lin1 = linearity_metrics(r_sweep, i_sweep_base, degree=1)
    lin2 = linearity_metrics(r_sweep, i_sweep_base, degree=2)

    _, _, i_ode_opt = simulate_dynamic_ode(
        OPTIMIZED_PARAMS, OPTIMIZED_PARAMS.r_soil_fresh_ohm, t_span=(0.0, 0.01)
    )

    r_base_k = BASELINE_PARAMS.r_soil_fresh_ohm / 1e3
    r_opt_k = OPTIMIZED_PARAMS.r_soil_fresh_ohm / 1e3
    i_gain = i_fresh_opt / i_fresh_base
    tau_gain = tau_rc_base / tau_rc_opt

    print("Soil Salinity (EC) Sensor - Python Verification Summary")
    print("=" * 64)
    print(f"Natural frequency (MS1):         {fn_base / 1e3:.2f} kHz")
    print(
        f"Natural frequency (MS2):         {fn_opt / 1e3:.2f} kHz ({fn_opt / 1e3:.2f}x f_ex=1 kHz)"
    )
    print(
        f"Damping ratio (MS1):             {zeta_salty_base:.2f} (50 Ohm) "
        f"to {zeta_fresh_base:,.0f} (150 kOhm)"
    )
    print(
        f"Fresh-water R_soil:              {r_base_k:.0f} kOhm -> "
        f"{r_opt_k:.0f} kOhm (10x reduction)"
    )
    print(
        f"Fresh-water peak current:        {i_fresh_base * 1e6:.2f} uA -> "
        f"{i_fresh_opt * 1e6:.2f} uA ({i_gain:.1f}x gain)"
    )
    print(
        f"RC double-layer tau_RC:          {tau_rc_base:.2f} s -> "
        f"{tau_rc_opt:.2f} s ({tau_gain:.1f}x faster)"
    )
    print(f"Inductive rise tau_L:            {tau_l_base:.2e} s -> {tau_l_opt:.2e} s")
    print(
        f"Static non-linearity (MS1):      {lin1.nonlinearity_pct_fso:.1f}% FSO (linear), "
        f"{lin2.nonlinearity_pct_fso:.1f}% FSO (quadratic)"
    )
    print(f"Stiff BDF ODE peak (MS2, 10 ms): {np.max(np.abs(i_ode_opt)) * 1e6:.2f} uA")

    comp_csv = _repo_root() / "matlab" / "results" / "data" / "compensation_signals.csv"
    if comp_csv.exists():
        summary = evaluate_archived_compensation(comp_csv, OPTIMIZED_PARAMS)
        m = summary.full_metrics
        s_ratio = summary.edge_start_std_raw / summary.edge_start_std_comp
        e_ratio = summary.edge_end_std_raw / summary.edge_end_std_comp
        print("-" * 64)
        print(
            f"Archived MS3 trajectory ({summary.samples} samples, "
            f"movmean diff {summary.max_movmean_diff_a:.2e} A):"
        )
        print(f"  Full-window raw RMSE:          {m.rmse_raw:.2e} S/cm ({m.rmse_raw_pct:.2f}%)")
        print(f"  Full-window N=5000 RMSE:       {m.rmse_comp:.2e} S/cm ({m.rmse_comp_pct:.2f}%)")
        print(
            f"  Full-window N=500  RMSE:       {summary.short_window_rmse_s_cm:.2e} S/cm "
            f"({summary.short_window_rmse_pct:.2f}%)"
        )
        print(
            f"  Edge [0.0, 1.5]s noise std:    {summary.edge_start_std_raw:.2e} -> "
            f"{summary.edge_start_std_comp:.2e} S/cm ({s_ratio:.1f}x)"
        )
        print(
            f"  Edge [18.5,20.0]s noise std:   {summary.edge_end_std_raw:.2e} -> "
            f"{summary.edge_end_std_comp:.2e} S/cm ({e_ratio:.1f}x)"
        )

    print("-" * 64)
    print("Commercial Sensor Weighted Decision Matrix (Paper Table VI):")
    for name, score in weighted_decision_totals().items():
        print(f"  {name:<26} {score:.2f} / 10")


if __name__ == "__main__":
    main()
