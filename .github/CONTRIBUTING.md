# Contributing

Contributions that improve model accuracy, Octave compatibility, Python test coverage, or documentation clarity are welcome.

## Development Setup

Clone the repository and sync the locked Python environment with `uv`:

```bash
git clone https://github.com/andrew-abdelmalak/soil-salinity-ec-sensor.git
cd soil-salinity-ec-sensor
uv sync --locked
```

## Verification Checks

Run the exact same checks that CI runs before opening a pull request against `main`:

```bash
uv run ruff check .
uv run ruff format --check .
uv run pytest -v
uv run python -m soil_sensor
```

Run the MATLAB/Octave simulation suite in GNU Octave 9.2.0 via Docker:

```bash
docker run --rm \
  -v "$(pwd)/matlab:/work" \
  -w /work \
  gnuoctave/octave@sha256:100d394c57b86469748d26ddafcf73a1074338a66dabcababe2e4e05146772b9 \
  octave-cli --no-gui --quiet run_all.m
```

If you edit files in `paper/`, compile `paper/Soil_EC_Sensor_Design.tex` with TeX Live and verify there are no LaTeX warnings or undefined references:

```bash
docker run --rm \
  -v "$(pwd)/paper:/work" \
  -w /work \
  texlive/texlive@sha256:7056390eac37715fd3e01875037ceb4016cb17d44c611f7bbbfa7a012007979f \
  latexmk -pdf -interaction=nonstopmode Soil_EC_Sensor_Design.tex
```

## Pull Request Process

- Target `main` from a topic branch with focused commits.
- Keep numerical claims traceable to `matlab/` scripts, `src/soil_sensor/`, or `paper/Soil_EC_Sensor_Design.tex`.
- Wait for the `Lint, test, and build` check (and `Build IEEE paper` when `paper/` changes) to pass.

## License

By contributing, you agree that your contributions will be licensed under the MIT License in [LICENSE](../LICENSE).
