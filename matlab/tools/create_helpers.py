#!/usr/bin/env python3
# Script to create compensation helper functions with proper line endings

import os

# Output directory (relative to this script's location)
matlab_dir = os.path.join(os.path.dirname(__file__), '..')

# ===== add_noise_and_drift.m =====
noise_drift_code = r'''function [I_meas, n_t, b_t] = add_noise_and_drift(I_true, t_vec, SNR_dB, drift_amp, drift_freq)
% Add noise and drift to ideal sensor output

    P_signal = mean(I_true.^2);
    SNR_linear = 10^(SNR_dB / 10);
    P_noise = P_signal / SNR_linear;
    noise_std = sqrt(P_noise);
    n_t = noise_std * randn(size(I_true));

    I_mean = mean(abs(I_true));
    drift_amplitude = drift_amp * I_mean;
    b_t = drift_amplitude * sin(2 * pi * drift_freq * t_vec);

    I_meas = I_true + b_t + n_t;

    actual_SNR = 10 * log10(P_signal / var(n_t));
    drift_percentage = (max(abs(b_t)) / I_mean) * 100;

    fprintf('  Added noise: SNR = %.1f dB (target: %.1f dB)\n', actual_SNR, SNR_dB);
    fprintf('  Added drift: %.1f%% amplitude, f = %.3f Hz\n', drift_percentage, drift_freq);
    fprintf('  Noise std: %.3f microA, Drift peak: %.3f microA\n', std(n_t)*1e6, max(abs(b_t))*1e6);

end
'''

# ===== compensation_filter.m =====
comp_filter_code = r'''function [I_comp, EC_est, I_filt, b_est] = compensation_filter(I_meas, t_vec, filter_params)
% Apply compensation filter (noise reduction + drift removal)

    win_noise = filter_params.window_noise;
    win_drift = filter_params.window_drift;
    K_cell = filter_params.K_cell;

    I_filt = movmean(I_meas, win_noise);

    I_baseline = movmean(I_meas, win_drift);
    b_est = I_baseline - movmean(I_filt, win_noise);

    I_comp = I_filt - b_est;

    EC_est = zeros(size(I_comp));

    fprintf('  Applied noise filter (window: %d samples)\n', win_noise);
    fprintf('  Estimated and removed drift (window: %d samples)\n', win_drift);
    fprintf('  Compensated current range: %.3f to %.3f mA\n', min(I_comp)*1000, max(I_comp)*1000);

end
'''

# ===== error_metrics.m =====
error_metrics_code = r'''function [metrics, summary_str] = error_metrics(EC_true, EC_raw, EC_est, t_vec)
% Compute error metrics and performance evaluation

    err_raw = EC_raw - EC_true;
    err_comp = EC_est - EC_true;

    rmse_raw = sqrt(mean(err_raw.^2));
    rmse_comp = sqrt(mean(err_comp.^2));

    max_err_raw = max(abs(err_raw));
    max_err_comp = max(abs(err_comp));

    std_err_raw = std(err_raw);
    std_err_comp = std(err_comp);

    mean_err_raw = mean(err_raw);
    mean_err_comp = mean(err_comp);

    improvement_rmse = ((rmse_raw - rmse_comp) / rmse_raw) * 100;
    improvement_max = ((max_err_raw - max_err_comp) / max_err_raw) * 100;

    metrics.rmse_raw = rmse_raw;
    metrics.rmse_comp = rmse_comp;
    metrics.max_err_raw = max_err_raw;
    metrics.max_err_comp = max_err_comp;
    metrics.std_err_raw = std_err_raw;
    metrics.std_err_comp = std_err_comp;
    metrics.mean_err_raw = mean_err_raw;
    metrics.mean_err_comp = mean_err_comp;
    metrics.improvement_rmse_pct = improvement_rmse;
    metrics.improvement_max_pct = improvement_max;

    EC_mean = mean(EC_true);
    metrics.rmse_raw_pct = (rmse_raw / EC_mean) * 100;
    metrics.rmse_comp_pct = (rmse_comp / EC_mean) * 100;

    summary_str = sprintf([...
        '===========================================================\n', ...
        'ERROR ANALYSIS - PERFORMANCE METRICS\n', ...
        '===========================================================\n', ...
        'Metric                          Raw (Noisy)    Compensated\n', ...
        '-----------------------------------------------------------\n', ...
        'RMSE                            %.6e     %.6e\n', ...
        'RMSE (%% of mean EC)             %.2f%%          %.2f%%\n', ...
        'Max Absolute Error              %.6e     %.6e\n', ...
        'Std Dev of Error                %.6e     %.6e\n', ...
        'Mean Error (Bias)               %.6e     %.6e\n', ...
        '-----------------------------------------------------------\n', ...
        'IMPROVEMENT:\n', ...
        '  RMSE Reduction:               %.2f%%\n', ...
        '  Max Error Reduction:          %.2f%%\n', ...
        '===========================================================\n'], ...
        rmse_raw, rmse_comp, ...
        metrics.rmse_raw_pct, metrics.rmse_comp_pct, ...
        max_err_raw, max_err_comp, ...
        std_err_raw, std_err_comp, ...
        mean_err_raw, mean_err_comp, ...
        improvement_rmse, improvement_max);

    fprintf('%s', summary_str);

end
'''

# ===== generate_signals.m =====
gen_signals_code = r'''function [EC_true, R_soil_true, I_true] = generate_signals(t_vec, params)
% Generate true EC trajectory and ideal sensor output

    K_cell = params.K_cell;
    L_coil = params.L_coil;
    C_dl = params.C_dl;
    f_ex = params.f_ex;
    V_peak = params.V_peak;
    EC_levels = params.EC_levels;
    EC_times = params.EC_times;

    N = length(t_vec);
    EC_true = zeros(1, N);

    for i = 1:N
        t = t_vec(i);
        idx = find(t >= EC_times, 1, 'last');
        if isempty(idx)
            idx = 1;
        end
        EC_true(i) = EC_levels(idx);
    end

    R_soil_true = K_cell ./ EC_true;

    I_true = zeros(1, N);
    s = 1j * 2 * pi * f_ex;

    for i = 1:N
        R = R_soil_true(i);
        Y_s = (C_dl * s) / (L_coil * C_dl * s^2 + R * C_dl * s + 1);
        I_true(i) = abs(Y_s) * V_peak;
    end

    fprintf('  Generated true EC trajectory with %d levels\n', length(EC_levels));
    fprintf('  R_soil range: %.1f Ohm to %.1f kOhm\n', min(R_soil_true), max(R_soil_true)/1000);
    fprintf('  I_true range: %.3f to %.3f mA\n', min(I_true)*1000, max(I_true)*1000);

end
'''

# Write all files
files = {
    'add_noise_and_drift.m': noise_drift_code,
    'compensation_filter.m': comp_filter_code,
    'error_metrics.m': error_metrics_code,
    'generate_signals.m': gen_signals_code,
}

for filename, code in files.items():
    filepath = os.path.join(matlab_dir, filename)
    with open(filepath, 'w', newline='\r\n', encoding='utf-8') as f:
        f.write(code)
    print(f"Created {filename}")

print("\nAll helper functions created successfully!")
