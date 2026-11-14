"""Analytical RLC model, compensation pipeline, and benchmark reproduction."""

from soil_sensor.compensation import (
    add_noise_and_drift,
    apply_compensation_filter,
    compute_error_metrics,
    evaluate_archived_compensation,
    generate_ec_trajectory,
    invert_calibration_lookup,
    matlab_movmean,
)
from soil_sensor.model import (
    admittance,
    damping_ratio,
    frequency_response,
    linearity_metrics,
    natural_frequency_hz,
    poles,
    sensitivity_r,
    simulate_dynamic_ode,
    static_calibration,
    step_response_analytical,
    time_constants,
)
from soil_sensor.parameters import (
    BASELINE_PARAMS,
    DECISION_CRITERIA,
    DECISION_SCORES,
    OPTIMIZED_PARAMS,
    SensorParameters,
    weighted_decision_totals,
)

__all__ = [
    "BASELINE_PARAMS",
    "DECISION_CRITERIA",
    "DECISION_SCORES",
    "OPTIMIZED_PARAMS",
    "SensorParameters",
    "add_noise_and_drift",
    "admittance",
    "apply_compensation_filter",
    "compute_error_metrics",
    "damping_ratio",
    "evaluate_archived_compensation",
    "frequency_response",
    "generate_ec_trajectory",
    "invert_calibration_lookup",
    "linearity_metrics",
    "matlab_movmean",
    "natural_frequency_hz",
    "poles",
    "sensitivity_r",
    "simulate_dynamic_ode",
    "static_calibration",
    "step_response_analytical",
    "time_constants",
    "weighted_decision_totals",
]
