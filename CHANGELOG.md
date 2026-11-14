# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `uv`-managed Python verification package (`src/soil_sensor/`) reproducing MS1, MS2, MS3, and Table VI equations with a 21-test `pytest` suite and CLI report.
- GNU Octave 9.2.0 compatibility layer (`matlab/compat/`) and `matlab/run_all.m` headless runner covering all 11 `.m` simulation scripts.
- Continuous integration workflows for Python/Octave verification (`.github/workflows/ci.yml`) and IEEE LaTeX compilation (`.github/workflows/paper.yml`), pinned by commit SHA and container digest.
- SVG technical diagrams in `docs/diagrams/` (`rlc-equivalent-circuit.svg`, `compensation-pipeline.svg`), social preview assets in `docs/`, community health templates, `CITATION.cff`, and Dependabot configuration.

### Changed
- Aligned `paper/Soil_EC_Sensor_Design.tex` and compiled `docs/Soil_EC_Sensor_Design.pdf` with exact dual time-scale RLC settling behavior ($\tau_L$ vs $\tau_{RC}$) and step-free MS3 plateau metrics from `compensation_signals.csv`.
- Fixed inductive numerator `Num_L` and Octave path initialization in `setup_parameters.m` and `setup_parameters_v2.m`, and corrected `step_response_analysis*.m` to report both $\tau_{RC}$ and $\tau_L$ with finite 2% decay time.
- Restored LF line endings across corrupted MS3 MATLAB scripts and updated `matlab/results/figures/ec_time_comparison.png` directly from archived `compensation_signals.csv` with `EC (S/cm)` axis units.

### Removed
- Local coaching artifacts in `matlab/results/reports/` and helper formatting wrapper `matlab/tools/`.

## [1.0.0] - 2026-03-19

### Added
- Initial public release of the three-milestone MATLAB/Simulink design study, generated figures and CSV datasets, and IEEE conference paper source (`paper/Soil_EC_Sensor_Design.tex`).
