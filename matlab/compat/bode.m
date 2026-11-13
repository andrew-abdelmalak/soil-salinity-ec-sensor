function [mag_out, phase_out, w_out] = bode(sys, w)
% Evaluate Bode magnitude and phase of a transfer function struct.
    if nargin < 2 || isempty(w)
        w = logspace(-1, 7, 500);
    end
    w = w(:);
    s = 1j * w;
    H = polyval(sys.num, s) ./ polyval(sys.den, s);
    mag_vec = abs(H);
    phase_vec = unwrap(angle(H)) * (180 / pi);
    if nargout == 0
        subplot(2, 1, 1);
        semilogx(w, 20 * log10(mag_vec));
        grid on;
        ylabel('Magnitude (dB)');
        subplot(2, 1, 2);
        semilogx(w, phase_vec);
        grid on;
        xlabel('Frequency (rad/s)');
        ylabel('Phase (deg)');
    else
        mag_out = reshape(mag_vec, 1, 1, []);
        phase_out = reshape(phase_vec, 1, 1, []);
        w_out = w;
    end
end
