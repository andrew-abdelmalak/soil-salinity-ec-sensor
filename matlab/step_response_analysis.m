% =========================================================================
% Soil Salinity (EC)
% Step Response Analysis: Fresh Water (Low EC) vs. Salty Water (High EC)
% =========================================================================
clear all; close all; clc;

% 1. Load System Parameters
run('setup_parameters.m');

disp('===========================================================');
disp('STEP RESPONSE ANALYSIS: FRESH WATER vs. SALTY WATER');
disp('===========================================================');

% =========================================================================
% PART A: DEFINE TEST CONDITIONS
% =========================================================================
disp(' ');
disp('--- TEST CONDITIONS ---');

% EC (Electrical Conductivity) Relationship:
% - Low EC (Fresh Water):  Low conductivity → HIGH resistance
% - High EC (Salty Water): High conductivity → LOW resistance

% Fresh Water Condition (Low EC)
% Typical fresh water: EC ≈ 0.05-0.8 mS/cm → R ≈ 100-200 kΩ
R_fresh = 150e3;  % 150 kΩ (fresh water, low conductivity)

% Salty Water Condition (High EC)
% Typical seawater: EC ≈ 50-60 mS/cm → R ≈ 10-100 Ω
R_salty = 50;  % 50 Ω (salty/seawater, high conductivity)

% Baseline/Reference Condition (Medium EC)
R_baseline = R_soil_baseline;  % 10 kΩ (from setup_parameters.m)

disp(['Fresh Water:  R = ', num2str(R_fresh/1000), ' kΩ (Low EC, High Resistance)']);
disp(['Salty Water:  R = ', num2str(R_salty), ' Ω (High EC, Low Resistance)']);
disp(['Baseline:     R = ', num2str(R_baseline/1000), ' kΩ (Medium EC, Reference)']);

% =========================================================================
% PART B: CREATE TRANSFER FUNCTIONS FOR EACH CONDITION
% =========================================================================
disp(' ');
disp('--- TRANSFER FUNCTION MODELS ---');

% Transfer Function: H(s) = (C_dl * s) / (L_coil * C_dl * s^2 + R_soil * C_dl * s + 1)

% Fresh Water System
num_fresh = [C_dl, 0];
den_fresh = [L_coil * C_dl, R_fresh * C_dl, 1];
H_fresh = tf(num_fresh, den_fresh);

% Salty Water System
num_salty = [C_dl, 0];
den_salty = [L_coil * C_dl, R_salty * C_dl, 1];
H_salty = tf(num_salty, den_salty);

% Baseline System
num_baseline = [C_dl, 0];
den_baseline = [L_coil * C_dl, R_baseline * C_dl, 1];
H_baseline = tf(num_baseline, den_baseline);

disp('Transfer functions created for all three conditions.');

% =========================================================================
% PART C: CALCULATE THEORETICAL SYSTEM CHARACTERISTICS
% =========================================================================
disp(' ');
disp('--- THEORETICAL SYSTEM CHARACTERISTICS ---');

% Natural frequency (same for all, independent of R)
omega_n = sqrt(1 / (L_coil * C_dl));
f_n = omega_n / (2 * pi);

% --- Fresh Water ---
zeta_fresh = (R_fresh / (2 * L_coil)) * sqrt(L_coil * C_dl);
Q_fresh = 1 / (2 * zeta_fresh);
tau_fresh = 1 / (zeta_fresh * omega_n);  % Time constant

% Determine damping type
if zeta_fresh < 1
    damping_type_fresh = 'UNDERDAMPED';
    omega_d_fresh = omega_n * sqrt(1 - zeta_fresh^2);  % Damped natural frequency
    T_d_fresh = 2 * pi / omega_d_fresh;  % Period of oscillation
elseif zeta_fresh == 1
    damping_type_fresh = 'CRITICALLY DAMPED';
    omega_d_fresh = NaN;
    T_d_fresh = NaN;
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
elseif zeta_salty == 1
    damping_type_salty = 'CRITICALLY DAMPED';
    omega_d_salty = NaN;
    T_d_salty = NaN;
