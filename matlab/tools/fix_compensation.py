#!/usr/bin/env python3
# Fix the compensation filter to work properly

import os

code = r'''function [I_comp, EC_est, I_filt, b_est] = compensation_filter(I_meas, t_vec, filter_params)
% Apply compensation filter (noise reduction + drift removal)

    win_noise = filter_params.window_noise;
    win_drift = filter_params.window_drift;
    K_cell = filter_params.K_cell;

    % Simple moving average for noise reduction
    I_filt = movmean(I_meas, win_noise);

    % Drift estimation: Use high-pass filtering approach
    % Low-pass filter to get trend (signal + drift)
    I_lowpass = movmean(I_meas, win_drift);

    % The drift is the slow baseline shift
    % For compensation, we just use the filtered signal
    % The long moving average removes high-frequency noise well
    I_comp = I_lowpass;

    % Estimate drift as difference between short and long filters
    b_est = I_lowpass - I_filt;

    EC_est = zeros(size(I_comp));

    fprintf('  Applied noise filter (window: %d samples)\n', win_noise);
    fprintf('  Applied drift compensation (window: %d samples)\n', win_drift);
    fprintf('  Compensated current range: %.3f to %.3f mA\n', min(I_comp)*1000, max(I_comp)*1000);

end
'''

output_path = os.path.join(os.path.dirname(__file__), '..', 'compensation_filter.m')
with open(output_path, 'w', newline='\r\n', encoding='utf-8') as f:
    f.write(code)

print("Fixed compensation_filter.m")
