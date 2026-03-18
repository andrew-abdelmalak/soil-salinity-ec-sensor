% =========================================================================
% Soil Salinity (EC)
% Frequency Response Analysis: Bode Plot, Bandwidth, and Resonance
% =========================================================================
clear all; close all; clc;

% 1. Load System Parameters
run('setup_parameters.m');

disp('===========================================================');
disp('FREQUENCY RESPONSE ANALYSIS');
disp('===========================================================');

% =========================================================================
% PART A: TRANSFER FUNCTION CONSTRUCTION
% =========================================================================
disp(' ');
disp('--- TRANSFER FUNCTION MODEL ---');

% Transfer Function H(s) = Y(s) = (C_dl * s) / (L_coil * C_dl * s^2 + R_soil * C_dl * s + 1)
% Numerator: C_dl * s
% Denominator: L_coil * C_dl * s^2 + R_soil * C_dl * s + 1

num = [C_dl, 0];  % C_dl * s
den = [L_coil * C_dl, R_soil_baseline * C_dl, 1];  % L*C*s^2 + R*C*s + 1

% Create Transfer Function Model (Requires Control System Toolbox)
H_s = tf(num, den);

disp('Transfer Function:');
disp(H_s);

% Theoretical System Characteristics
omega_n = sqrt(1 / (L_coil * C_dl));  % Natural frequency (rad/s)
f_n = omega_n / (2 * pi);  % Natural frequency (Hz)
zeta = (R_soil_baseline / (2 * L_coil)) * sqrt(L_coil * C_dl);  % Damping ratio
Q_factor = 1 / (2 * zeta);  % Quality factor

disp(['Natural Frequency (f_n):        ', num2str(f_n, '%.2f'), ' Hz']);
disp(['Natural Frequency (ω_n):        ', num2str(omega_n, '%.2f'), ' rad/s']);
disp(['Damping Ratio (ζ):              ', num2str(zeta, '%.4f')]);
disp(['Quality Factor (Q):             ', num2str(Q_factor, '%.2f')]);

% =========================================================================
% PART B: BODE PLOT GENERATION
% =========================================================================
disp(' ');
disp('--- BODE PLOT ANALYSIS ---');

% Define comprehensive frequency range (0.1 Hz to 1 MHz)
f_start = 0.1;  % Hz
f_end = 1e6;    % Hz
num_points = 1000;

% Create logarithmic frequency vector
w_vec = logspace(log10(2*pi*f_start), log10(2*pi*f_end), num_points);

% Calculate Bode response
[mag_abs, phase_deg, w_out] = bode(H_s, w_vec);

% Reshape output vectors (bode output is 3D for SISO systems)
mag_abs = reshape(mag_abs, 1, [])';
phase_deg = reshape(phase_deg, 1, [])';
f_out = w_out / (2 * pi);  % Convert to Hz

% Convert magnitude to dB
mag_dB = 20 * log10(mag_abs);

% =========================================================================
% PART C: RESONANCE ANALYSIS
% =========================================================================
disp(' ');
disp('--- RESONANCE ANALYSIS ---');

% Find peak magnitude (resonance)
[mag_peak, idx_peak] = max(mag_abs);
f_peak = f_out(idx_peak);
mag_peak_dB = mag_dB(idx_peak);
phase_peak = phase_deg(idx_peak);

disp(['Peak Magnitude:                 ', num2str(mag_peak, '%.6f'), ' (', num2str(mag_peak_dB, '%.2f'), ' dB)']);
disp(['Resonant Frequency (f_res):     ', num2str(f_peak, '%.2f'), ' Hz']);
disp(['Phase at Resonance:             ', num2str(phase_peak, '%.2f'), ' degrees']);

% Check if system exhibits resonance (Q > 0.707 indicates underdamped)
if Q_factor > 0.707
    disp(['System Status:                  UNDERDAMPED (Resonance Present)']);
    resonance_factor = mag_peak;  % Peak magnification
    disp(['Resonance Magnification:        ', num2str(resonance_factor, '%.2f'), 'x']);
else
    disp(['System Status:                  OVERDAMPED (No Resonance)']);
end

% =========================================================================
% PART D: OPERATING FREQUENCY ANALYSIS
% =========================================================================
disp(' ');
disp('--- OPERATING FREQUENCY ANALYSIS (f_ex = 1 kHz) ---');

% Find response at operating frequency (1 kHz)
[~, idx_op] = min(abs(f_out - f_ex));
f_operating = f_out(idx_op);
mag_operating = mag_abs(idx_op);
mag_operating_dB = mag_dB(idx_op);
phase_operating = phase_deg(idx_op);

disp(['Operating Frequency:            ', num2str(f_operating, '%.2f'), ' Hz']);
disp(['Magnitude at f_ex:              ', num2str(mag_operating, '%.6f'), ' (', num2str(mag_operating_dB, '%.2f'), ' dB)']);
disp(['Phase at f_ex:                  ', num2str(phase_operating, '%.2f'), ' degrees']);