else
    damping_type_salty = 'OVERDAMPED';
    omega_d_salty = NaN;
    T_d_salty = NaN;
end

% --- Baseline ---
zeta_baseline = (R_baseline / (2 * L_coil)) * sqrt(L_coil * C_dl);
Q_baseline = 1 / (2 * zeta_baseline);
tau_baseline = 1 / (zeta_baseline * omega_n);

if zeta_baseline < 1
    damping_type_baseline = 'UNDERDAMPED';
    omega_d_baseline = omega_n * sqrt(1 - zeta_baseline^2);
    T_d_baseline = 2 * pi / omega_d_baseline;
elseif zeta_baseline == 1
    damping_type_baseline = 'CRITICALLY DAMPED';
    omega_d_baseline = NaN;
    T_d_baseline = NaN;
else
    damping_type_baseline = 'OVERDAMPED';
    omega_d_baseline = NaN;
    T_d_baseline = NaN;
end

% Display results
disp(' ');
disp('=== FRESH WATER (Low EC) ===');
disp(['Damping Ratio (ζ):           ', num2str(zeta_fresh, '%.6f')]);
disp(['Quality Factor (Q):          ', num2str(Q_fresh, '%.6f')]);
disp(['Damping Type:                ', damping_type_fresh]);
disp(['Time Constant (τ):           ', num2str(tau_fresh*1000, '%.3f'), ' ms']);
if ~isnan(T_d_fresh)
    disp(['Oscillation Period (T_d):    ', num2str(T_d_fresh*1000, '%.3f'), ' ms']);
    disp(['Damped Frequency (f_d):      ', num2str(1/T_d_fresh, '%.2f'), ' Hz']);
end

disp(' ');
disp('=== SALTY WATER (High EC) ===');
disp(['Damping Ratio (ζ):           ', num2str(zeta_salty, '%.6f')]);
disp(['Quality Factor (Q):          ', num2str(Q_salty, '%.6f')]);
disp(['Damping Type:                ', damping_type_salty]);
disp(['Time Constant (τ):           ', num2str(tau_salty*1000, '%.3f'), ' ms']);
if ~isnan(T_d_salty)
    disp(['Oscillation Period (T_d):    ', num2str(T_d_salty*1000, '%.3f'), ' ms']);
    disp(['Damped Frequency (f_d):      ', num2str(1/T_d_salty, '%.2f'), ' Hz']);
end

disp(' ');
disp('=== BASELINE (Medium EC) ===');
disp(['Damping Ratio (ζ):           ', num2str(zeta_baseline, '%.6f')]);
disp(['Quality Factor (Q):          ', num2str(Q_baseline, '%.6f')]);
disp(['Damping Type:                ', damping_type_baseline]);
disp(['Time Constant (τ):           ', num2str(tau_baseline*1000, '%.3f'), ' ms']);
if ~isnan(T_d_baseline)
    disp(['Oscillation Period (T_d):    ', num2str(T_d_baseline*1000, '%.3f'), ' ms']);
    disp(['Damped Frequency (f_d):      ', num2str(1/T_d_baseline, '%.2f'), ' Hz']);
end

% =========================================================================
% PART D: RUN STEP RESPONSE SIMULATIONS
% =========================================================================
disp(' ');
disp('--- STEP RESPONSE SIMULATIONS ---');

% Determine appropriate simulation time (5x longest time constant)
t_sim_max = max([tau_fresh, tau_salty, tau_baseline]) * 5;
t_final = max(t_sim_max, 0.1);  % At least 100 ms

% Run step responses
[y_fresh, t_fresh] = step(H_fresh, t_final);
[y_salty, t_salty] = step(H_salty, t_final);
[y_baseline, t_baseline] = step(H_baseline, t_final);

