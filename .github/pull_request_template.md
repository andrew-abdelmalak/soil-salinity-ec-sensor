## Summary

Describe what changed and why.

## Related Issue

Closes #

## Verification

- [ ] `uv run ruff check .` and `uv run ruff format --check .` pass
- [ ] `uv run pytest -v` passes
- [ ] `octave-cli --no-gui --quiet run_all.m` passes (when `matlab/` changed)
- [ ] `latexmk -pdf -interaction=nonstopmode Soil_EC_Sensor_Design.tex` compiles with zero warnings (when `paper/` changed)