% Check proximity to resonance
freq_ratio = f_operating / f_peak;
disp(['Frequency Ratio (f_ex/f_res):   ', num2str(freq_ratio, '%.4f')]);

if abs(freq_ratio - 1) < 0.1  % Within 10% of resonance
    disp('WARNING: Operating frequency is NEAR resonance peak!');
    disp('         This may cause instability or measurement issues.');
elseif abs(freq_ratio - 1) < 0.2  % Within 20% of resonance
    disp('CAUTION: Operating frequency is in resonance region.');
    disp('         Monitor for potential nonlinear effects.');
else
    disp('STATUS: Operating frequency is SAFE from resonance effects.');
end

% =========================================================================
% PART E: BANDWIDTH CALCULATION
% =========================================================================
disp(' ');
disp('--- BANDWIDTH ANALYSIS ---');

% Method 1: -3dB Bandwidth (standard definition)
% Find -3dB point relative to DC gain (or peak for bandpass)
mag_ref = mag_peak;  % Use peak as reference for bandpass filter
mag_3dB = mag_ref / sqrt(2);  % -3dB point
mag_3dB_threshold = 20 * log10(mag_3dB);

% Find lower and upper -3dB frequencies
idx_above_3dB = find(mag_abs >= mag_3dB);
if ~isempty(idx_above_3dB)
    idx_lower = idx_above_3dB(1);
    idx_upper = idx_above_3dB(end);
    
    f_lower_3dB = f_out(idx_lower);
    f_upper_3dB = f_out(idx_upper);
    BW_3dB = f_upper_3dB - f_lower_3dB;
    
    disp(['3dB Reference Level:            ', num2str(mag_3dB_threshold, '%.2f'), ' dB']);
    disp(['Lower -3dB Frequency (f_L):     ', num2str(f_lower_3dB, '%.2f'), ' Hz']);
    disp(['Upper -3dB Frequency (f_H):     ', num2str(f_upper_3dB, '%.2f'), ' Hz']);
    disp(['Bandwidth (BW = f_H - f_L):     ', num2str(BW_3dB, '%.2f'), ' Hz']);
    
    % Check if operating frequency is within bandwidth
    if f_operating >= f_lower_3dB && f_operating <= f_upper_3dB
        disp(['Operating Frequency Status:     WITHIN bandwidth (good)']);
    else
        disp(['Operating Frequency Status:     OUTSIDE bandwidth (check design)']);
    end
else
    disp('Warning: Could not determine -3dB bandwidth from data.');
    BW_3dB = NaN;
    f_lower_3dB = NaN;
    f_upper_3dB = NaN;
end

% Method 2: Theoretical Bandwidth (for 2nd-order systems)
BW_theoretical = f_n / Q_factor;
disp(['Theoretical Bandwidth (f_n/Q):  ', num2str(BW_theoretical, '%.2f'), ' Hz']);

% Method 3: Fractional Bandwidth
if ~isnan(BW_3dB)
    BW_fractional = (BW_3dB / f_peak) * 100;
    disp(['Fractional Bandwidth:           ', num2str(BW_fractional, '%.2f'), ' %']);
end

% =========================================================================
% PART F: PHASE ANALYSIS
% =========================================================================
disp(' ');
disp('--- PHASE ANALYSIS ---');

% Find -90° phase crossing (characteristic of resonance)
[~, idx_90] = min(abs(phase_deg + 90));
f_90deg = f_out(idx_90);
disp(['Frequency at -90° phase:        ', num2str(f_90deg, '%.2f'), ' Hz']);

% Phase margin at operating frequency
phase_margin = phase_operating + 180;  % Standard definition
disp(['Phase Margin at f_ex:           ', num2str(phase_margin, '%.2f'), ' degrees']);

% =========================================================================
% PART G: EXPORT DATA
% =========================================================================
disp(' ');
disp('--- DATA EXPORT ---');

% Export full Bode plot data
bode_data = [f_out, mag_abs, mag_dB, phase_deg];
writematrix(bode_data, 'results/data/bode_plot_data.csv');
disp('Bode plot data saved to bode_plot_data.csv');
disp('Columns: [Frequency(Hz), Magnitude(abs), Magnitude(dB), Phase(deg)]');