disp(['Simulation time:             ', num2str(t_final*1000, '%.2f'), ' ms']);

% =========================================================================
% PART E: ANALYZE STEP RESPONSE CHARACTERISTICS
% =========================================================================
disp(' ');
disp('--- STEP RESPONSE METRICS ---');

% Use stepinfo for detailed analysis
info_fresh = stepinfo(H_fresh);
info_salty = stepinfo(H_salty);
info_baseline = stepinfo(H_baseline);

% --- Fresh Water Metrics ---
disp(' ');
disp('=== FRESH WATER ===');
disp(['Rise Time (10%-90%):         ', num2str(info_fresh.RiseTime*1000, '%.3f'), ' ms']);
disp(['Settling Time (2%):          ', num2str(info_fresh.SettlingTime*1000, '%.3f'), ' ms']);
disp(['Overshoot:                   ', num2str(info_fresh.Overshoot, '%.2f'), ' %']);
disp(['Peak Value:                  ', num2str(info_fresh.Peak, '%.6f')]);
disp(['Peak Time:                   ', num2str(info_fresh.PeakTime*1000, '%.3f'), ' ms']);
disp(['Steady-State Value:          ', num2str(info_fresh.SettlingMax, '%.6f')]);

% --- Salty Water Metrics ---
disp(' ');
disp('=== SALTY WATER ===');
disp(['Rise Time (10%-90%):         ', num2str(info_salty.RiseTime*1000, '%.3f'), ' ms']);
disp(['Settling Time (2%):          ', num2str(info_salty.SettlingTime*1000, '%.3f'), ' ms']);
disp(['Overshoot:                   ', num2str(info_salty.Overshoot, '%.2f'), ' %']);
disp(['Peak Value:                  ', num2str(info_salty.Peak, '%.6f')]);
disp(['Peak Time:                   ', num2str(info_salty.PeakTime*1000, '%.3f'), ' ms']);
disp(['Steady-State Value:          ', num2str(info_salty.SettlingMax, '%.6f')]);

% --- Baseline Metrics ---
disp(' ');
disp('=== BASELINE ===');
disp(['Rise Time (10%-90%):         ', num2str(info_baseline.RiseTime*1000, '%.3f'), ' ms']);
disp(['Settling Time (2%):          ', num2str(info_baseline.SettlingTime*1000, '%.3f'), ' ms']);
disp(['Overshoot:                   ', num2str(info_baseline.Overshoot, '%.2f'), ' %']);
disp(['Peak Value:                  ', num2str(info_baseline.Peak, '%.6f')]);
disp(['Peak Time:                   ', num2str(info_baseline.PeakTime*1000, '%.3f'), ' ms']);
disp(['Steady-State Value:          ', num2str(info_baseline.SettlingMax, '%.6f')]);

% =========================================================================
% PART F: COMPARATIVE ANALYSIS
% =========================================================================
disp(' ');
disp('--- COMPARATIVE ANALYSIS ---');

% Settling time comparison
settling_ratio = info_fresh.SettlingTime / info_salty.SettlingTime;
disp(['Settling Time Ratio (Fresh/Salty):  ', num2str(settling_ratio, '%.2f'), 'x']);

if settling_ratio > 1
    disp(['Fresh water settles ', num2str(settling_ratio, '%.2f'), 'x SLOWER than salty water']);
else
    disp(['Fresh water settles ', num2str(1/settling_ratio, '%.2f'), 'x FASTER than salty water']);
end

% Rise time comparison
rise_ratio = info_fresh.RiseTime / info_salty.RiseTime;
disp(['Rise Time Ratio (Fresh/Salty):      ', num2str(rise_ratio, '%.2f'), 'x']);

% Overshoot comparison
disp(['Overshoot Difference:               ', num2str(abs(info_fresh.Overshoot - info_salty.Overshoot), '%.2f'), ' %']);

