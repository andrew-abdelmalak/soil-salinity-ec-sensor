function [y_out, t_out] = step(sys, t_arg)
% Analytical step response of a continuous-time transfer function struct.
    p = roots(sys.den);
    real_parts = abs(real(p));
    nonzero_real = real_parts(real_parts > 0);
    if isempty(nonzero_real)
        tau_slow = 1.0;
        tau_fast = 1e-3;
    else
        tau_slow = 1.0 / min(nonzero_real);
        tau_fast = 1.0 / max(nonzero_real);
    end

    if nargin < 2 || isempty(t_arg)
        t_final = 5.0 * tau_slow;
        t_min = max(1e-14, 0.05 * tau_fast);
        t = unique([0; logspace(log10(t_min), log10(t_final), 1200).'; linspace(0, t_final, 1000).']);
    elseif isscalar(t_arg)
        t_final = t_arg;
        t_min = max(1e-14, min(0.05 * tau_fast, t_final * 1e-6));
        t = unique([0; logspace(log10(t_min), log10(t_final), 1200).'; linspace(0, t_final, 1000).']);
    else
        t = t_arg(:);
    end

    num = sys.num;
    den = sys.den;
    if abs(num(end)) < 1e-18 && length(num) >= 2
        % Cancel s=0 in H(s)/s
        num_step = num(1:end-1);
        den_step = den;
        dc_val = 0.0;
    else
        num_step = num;
        den_step = conv([1, 0], den);
        dc_val = num(end) / den(end);
    end

    if length(den_step) == 3 && length(num_step) <= 2 && isreal(p) && length(p) == 2 && p(1) ~= p(2)
        a2 = den_step(1);
        b1 = 0.0;
        if length(num_step) == 2
            b1 = num_step(1);
            b0 = num_step(2);
        else
            b0 = num_step(1);
        end
        r1 = (b1 * p(1) + b0) / (a2 * (p(1) - p(2)));
        r2 = (b1 * p(2) + b0) / (a2 * (p(2) - p(1)));
        y = real(r1 * exp(p(1) * t) + r2 * exp(p(2) * t));
    else
        [r, pol, k] = residue(num_step, den_step);
        y = zeros(size(t));
        for i = 1:length(r)
            if abs(pol(i)) < 1e-15
                y = y + real(r(i));
            else
                y = y + real(r(i) * exp(pol(i) * t));
            end
        end
        if ~isempty(k)
            y(1) = y(1) + real(k(end));
        end
        if dc_val ~= 0
            y(end) = y(end);
        end
    end

    if nargout == 0
        plot(t, y, 'b-', 'LineWidth', 1.5);
        grid on;
        xlabel('Time (s)');
        ylabel('Amplitude');
        title('Step Response');
    else
        y_out = y;
        t_out = t;
    end
end