% Export summary statistics
summary_data = {
    'Parameter', 'Value', 'Units';
    'Natural Frequency (f_n)', f_n, 'Hz';
    'Natural Frequency (omega_n)', omega_n, 'rad/s';
    'Damping Ratio (zeta)', zeta, '-';
    'Quality Factor (Q)', Q_factor, '-';
    'Resonant Frequency', f_peak, 'Hz';
    'Peak Magnitude', mag_peak, 'abs';
    'Peak Magnitude', mag_peak_dB, 'dB';
    'Operating Frequency', f_operating, 'Hz';
    'Magnitude at f_ex', mag_operating, 'abs';
    'Magnitude at f_ex', mag_operating_dB, 'dB';
    'Phase at f_ex', phase_operating, 'deg';
    'Lower -3dB Freq', f_lower_3dB, 'Hz';
    'Upper -3dB Freq', f_upper_3dB, 'Hz';
    'Bandwidth (-3dB)', BW_3dB, 'Hz';
    'Theoretical BW', BW_theoretical, 'Hz';
    'Fractional BW', BW_fractional, '%';
    'Freq Ratio (f_ex/f_res)', freq_ratio, '-';
    'Phase Margin', phase_margin, 'deg'
};
writecell(summary_data, 'results/data/frequency_response_summary.csv');
disp('Summary statistics saved to frequency_response_summary.csv');

% =========================================================================
% PART H: VISUALIZATION
% =========================================================================

% Figure 1: Complete Bode Plot (Magnitude and Phase)
figure(1);
subplot(2,1,1);
semilogx(f_out, mag_dB, 'b-', 'LineWidth', 2);
hold on;
% Mark operating frequency
plot(f_operating, mag_operating_dB, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
% Mark resonant frequency
plot(f_peak, mag_peak_dB, 'g^', 'MarkerSize', 10, 'LineWidth', 2);
% Mark -3dB bandwidth
if ~isnan(BW_3dB)
    plot(f_lower_3dB, mag_3dB_threshold, 'ms', 'MarkerSize', 8, 'LineWidth', 2);
    plot(f_upper_3dB, mag_3dB_threshold, 'ms', 'MarkerSize', 8, 'LineWidth', 2);
    yline(mag_3dB_threshold, 'k--', 'LineWidth', 1, 'Label', '-3dB');
end
title(['Bode Plot: Magnitude (R_{soil} = ', num2str(R_soil_baseline/1000), ' kΩ)']);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
grid on;
legend('Frequency Response', 'Operating Freq (1 kHz)', 'Resonant Freq', ...
       '-3dB Points', 'Location', 'best');

subplot(2,1,2);
semilogx(f_out, phase_deg, 'b-', 'LineWidth', 2);
hold on;
% Mark operating frequency
plot(f_operating, phase_operating, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
% Mark resonant frequency
plot(f_peak, phase_peak, 'g^', 'MarkerSize', 10, 'LineWidth', 2);
% Mark -90° line
yline(-90, 'k--', 'LineWidth', 1, 'Label', '-90°');
title('Bode Plot: Phase');
xlabel('Frequency (Hz)');
ylabel('Phase (degrees)');
grid on;
legend('Phase Response', 'Operating Freq (1 kHz)', 'Resonant Freq', ...
       'Location', 'best');

% Figure 2: Zoomed View Around Operating Frequency
figure(2);
% Define zoom range: ±50% around operating frequency
f_zoom_min = f_ex * 0.1;
f_zoom_max = f_ex * 10;
idx_zoom = (f_out >= f_zoom_min) & (f_out <= f_zoom_max);

subplot(2,1,1);
semilogx(f_out(idx_zoom), mag_dB(idx_zoom), 'b-', 'LineWidth', 2);
hold on;
plot(f_operating, mag_operating_dB, 'ro', 'MarkerSize', 12, 'LineWidth', 2);
if f_peak >= f_zoom_min && f_peak <= f_zoom_max
    plot(f_peak, mag_peak_dB, 'g^', 'MarkerSize', 12, 'LineWidth', 2);
end
title(['Magnitude Response Near Operating Frequency (', num2str(f_ex/1000), ' kHz)']);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
grid on;
legend('Frequency Response', 'Operating Freq', 'Resonant Freq', 'Location', 'best');

subplot(2,1,2);
semilogx(f_out(idx_zoom), phase_deg(idx_zoom), 'b-', 'LineWidth', 2);
hold on;
plot(f_operating, phase_operating, 'ro', 'MarkerSize', 12, 'LineWidth', 2);
if f_peak >= f_zoom_min && f_peak <= f_zoom_max
    plot(f_peak, phase_peak, 'g^', 'MarkerSize', 12, 'LineWidth', 2);
end
yline(-90, 'k--', 'LineWidth', 1);
title('Phase Response Near Operating Frequency');
xlabel('Frequency (Hz)');
ylabel('Phase (degrees)');
grid on;
legend('Phase Response', 'Operating Freq', 'Resonant Freq', 'Location', 'best');

% Figure 3: Nyquist Plot (for stability analysis)
figure(3);
nyquist(H_s);
title(['Nyquist Plot (R_{soil} = ', num2str(R_soil_baseline/1000), ' kΩ)']);
grid on;

% Figure 4: Step Response (time-domain behavior)
figure(4);
step(H_s);
title(['Step Response (R_{soil} = ', num2str(R_soil_baseline/1000), ' kΩ)']);
grid on;

disp(' ');
disp('===========================================================');
disp('FREQUENCY RESPONSE ANALYSIS COMPLETE');
disp('===========================================================');
