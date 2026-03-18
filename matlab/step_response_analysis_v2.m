% =========================================================================
% Soil Salinity (EC)
% Step Response Analysis with IMPROVED Parameters
% =========================================================================
clear all; close all; clc;

% Load IMPROVED MS2 parameters
run('setup_parameters_v2.m');

fprintf('\n');
fprintf('===========================================================\n');
fprintf('MS2 STEP RESPONSE ANALYSIS (IMPROVED SENSOR)\n');
fprintf('===========================================================\n');

% Fresh Water Condition (IMPROVED)
R_fresh = R_soil_baseline;  % 15 kOhm (was 150 kOhm in MS1)

% Salty Water Condition
R_salty = 50;  % 50 Ω (high conductivity - unchanged)

fprintf('Test Conditions:\n');
fprintf('  Fresh Water:  R = %.1f kOhm (IMPROVED from 150 kOhm)\n', R_fresh/1000);
fprintf('  Salty Water:  R = %.1f Ω\n', R_salty);
fprintf('\n');

% Natural frequency (same for all, independent of R)
omega_n = sqrt(1 / (L_coil * C_dl));
f_n = omega_n / (2 * pi);

fprintf('Natural Frequency: %.2f Hz\n', f_n);
fprintf('\n');

% --- Fresh Water ---
zeta_fresh = (R_fresh / (2 * L_coil)) * sqrt(L_coil * C_dl);
Q_fresh = 1 / (2 * zeta_fresh);
tau_fresh = 1 / (zeta_fresh * omega_n);

if zeta_fresh < 1
    damping_type_fresh = 'UNDERDAMPED';
    omega_d_fresh = omega_n * sqrt(1 - zeta_fresh^2);
    T_d_fresh = 2 * pi / omega_d_fresh;
else
    damping_type_fresh = 'OVERDAMPED';
    omega_d_fresh = NaN;
    T_d_fresh = NaN;
end

% --- Salty Water ---
zeta_salty = (R_salty / (2 * L_coil)) * sqrt(L_coil * C_dl);
Q_salty = 1 / (2 * zeta_salty);
tau_salty = 1 / (zeta_salty * omega_n);

if zeta_salty < 1
    damping_type_salty = 'UNDERDAMPED';
    omega_d_salty = omega_n * sqrt(1 - zeta_salty^2);
    T_d_salty = 2 * pi / omega_d_salty;
else
    damping_type_salty = 'OVERDAMPED';
    omega_d_salty = NaN;
    T_d_salty = NaN;
end

% Display characteristics
fprintf('=== FRESH WATER (IMPROVED) ===\n');
fprintf('  Damping Ratio (ζ):           %.6f\n', zeta_fresh);
fprintf('  Quality Factor (Q):          %.6f\n', Q_fresh);
fprintf('  Damping Type:                %s\n', damping_type_fresh);
fprintf('  Time Constant (τ):           %.3f ms\n', tau_fresh*1000);
if ~isnan(T_d_fresh)
    fprintf('  Oscillation Period (T_d):    %.3f ms\n', T_d_fresh*1000);
end
fprintf('\n');

fprintf('=== SALTY WATER ===\n');
fprintf('  Damping Ratio (ζ):           %.6f\n', zeta_salty);
fprintf('  Quality Factor (Q):          %.6f\n', Q_salty);
fprintf('  Damping Type:                %s\n', damping_type_salty);
fprintf('  Time Constant (τ):           %.3f ms\n', tau_salty*1000);
if ~isnan(T_d_salty)
    fprintf('  Oscillation Period (T_d):    %.3f ms\n', T_d_salty*1000);
end
fprintf('\n');

% Create transfer functions
num_fresh = [C_dl, 0];
den_fresh = [L_coil * C_dl, R_fresh * C_dl, 1];
H_fresh = tf(num_fresh, den_fresh);

num_salty = [C_dl, 0];
den_salty = [L_coil * C_dl, R_salty * C_dl, 1];
H_salty = tf(num_salty, den_salty);

% Simulate step responses
[y_fresh, t_fresh] = step(H_fresh);
[y_salty, t_salty] = step(H_salty);

% Get step response metrics
info_fresh = stepinfo(H_fresh);
info_salty = stepinfo(H_salty);

fprintf('=== STEP RESPONSE METRICS ===\n\n');
fprintf('FRESH WATER (IMPROVED):\n');
fprintf('  Rise Time (10%%-90%%):         %.3f ms\n', info_fresh.RiseTime*1000);
fprintf('  Settling Time (2%%):          %.3f ms\n', info_fresh.SettlingTime*1000);
fprintf('  Overshoot:                   %.2f %%\n', info_fresh.Overshoot);
fprintf('  Peak Time:                   %.3f ms\n', info_fresh.PeakTime*1000);
fprintf('\n');

fprintf('SALTY WATER:\n');
fprintf('  Rise Time (10%%-90%%):         %.3f ms\n', info_salty.RiseTime*1000);
fprintf('  Settling Time (2%%):          %.3f ms\n', info_salty.SettlingTime*1000);
fprintf('  Overshoot:                   %.2f %%\n', info_salty.Overshoot);
fprintf('  Peak Time:                   %.3f ms\n', info_salty.PeakTime*1000);
fprintf('\n');

% Save data
step_data_fresh_MS2 = [t_fresh, y_fresh];
step_data_salty_MS2 = [t_salty, y_salty];

writematrix(step_data_fresh_MS2, 'results/data/step_response_fresh_v2.csv');
writematrix(step_data_salty_MS2, 'results/data/step_response_salty_v2.csv');

% Summary comparison
summary_data = {
    'Metric', 'Fresh Water (MS2)', 'Salty Water', 'Units';
    'Resistance', R_fresh, R_salty, 'Ω';
    'Damping Ratio (ζ)', zeta_fresh, zeta_salty, '-';
    'Time Constant (τ)', tau_fresh*1000, tau_salty*1000, 'ms';
    'Rise Time', info_fresh.RiseTime*1000, info_salty.RiseTime*1000, 'ms';
    'Settling Time', info_fresh.SettlingTime*1000, info_salty.SettlingTime*1000, 'ms';
    'Overshoot', info_fresh.Overshoot, info_salty.Overshoot, '%';
};

writecell(summary_data, 'results/data/step_response_comparison_v2.csv');
fprintf('✓ MS2 step response data saved\n');
fprintf('\n');

% Plotting
figure(1);
plot(t_fresh*1000, y_fresh, 'b-', 'LineWidth', 2);
hold on;
plot(t_salty*1000, y_salty, 'r-', 'LineWidth', 2);
yline(info_fresh.SettlingMax * 1.02, 'k--', 'LineWidth', 0.5);
yline(info_fresh.SettlingMax * 0.98, 'k--', 'LineWidth', 0.5);
title('MS2 Step Response Comparison (Improved Sensor)');
xlabel('Time (ms)');
ylabel('Response');
grid on;
legend('Fresh Water (15kΩ - IMPROVED)', 'Salty Water (50Ω)', '±2% Band', 'Location', 'southeast');

saveas(gcf, 'results/figures/step_response_v2.png');

fprintf('===========================================================\n');
% fprintf('MS2 STEP RESPONSE ANALYSIS COMPLETE\n');
fprintf('===========================================================\n');
