% =========================================================================
% Soil Salinity (EC)
% Performance Analysis with IMPROVED Parameters
% =========================================================================
clear all; close all; clc;

% Load IMPROVED MS2 parameters
run('setup_parameters_v2.m');

fprintf('\n');
fprintf('===========================================================\n');
fprintf('MS2 PERFORMANCE ANALYSIS (IMPROVED SENSOR)\n');
fprintf('===========================================================\n');

% Initial conditions
y0 = [0; 0];

% Run Dynamic Simulation
fprintf('Running ODE simulation with IMPROVED parameters...\n');
[T, Y] = ode15s(@(t, y) ode_function(t, y, L_coil, C_dl, R_soil_baseline, V_peak, f_ex), [0 T_sim], y0);

Q_out = Y(:, 1);  % Charge response
I_out = Y(:, 2);  % Current response

% Save dynamic response data
dynamic_data = [T, I_out];
writematrix(dynamic_data, 'results/data/dynamic_response_data_v2.csv');
fprintf('✓ MS2 dynamic response saved\n');

% Theoretical Characterization
omega_n_rad = sqrt(1 / (L_coil * C_dl));
damping_ratio = (R_soil_baseline / (2 * L_coil)) * sqrt(L_coil * C_dl);
f_n_Hz = omega_n_rad / (2 * pi);

% Static Characterization (Peak Current at Excitation Frequency)
s = 1j * 2 * pi * f_ex;
Y_s = (C_dl * s) / (L_coil * C_dl * s^2 + R_soil_baseline * C_dl * s + 1);
I_mag = abs(Y_s) * V_peak;

% System Sensitivity
K_sys = I_mag / R_soil_baseline;

% Dynamic Characterization
Quality_Factor = 1 / (2 * damping_ratio);
Bandwidth_Hz = f_n_Hz / Quality_Factor;

% Display Results
fprintf('\n');
fprintf('===========================================================\n');
fprintf('MS2 PERFORMANCE CHARACTERIZATION\n');
fprintf('===========================================================\n');
fprintf('Excitation Frequency (f_ex):         %.1f kHz\n', f_ex/1000);
fprintf('Baseline Resistance (R_soil):        %.1f kOhm (IMPROVED)\n', R_soil_baseline/1000);
fprintf('-----------------------------------------------------------\n');
fprintf('Natural Frequency (f_n):             %.2f Hz\n', f_n_Hz);
fprintf('Natural Angular Freq (ω_n):          %.2f rad/s\n', omega_n_rad);
fprintf('Damping Ratio (ζ):                   %.6f\n', damping_ratio);
fprintf('Quality Factor (Q):                  %.6e\n', Quality_Factor);
fprintf('Bandwidth (BW):                      %.2f Hz\n', Bandwidth_Hz);
fprintf('Peak Output Current (I_peak @ f_ex): %.6f mA\n', I_mag*1000);
fprintf('Calculated Sensitivity (K_sys):      %.6f μA/Ω\n', K_sys*1e6);
fprintf('===========================================================\n');
fprintf('\n');

% Static/Calibration Response
R_sweep = logspace(log10(R_soil_min), log10(R_soil_max), 100);
I_sweep = zeros(size(R_sweep));

for k = 1:length(R_sweep)
    R_current = R_sweep(k);
    s_curr = 1j * 2 * pi * f_ex;
    Y_s_curr = (C_dl * s_curr) / (L_coil * C_dl * s_curr^2 + R_current * C_dl * s_curr + 1);
    I_sweep(k) = abs(Y_s_curr) * V_peak;
end

% Save static response data
static_data = [R_sweep', I_sweep'];
writematrix(static_data, 'results/data/static_response_data_v2.csv');
fprintf('✓ MS2 static response saved\n');

% Frequency Response Data
f_start = f_n_Hz / 100;
f_end = f_n_Hz * 100;
f_out = logspace(log10(f_start), log10(f_end), 500);
mag_abs = zeros(size(f_out));

for k = 1:length(f_out)
    s_k = 1j * 2 * pi * f_out(k);
    Y_k = (C_dl * s_k) / (L_coil * C_dl * s_k^2 + R_soil_baseline * C_dl * s_k + 1);
    mag_abs(k) = abs(Y_k);
end

mag_dB = 20 * log10(mag_abs);

% Save frequency response data
frequency_data = [f_out', mag_abs', mag_dB'];
writematrix(frequency_data, 'results/data/frequency_response_data_v2.csv');
fprintf('✓ MS2 frequency response saved\n');

% --- Plotting ---
figure(1);
plot(T * 1000, I_out * 1000);
title(['MS2 Dynamic Response @ R_{soil} = ', num2str(R_soil_baseline/1000), ' kΩ']);
xlabel('Time (ms)');
ylabel('Output Current (mA)');
grid on;
saveas(gcf, 'results/figures/dynamic_response_v2.png');

figure(2);
loglog(R_sweep, I_sweep);
title(['MS2 Static Response @ f_{ex} = ', num2str(f_ex/1000), ' kHz']);
xlabel('Soil Resistance R_{soil} (Ω)');
ylabel('Peak Output Current (A)');
grid on;
saveas(gcf, 'results/figures/static_response_v2.png');

figure(3);
semilogx(f_out, mag_dB);
title(['MS2 Frequency Response @ R_{soil} = ', num2str(R_soil_baseline/1000), ' kΩ']);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
grid on;
saveas(gcf, 'results/figures/frequency_response_v2.png');

fprintf('\n');
fprintf('===========================================================\n');
fprintf('MS2 PERFORMANCE ANALYSIS COMPLETE\n');
fprintf('===========================================================\n');