% Damping comparison
disp(['Damping Ratio Difference:           ', num2str(abs(zeta_fresh - zeta_salty), '%.6f')]);

% Speed comparison
if info_fresh.SettlingTime > info_salty.SettlingTime
    disp('CONCLUSION: Salty water (high EC) responds FASTER due to higher damping.');
else
    disp('CONCLUSION: Fresh water (low EC) responds FASTER due to lower damping.');
end

% =========================================================================
% PART G: EXPORT DATA
% =========================================================================
disp(' ');
disp('--- DATA EXPORT ---');

% Export step response data
step_data_fresh = [t_fresh, y_fresh];
step_data_salty = [t_salty, y_salty];
step_data_baseline = [t_baseline, y_baseline];

writematrix(step_data_fresh, 'results/data/step_response_fresh.csv');
writematrix(step_data_salty, 'results/data/step_response_salty.csv');
writematrix(step_data_baseline, 'results/data/step_response_baseline.csv');

disp('Step response data saved:');
disp('  - step_response_fresh.csv');
disp('  - step_response_salty.csv');
disp('  - step_response_baseline.csv');

% Export summary comparison
summary_data = {
    'Metric', 'Fresh Water (Low EC)', 'Salty Water (High EC)', 'Baseline (Medium EC)', 'Units';
    'Resistance', R_fresh, R_salty, R_baseline, 'Ω';
    'Damping Ratio (ζ)', zeta_fresh, zeta_salty, zeta_baseline, '-';
    'Quality Factor (Q)', Q_fresh, Q_salty, Q_baseline, '-';
    'Damping Type', damping_type_fresh, damping_type_salty, damping_type_baseline, '-';
    'Time Constant (τ)', tau_fresh*1000, tau_salty*1000, tau_baseline*1000, 'ms';
    'Rise Time', info_fresh.RiseTime*1000, info_salty.RiseTime*1000, info_baseline.RiseTime*1000, 'ms';
    'Settling Time', info_fresh.SettlingTime*1000, info_salty.SettlingTime*1000, info_baseline.SettlingTime*1000, 'ms';
    'Overshoot', info_fresh.Overshoot, info_salty.Overshoot, info_baseline.Overshoot, '%';
    'Peak Value', info_fresh.Peak, info_salty.Peak, info_baseline.Peak, '-';
    'Peak Time', info_fresh.PeakTime*1000, info_salty.PeakTime*1000, info_baseline.PeakTime*1000, 'ms';
};

writecell(summary_data, 'results/data/step_response_comparison.csv');
disp('Summary comparison saved to step_response_comparison.csv');

% =========================================================================
% PART H: VISUALIZATION
% =========================================================================

% Figure 1: Overlaid Step Responses (Full View)
figure(1);
plot(t_fresh*1000, y_fresh, 'b-', 'LineWidth', 2);
hold on;
plot(t_salty*1000, y_salty, 'r-', 'LineWidth', 2);
plot(t_baseline*1000, y_baseline, 'g--', 'LineWidth', 1.5);

% Mark settling times
yline(info_fresh.SettlingMax * 1.02, 'k--', 'LineWidth', 0.5);
yline(info_fresh.SettlingMax * 0.98, 'k--', 'LineWidth', 0.5);

title('Step Response Comparison: Fresh Water vs. Salty Water');
xlabel('Time (ms)');
ylabel('Output Current Response (normalized)');
grid on;
legend(['Fresh Water (R=' num2str(R_fresh/1000) ' kΩ, ζ=' num2str(zeta_fresh, '%.4f') ')'], ...
       ['Salty Water (R=' num2str(R_salty) ' Ω, ζ=' num2str(zeta_salty, '%.4f') ')'], ...
       ['Baseline (R=' num2str(R_baseline/1000) ' kΩ, ζ=' num2str(zeta_baseline, '%.4f') ')'], ...
       '±2% Settling Bounds', ...
       'Location', 'southeast');

% Figure 2: Step Response Details (4 Subplots)
figure(2);

