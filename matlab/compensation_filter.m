function [I_comp, EC_est, I_filt, b_est] = compensation_filter(I_meas, t_vec, filter_params)
% Apply compensation filter (noise reduction + drift tracking)

    win_noise = filter_params.window_noise;
    win_drift = filter_params.window_drift;

    % Short-window moving average for high-frequency noise reduction
    I_filt = movmean(I_meas, win_noise);

    % Long-window moving average for low-frequency envelope smoothing
    I_lowpass = movmean(I_meas, win_drift);

    % Use the long-window smoothed current as compensated output
    I_comp = I_lowpass;

    % Diagnostic difference between long and short moving-average windows
    b_est = I_lowpass - I_filt;

    EC_est = zeros(size(I_comp));

    fprintf('  Applied noise filter (window: %d samples)\n', win_noise);
    fprintf('  Applied drift smoothing (window: %d samples)\n', win_drift);
    fprintf('  Compensated current range: %.3f to %.3f mA\n', min(I_comp)*1000, max(I_comp)*1000);

end
