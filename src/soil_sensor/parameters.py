"""Sensor parameter definitions and commercial benchmarking matrix."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class SensorParameters:
    """Physical and excitation parameters for the series-RLC soil EC probe."""

    name: str
    cell_constant_cm_inv: float
    lead_inductance_h: float
    double_layer_capacitance_f: float
    excitation_freq_hz: float
    peak_voltage_v: float
    r_soil_min_ohm: float
    r_soil_max_ohm: float
    r_soil_nominal_ohm: float
    r_soil_fresh_ohm: float
    r_soil_salty_ohm: float = 50.0


BASELINE_PARAMS = SensorParameters(
    name="Baseline (MS1)",
    cell_constant_cm_inv=1.0,
    lead_inductance_h=3e-6,
    double_layer_capacitance_f=10e-6,
    excitation_freq_hz=1e3,
    peak_voltage_v=1.0,
    r_soil_min_ohm=5.0,
    r_soil_max_ohm=200e3,
    r_soil_nominal_ohm=10e3,
    r_soil_fresh_ohm=150e3,
)

OPTIMIZED_PARAMS = SensorParameters(
    name="Optimized (MS2)",
    cell_constant_cm_inv=0.1,
    lead_inductance_h=3e-6,
    double_layer_capacitance_f=20e-6,
    excitation_freq_hz=1e3,
    peak_voltage_v=1.0,
    r_soil_min_ohm=5.0,
    r_soil_max_ohm=200e3,
    r_soil_nominal_ohm=15e3,
    r_soil_fresh_ohm=15e3,
)

# Eight-criterion weighted decision matrix from Paper Table VI (weights sum to 100%).
DECISION_CRITERIA: tuple[tuple[str, float], ...] = (
    ("Range Coverage", 0.20),
    ("Accuracy", 0.25),
    ("Response Time", 0.15),
    ("Operating Temp.", 0.10),
    ("Environ. Suit.", 0.10),
    ("Interference Imm.", 0.10),
    ("Cost", 0.05),
    ("Maintenance", 0.05),
)

DECISION_SCORES: dict[str, tuple[int, ...]] = {
    "Atlas Scientific K 1.0": (10, 10, 7, 9, 8, 9, 8, 9),
    "Vernier CON-BTA": (6, 9, 5, 7, 6, 8, 7, 8),
    "METER 5TE": (7, 6, 10, 10, 10, 7, 5, 9),
    "Optimized Design (K=0.1)": (10, 8, 10, 7, 9, 8, 10, 7),
}


def weighted_decision_totals() -> dict[str, float]:
    """Compute weighted totals (out of 10) for all benchmarked sensors."""
    weights = [w for _, w in DECISION_CRITERIA]
    if abs(sum(weights) - 1.0) > 1e-12:
        raise ValueError(f"Decision weights must sum to 1.0, got {sum(weights)}")
    totals: dict[str, float] = {}
    for sensor, scores in DECISION_SCORES.items():
        if len(scores) != len(weights):
            raise ValueError(f"Score count mismatch for {sensor}")
        totals[sensor] = round(sum(w * s for w, s in zip(weights, scores, strict=True)), 6)
    return totals
