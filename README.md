# Soil Salinity (EC) Sensor System

Design, mathematical modeling, performance optimization, signal processing, and commercial benchmarking of a two-electrode soil electrical conductivity (EC) sensor for precision agriculture applications.

## Project Overview

Soil salinity is measured via electrical conductivity (EC). This project models a two-electrode impedance-based sensing circuit as a second-order RLC system driven by an AC excitation signal, derives and validates the sensor transfer function, optimizes sensitivity through cell-constant reduction, and develops a dual-window compensation scheme for real-world measurement noise and slow drift.

Key analysis stages:

| Stage | Focus |
|-------|-------|
| Baseline characterization | Parameter setup, static calibration, linearity, step/frequency response |
| Enhanced modeling | Revised circuit model, Bode analysis, performance validation against specifications |
| Signal compensation | Noise injection, drift modeling, moving-average compensation filter, error metrics |

## Repository Structure

```
.
├── matlab/
│   ├── setup_parameters.m              # Baseline sensor parameters
│   ├── setup_parameters_v2.m           # Enhanced model parameters
│   ├── parameter_validation.m          # Parameter validation & calibration
│   ├── parameter_validation_v2.m       # Enhanced parameter validation
│   ├── performance_analysis.m          # Static/dynamic performance
│   ├── performance_analysis_v2.m       # Enhanced performance analysis
│   ├── frequency_response.m            # Bode plot and -3 dB bandwidth
│   ├── step_response_analysis.m        # Step response (fresh/salty water)
│   ├── step_response_analysis_v2.m     # Enhanced step response
│   ├── sensitivity_analysis.m          # Parametric sensitivity study
│   ├── ode_function.m                  # ODE right-hand side for time integration
│   ├── noise_compensation_main.m       # Noise + drift compensation pipeline
│   ├── generate_signals.m             # Signal generation for compensation scenarios
│   ├── add_noise_and_drift.m          # Noise and drift injection
│   ├── compensation_filter.m          # Moving-average compensation filter
│   ├── error_metrics.m                # RMSE / peak-error quantification
│   ├── ec_sensor_model.slx            # Simulink circuit model
│   ├── validated_parameters.mat        # Saved validated parameter set
│   ├── results/
│   │   ├── data/                       # Simulation output datasets (CSV, MAT)
│   │   ├── figures/                    # Exported plots (PNG, JPG)
│   │   └── reports/                    # Analysis reports and correction notes (MD)
│   └── tools/
│       └── *.py                        # Code-generation and patch helpers
└── ...
```

## Circuit Model

The sensor is modelled as a series RLC impedance driven by an AC voltage source at frequency $f_{ex} = 1\,\text{kHz}$:

$$Y(s) = \frac{C_{dl}\,s}{L_{coil}\,C_{dl}\,s^2 + R_{soil}\,C_{dl}\,s + 1}$$

The output current amplitude is:

$$I_{out}(R_{soil}) = |Y(j\omega)| \cdot V_{peak}$$

Design parameters:

| Parameter | Symbol | Value |
|-----------|--------|-------|
| Lead inductance | $L_{coil}$ | 3 µH |
| Probe double-layer capacitance | $C_{dl}$ | 10–20 µF |
| Excitation frequency | $f_{ex}$ | 1 kHz |
| Soil resistance range | $R_{soil}$ | 5 Ω – 200 kΩ |
| Excitation voltage | $V_{peak}$ | 1 V |

## Usage

### Prerequisites
- MATLAB R2021a or later
- Simulink (for `ec_sensor_model.slx`)

### Recommended Execution Order

**Baseline characterization:**
```matlab
run('matlab/setup_parameters.m')
run('matlab/parameter_validation.m')
run('matlab/performance_analysis.m')
run('matlab/step_response_analysis.m')
run('matlab/frequency_response.m')
run('matlab/sensitivity_analysis.m')
```

**Enhanced model:**
```matlab
run('matlab/setup_parameters_v2.m')
run('matlab/parameter_validation_v2.m')
run('matlab/performance_analysis_v2.m')
run('matlab/step_response_analysis_v2.m')
```

**Noise and drift compensation:**
```matlab
run('matlab/noise_compensation_main.m')
```

Outputs (CSV datasets, figures, summary reports) are written to `matlab/results/data/`, `matlab/results/figures/`, and `matlab/results/reports/`.

## Results Overview

- **Static response:** Peak output current vs. soil resistance spanning ~4 decades on a log-log scale.
- **Frequency response:** Flat passband in the kHz range; -3 dB bandwidth well above the 1 kHz operating point.
- **Step response:** Damping ratio $\zeta \gg 1$ (critically overdamped) for both fresh-water and salty-water conditions; settling time < 5 ms.
- **Signal compensation:** Moving-average filter reduces current-signal RMSE under noise and slow sinusoidal drift by tracking EC step changes within the filter window.

## Authors

| Name | Affiliation |
|------|-------------|
| **Andrew Khalil** | Mechatronics Engineering, GUC |
| **Daniel George** | Mechatronics Engineering, GUC |
| **David Louis** | Mechatronics Engineering, GUC |
| **Samir Sameh** | Mechatronics Engineering, GUC |
| **Youssef Youssry** | Mechatronics Engineering, GUC |

## Report

The full project report is available in [`docs/Soil_EC_Sensor_Design.pdf`](docs/Soil_EC_Sensor_Design.pdf).

## License

Released under the MIT License. See `LICENSE`.
