function run_all()
% =========================================================================
% Soil Salinity (EC) Sensor
% Run all baseline (MS1), optimized (MS2), and compensation (MS3) scripts.
% =========================================================================

    fprintf('Running full MATLAB/Octave verification suite...\n');

    if exist('OCTAVE_VERSION', 'builtin')
        warning('off', 'Octave:gnuplot-graphics-toolkit');
        addpath(fullfile(fileparts(mfilename('fullpath')), 'compat'));
        if isempty(getenv('DISPLAY'))
            set(0, 'defaultfigurevisible', 'off');
        end
    end

    scripts = {
        'setup_parameters.m', ...
        'parameter_validation.m', ...
        'performance_analysis.m', ...
        'step_response_analysis.m', ...
        'frequency_response.m', ...
        'sensitivity_analysis.m', ...
        'setup_parameters_v2.m', ...
        'parameter_validation_v2.m', ...
        'performance_analysis_v2.m', ...
        'step_response_analysis_v2.m' ...
    };

    for idx = 1:length(scripts)
        script_name = scripts{idx};
        fprintf('\n>>> Running %s <<<\n', script_name);
        run_isolated(script_name);
    end

    % Run MS3 compensation pipeline into a temporary directory unless overridden,
    % preserving the archived MATLAB compensation_signals.csv cited in Paper Table IV.
    comp_out_prev = getenv('EC_COMP_OUT_DIR');
    if isempty(comp_out_prev)
        comp_tmp = tempname();
        setenv('EC_COMP_OUT_DIR', comp_tmp);
    else
        comp_tmp = '';
    end

    fprintf('\n>>> Running noise_compensation_main.m <<<\n');
    run_isolated('noise_compensation_main.m');

    if ~isempty(comp_tmp)
        setenv('EC_COMP_OUT_DIR', '');
    end

    fprintf('\nAll 11 scripts completed successfully.\n');
end

function run_isolated(script_path)
% Run a script in its own function scope so `clear all` inside the script
% does not clear variables in run_all().
    run(script_path);
end
