function nyquist(sys, w)
% Plot Nyquist diagram of a transfer function struct.
    if nargin < 2 || isempty(w)
        w = logspace(-2, 9, 1000);
    end
    s = 1j * w(:);
    H = polyval(sys.num, s) ./ polyval(sys.den, s);
    plot(real(H), imag(H), 'b-', real(H), -imag(H), 'b--');
    grid on;
    xlabel('Real Axis');
    ylabel('Imaginary Axis');
end
