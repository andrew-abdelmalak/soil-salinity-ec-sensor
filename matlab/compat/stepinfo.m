function info = stepinfo(sys_or_y, t_arg, y_ss_arg)
% Step response characteristics for transfer function or response vector.
    if isstruct(sys_or_y) && isfield(sys_or_y, 'is_tf')
        [y, t] = step(sys_or_y);
        y_ss = dcgain(sys_or_y);
    else
        y = sys_or_y(:);
        t = t_arg(:);
        if nargin >= 3 && ~isempty(y_ss_arg)
            y_ss = y_ss_arg;
        else
            y_ss = y(end);
        end
    end

    [peak_val, idx_peak] = max(abs(y));
    peak_signed = y(idx_peak);
    t_peak = t(idx_peak);

    % Rise time (10% to 90% of peak on rising edge)
    y_rise_ref = peak_signed;
    if abs(y_ss) > 1e-12 * peak_val && isfinite(y_ss)
        y_rise_ref = y_ss;
    end
    idx_10 = find(y(1:idx_peak) >= 0.1 * y_rise_ref, 1, 'first');
    idx_90 = find(y(1:idx_peak) >= 0.9 * y_rise_ref, 1, 'first');
    if ~isempty(idx_10) && ~isempty(idx_90)
        t_rise = t(idx_90) - t(idx_10);
    else
        t_rise = 0.0;
    end

    % Settling / 2% decay time
    if abs(y_ss) <= 1e-12 * peak_val
        % Bandpass/high-pass admittance: measure 2% decay from peak
        idx_above = find(abs(y(idx_peak:end)) > 0.02 * peak_val, 1, 'last');
        if isempty(idx_above)
            t_settle = t_peak;
        elseif (idx_peak + idx_above - 1) >= length(t)
            t_settle = t(end);
        else
            t_settle = t(idx_peak + idx_above);
        end
        overshoot = 0.0;
        settling_max = peak_signed;
    else
        idx_out = find(abs(y - y_ss) > 0.02 * abs(y_ss), 1, 'last');
        if isempty(idx_out)
            t_settle = 0.0;
        elseif idx_out >= length(t)
            t_settle = t(end);
        else
            t_settle = t(idx_out + 1);
        end
        overshoot = max(0.0, (peak_signed - y_ss) / abs(y_ss) * 100.0);
        settling_max = max(y);
    end

    info = struct( ...
        'RiseTime', t_rise, ...
        'SettlingTime', t_settle, ...
        'SettlingMin', min(y), ...
        'SettlingMax', settling_max, ...
        'Overshoot', overshoot, ...
        'Undershoot', 0.0, ...
        'Peak', peak_val, ...
        'PeakTime', t_peak);
end
