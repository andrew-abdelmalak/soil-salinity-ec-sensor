% =========================================================================
% Soil Salinity (EC)
% Simulation Execution and Performance Analysis
% =========================================================================
clear all; close all; clc;

% 1. Setup Parameters and Initial Conditions
run('setup_parameters.m');

% Initial conditions [q(0); q_dot(0)] = [0; 0]
y0 = [0; 0]; 

% 2. Run Dynamic Simulation (using ODE solver - ode15s recommended for stiff systems)
disp('Running ODE simulation...');
% Use R_soil_baseline for this dynamic run
[T, Y] = ode15s(@(t, y) ode_function(t, y, L_coil, C_dl, R_soil_baseline, V_peak, f_ex), [0 T_sim], y0);

% Extract simulation results
Q_out = Y(:, 1);  % Charge response
I_out = Y(:, 2);  % Current response (The sensed signal I(t))

% --- SAVE DATA FOR DYNAMIC RESPONSE (Figure 1) ---
dynamic_data = [T, I_out];
writematrix(dynamic_data, 'results/data/dynamic_response_data.csv');
disp('Simulation complete. Dynamic response data saved to dynamic_response_data.csv.');

% 3. Theoretical Characterization (from Transfer Function)
% Denominator: s^2 + (R_soil/L)s + 1/(L*C_dl) = 0
omega_n_rad = sqrt(1 / (L_coil * C_dl));
damping_ratio = (R_soil_baseline / (2 * L_coil)) * sqrt(L_coil * C_dl);
f_n_Hz = omega_n_rad / (2 * pi);

% 4. Static Characterization (Peak Current at Excitation Frequency)
s = 1j * 2 * pi * f_ex;
Y_s = (C_dl * s) / (L_coil * C_dl * s^2 + R_soil_baseline * C_dl * s + 1);
I_mag = abs(Y_s) * V_peak; % Peak output current

% System Sensitivity: I_mag change w.r.t R_soil change (linear approx at operating point)
K_sys = I_mag / R_soil_baseline; 

% 5. Dynamic Characterization
% Note: This calculation assumes a high-Q system for BW, but BW is generally defined by the -3dB point
Quality_Factor = 1 / (2 * damping_ratio); 
Bandwidth_Hz = f_n_Hz / Quality_Factor;

% 6. Display Results (Report Summary Table Content)
disp(' ');
disp('===========================================================');
disp('BASELINE PERFORMANCE CHARACTERIZATION (Project 13)');
disp('===========================================================');
disp(['Excitation Frequency (f_ex):         ', num2str(f_ex/1000), ' kHz']);
disp(['Baseline Resistance (R_soil):        ', num2str(R_soil_baseline/1000), ' kOhm']);
disp('-----------------------------------------------------------');
disp(['Natural Frequency (f_n):             ', num2str(f_n_Hz), ' Hz']);
disp(['Natural Angular Freq (omega_n):      ', num2str(omega_n_rad), ' rad/s']);
disp(['Damping Ratio (zeta):                ', num2str(damping_ratio)]);
disp(['Quality Factor (Q):                  ', num2str(Quality_Factor)]);
disp(['Bandwidth (BW):                      ', num2str(Bandwidth_Hz), ' Hz']);
disp(['Peak Output Current (I_peak @ f_ex): ', num2str(I_mag*1000), ' mA']);
disp(['Calculated Sensitivity (K_sys):      ', num2str(K_sys*1e6), ' uA/Ohm']);
disp('===========================================================');

% 7. Plotting and Saving Data for Plots (Cont.)

% --- Figure 1: Dynamic Response ---
figure(1);
plot(T * 1000, I_out * 1000); % Convert to ms and mA
title(['Dynamic Response: Output Current I(t) @ R_{soil} = ', num2str(R_soil_baseline/1000), ' k\Omega']);
xlabel('Time (ms)');
ylabel('Output Current (mA)');
grid on;

% --- Figure 2: Static/Calibration Response (R_sweep) ---
R_sweep = logspace(log10(R_soil_min), log10(R_soil_max), 100); 
I_sweep = zeros(size(R_sweep));

% Recalculate steady state I_mag for all R values
for k = 1:length(R_sweep)
    R_current = R_sweep(k);
    s_curr = 1j * 2 * pi * f_ex;
    Y_s_curr = (C_dl * s_curr) / (L_coil * C_dl * s_curr^2 + R_current * C_dl * s_curr + 1);
    I_sweep(k) = abs(Y_s_curr) * V_peak;
end

% --- SAVE DATA FOR STATIC/AMPLITUDE RESPONSE ---
static_data = [R_sweep', I_sweep']; 
writematrix(static_data, 'results/data/static_response_data.csv');
disp('Static response data saved to static_response_data.csv.');

figure(2);
loglog(R_sweep, I_sweep); % Use log-log scale for RLC non-linear relationship
title(['Static/Amplitude Response (I_{peak} vs. R_{soil}) @ f_{ex} = ', num2str(f_ex/1000), ' kHz']);
xlabel('Soil Resistance R_{soil} (\Omega)');
ylabel('Peak Output Current (A)');
grid on;

% =========================================================================
% --- NEW: Figure 3: Frequency Response / Resonance Behavior (Bode Plot) ---
% =========================================================================

% Transfer Function H(s) = Numerator(s) / Denominator(s)
num = [C_dl, 0];
den = [L_coil * C_dl, R_soil_baseline * C_dl, 1];

% Create Transfer Function Model (Requires Control System Toolbox)
H_s = tf(num, den);

% Define frequency range centered around the natural frequency (f_n_Hz)
f_start = f_n_Hz / 100;
f_end = f_n_Hz * 100;
w_vec = logspace(log10(2*pi*f_start), log10(2*pi*f_end), 500);

% Calculate Magnitude (mag) and Phase (phase) from the Bode plot
[mag_abs, phase_deg, w_out] = bode(H_s, w_vec);

% Reshape output vectors (bode output is 3D for SISO systems)
mag_abs = reshape(mag_abs, 1, [])'; 
phase_deg = reshape(phase_deg, 1, [])'; 
f_out = w_out / (2 * pi); % Convert omega (rad/s) back to Frequency (Hz)

% --- SAVE DATA FOR FREQUENCY RESPONSE (Figure 3) ---
frequency_data = [f_out, mag_abs, phase_deg];
writematrix(frequency_data, 'results/data/frequency_response_data.csv');
disp('Frequency response data saved to frequency_response_data.csv.');

% Plotting the Magnitude (Resonance Plot)
figure(3);
semilogx(f_out, 20*log10(mag_abs)); % Plot Magnitude in dB vs. Frequency in Hz
title(['Frequency Response Magnitude (Resonance) @ R_{soil} = ', num2str(R_soil_baseline/1000), ' k\Omega']);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
grid on;