% Subplot 1: Fresh Water Only
subplot(2,2,1);
plot(t_fresh*1000, y_fresh, 'b-', 'LineWidth', 2);
hold on;
yline(info_fresh.SettlingMax, 'k--', 'LineWidth', 1);
xline(info_fresh.SettlingTime*1000, 'r--', 'LineWidth', 1, 'Label', ['T_s=' num2str(info_fresh.SettlingTime*1000, '%.1f') ' ms']);
title(['Fresh Water']);
xlabel('Time (ms)');
ylabel('Response');
grid on;
legend('Step Response', 'Steady-State', 'Location', 'southeast');

% Subplot 2: Salty Water Only
subplot(2,2,2);
plot(t_salty*1000, y_salty, 'r-', 'LineWidth', 2);
hold on;
yline(info_salty.SettlingMax, 'k--', 'LineWidth', 1);
xline(info_salty.SettlingTime*1000, 'r--', 'LineWidth', 1, 'Label', ['T_s=' num2str(info_salty.SettlingTime*1000, '%.1f') ' ms']);
title('Salty Water');
xlabel('Time (ms)');
ylabel('Response');
grid on;
legend('Step Response', 'Steady-State', 'Location', 'southeast');

% Subplot 3: Baseline Only
subplot(2,2,3);
plot(t_baseline*1000, y_baseline, 'g-', 'LineWidth', 2);
hold on;
yline(info_baseline.SettlingMax, 'k--', 'LineWidth', 1);
xline(info_baseline.SettlingTime*1000, 'r--', 'LineWidth', 1, 'Label', ['T_s=' num2str(info_baseline.SettlingTime*1000, '%.1f') ' ms']);
title('Baseline');
xlabel('Time (ms)');
ylabel('Response');
grid on;
legend('Step Response', 'Steady-State', 'Location', 'southeast');

% Subplot 4: Early-Time Comparison (Zoomed)
subplot(2,2,4);
t_zoom = min([info_fresh.SettlingTime, info_salty.SettlingTime, info_baseline.SettlingTime]) * 2;
idx_fresh = t_fresh <= t_zoom;
idx_salty = t_salty <= t_zoom;
idx_baseline = t_baseline <= t_zoom;

plot(t_fresh(idx_fresh)*1000, y_fresh(idx_fresh), 'b-', 'LineWidth', 2);
hold on;
plot(t_salty(idx_salty)*1000, y_salty(idx_salty), 'r-', 'LineWidth', 2);
plot(t_baseline(idx_baseline)*1000, y_baseline(idx_baseline), 'g--', 'LineWidth', 1.5);
title('Early-Time Response (Zoomed)');
xlabel('Time (ms)');
ylabel('Response');
grid on;
legend('Fresh', 'Salty', 'Baseline', 'Location', 'southeast');

% Figure 3: Comparative Bar Charts
figure(3);

subplot(1,3,1);
bar([zeta_fresh, zeta_salty, zeta_baseline]);
set(gca, 'XTickLabel', {'Fresh', 'Salty', 'Baseline'});
title('Damping Ratio (ζ)');
ylabel('Damping Ratio');
grid on;

subplot(1,3,2);
bar([info_fresh.SettlingTime*1000, info_salty.SettlingTime*1000, info_baseline.SettlingTime*1000]);
set(gca, 'XTickLabel', {'Fresh', 'Salty', 'Baseline'});
title('Settling Time (2%)');
ylabel('Time (ms)');
grid on;

subplot(1,3,3);
bar([info_fresh.Overshoot, info_salty.Overshoot, info_baseline.Overshoot]);
set(gca, 'XTickLabel', {'Fresh', 'Salty', 'Baseline'});
title('Overshoot');
ylabel('Overshoot (%)');
grid on;

disp(' ');
disp('===========================================================');
disp('STEP RESPONSE ANALYSIS COMPLETE');
disp('===========================================================');
