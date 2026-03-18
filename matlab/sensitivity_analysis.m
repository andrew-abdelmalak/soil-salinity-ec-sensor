% =========================================================================
% Soil Salinity (EC)
% Sensitivity Analysis: Output vs. Input and Measurand
% =========================================================================
clear all; close all; clc;

% 1. Load System Parameters
run('setup_parameters.m');

disp('===========================================================');
disp('SENSITIVITY ANALYSIS');
disp('===========================================================');

% ====================4=====================================================
% PART A: MEASURAND SENSITIVITY (∂I_out/∂R_soil)
% =========================================================================
disp(' ');
disp('--- MEASURAND SENSITIVITY (∂I_out/∂R_soil) ---');

% Define the operating point for sensitivity calculation
R_operating = R_soil_baseline; % 10 kOhm

% Transfer function admittance at excitation frequency
s = 1j * 2 * pi * f_ex;

% Output current magnitude at operating point
Y_s_op = (C_dl * s) / (L_coil * C_dl * s^2 + R_operating * C_dl * s + 1);
I_mag_op = abs(Y_s_op) * V_peak;

% Analytical Sensitivity using Partial Derivative
% Y(s) = (C_dl * s) / (L_coil * C_dl * s^2 + R_soil * C_dl * s + 1)
% ∂Y/∂R_soil = -(C_dl * s) * (C_dl * s) / (L_coil * C_dl * s^2 + R_soil * C_dl * s + 1)^2
% ∂I/∂R_soil = V_peak * ∂|Y|/∂R_soil

% Denominator and its derivative
D_op = L_coil * C_dl * s^2 + R_operating * C_dl * s + 1;
dD_dR = C_dl * s; % Derivative of denominator w.r.t R_soil

% Derivative of admittance (complex)
dY_dR = -(C_dl * s) * dD_dR / (D_op^2);

% For magnitude: d|Y|/dR ≈ Re(Y* · dY/dR) / |Y|
% where Y* is complex conjugate of Y
dI_dR_analytical = V_peak * real(conj(Y_s_op) * dY_dR) / abs(Y_s_op);

% Numerical Sensitivity using Finite Difference
delta_R = 0.01 * R_operating; % 1% perturbation
R_plus = R_operating + delta_R;
R_minus = R_operating - delta_R;

Y_s_plus = (C_dl * s) / (L_coil * C_dl * s^2 + R_plus * C_dl * s + 1);
Y_s_minus = (C_dl * s) / (L_coil * C_dl * s^2 + R_minus * C_dl * s + 1);

I_mag_plus = abs(Y_s_plus) * V_peak;
I_mag_minus = abs(Y_s_minus) * V_peak;

dI_dR_numerical = (I_mag_plus - I_mag_minus) / (2 * delta_R);

% Relative/Normalized Sensitivity (dimensionless)
S_R = (dI_dR_analytical * R_operating) / I_mag_op;

disp(['Operating Point R_soil:             ', num2str(R_operating/1000), ' kΩ']);
disp(['Output Current @ Operating Point:   ', num2str(I_mag_op*1e6), ' μA']);
disp(['Analytical Sensitivity (dI/dR):     ', num2str(dI_dR_analytical*1e6), ' μA/Ω']);
disp(['Numerical Sensitivity (dI/dR):      ', num2str(dI_dR_numerical*1e6), ' μA/Ω']);
disp(['Relative Sensitivity S_R:           ', num2str(S_R)]);

% =========================================================================
% PART B: INPUT SENSITIVITY (∂I_out/∂V_in)
% =========================================================================
disp(' ');
disp('--- INPUT SENSITIVITY (∂I_out/∂V_in) ---');

% For linear systems: I_out = |Y(s)| * V_in
% Therefore: ∂I_out/∂V_in = |Y(s)|
dI_dV_analytical = abs(Y_s_op);

% Numerical verification
delta_V = 0.01 * V_peak; % 1% perturbation
V_plus = V_peak + delta_V;
V_minus = V_peak - delta_V;

I_mag_V_plus = abs(Y_s_op) * V_plus;
I_mag_V_minus = abs(Y_s_op) * V_minus;

dI_dV_numerical = (I_mag_V_plus - I_mag_V_minus) / (2 * delta_V);

% Relative Sensitivity
S_V = (dI_dV_analytical * V_peak) / I_mag_op;

disp(['Input Voltage V_peak:               ', num2str(V_peak), ' V']);
disp(['Analytical Sensitivity (dI/dV_in):  ', num2str(dI_dV_analytical*1e6), ' μA/V']);
disp(['Numerical Sensitivity (dI/dV_in):   ', num2str(dI_dV_numerical*1e6), ' μA/V']);
disp(['Relative Sensitivity S_V:           ', num2str(S_V)]);

% =========================================================================
% PART C: SENSITIVITY AS A FUNCTION OF R_soil
% =========================================================================
disp(' ');
disp('--- SENSITIVITY VARIATION ACROSS MEASUREMENT RANGE ---');

% Sweep R_soil from min to max
R_sweep = logspace(log10(R_soil_min), log10(R_soil_max), 100);
I_sweep = zeros(size(R_sweep));
Sensitivity_sweep = zeros(size(R_sweep));

for k = 1:length(R_sweep)
    R_current = R_sweep(k);
    
    % Calculate output current
    Y_s_curr = (C_dl * s) / (L_coil * C_dl * s^2 + R_current * C_dl * s + 1);
    I_sweep(k) = abs(Y_s_curr) * V_peak;
    
    % Calculate sensitivity at this point
    D_curr = L_coil * C_dl * s^2 + R_current * C_dl * s + 1;
    dY_dR_curr = -(C_dl * s) * (C_dl * s) / (D_curr^2);
    Sensitivity_sweep(k) = V_peak * real(conj(Y_s_curr) * dY_dR_curr) / abs(Y_s_curr);
end

% Save sensitivity data
sensitivity_data = [R_sweep', I_sweep', Sensitivity_sweep'];
writematrix(sensitivity_data, 'results/data/sensitivity_data.csv');
disp('Sensitivity sweep data saved to sensitivity_data.csv.');

% =========================================================================
% PART D: PARAMETRIC SENSITIVITIES (Advanced)
% =========================================================================
disp(' ');
disp('--- PARAMETRIC SENSITIVITIES ---');

% Sensitivity to Inductance L
delta_L = 0.01 * L_coil;
Y_s_L_plus = (C_dl * s) / ((L_coil + delta_L) * C_dl * s^2 + R_operating * C_dl * s + 1);
Y_s_L_minus = (C_dl * s) / ((L_coil - delta_L) * C_dl * s^2 + R_operating * C_dl * s + 1);
I_L_plus = abs(Y_s_L_plus) * V_peak;
I_L_minus = abs(Y_s_L_minus) * V_peak;
dI_dL = (I_L_plus - I_L_minus) / (2 * delta_L);
S_L = (dI_dL * L_coil) / I_mag_op;

% Sensitivity to Capacitance C
delta_C = 0.01 * C_dl;
Y_s_C_plus = ((C_dl + delta_C) * s) / (L_coil * (C_dl + delta_C) * s^2 + R_operating * (C_dl + delta_C) * s + 1);
Y_s_C_minus = ((C_dl - delta_C) * s) / (L_coil * (C_dl - delta_C) * s^2 + R_operating * (C_dl - delta_C) * s + 1);
I_C_plus = abs(Y_s_C_plus) * V_peak;
I_C_minus = abs(Y_s_C_minus) * V_peak;
dI_dC = (I_C_plus - I_C_minus) / (2 * delta_C);
S_C = (dI_dC * C_dl) / I_mag_op;

% Sensitivity to Excitation Frequency f_ex
delta_f = 0.01 * f_ex;
s_f_plus = 1j * 2 * pi * (f_ex + delta_f);
s_f_minus = 1j * 2 * pi * (f_ex - delta_f);
Y_s_f_plus = (C_dl * s_f_plus) / (L_coil * C_dl * s_f_plus^2 + R_operating * C_dl * s_f_plus + 1);
Y_s_f_minus = (C_dl * s_f_minus) / (L_coil * C_dl * s_f_minus^2 + R_operating * C_dl * s_f_minus + 1);
I_f_plus = abs(Y_s_f_plus) * V_peak;
I_f_minus = abs(Y_s_f_minus) * V_peak;
dI_df = (I_f_plus - I_f_minus) / (2 * delta_f);
S_f = (dI_df * f_ex) / I_mag_op;

disp(['Relative Sensitivity to L (S_L):    ', num2str(S_L)]);
disp(['Relative Sensitivity to C (S_C):    ', num2str(S_C)]);
disp(['Relative Sensitivity to f (S_f):    ', num2str(S_f)]);

% =========================================================================
% PART E: LINEARITY ANALYSIS
% =========================================================================
disp(' ');
disp('===========================================================');
disp('LINEARITY ANALYSIS');
disp('===========================================================');

% -------------------------------------------------------------------------
% E1: INPUT VOLTAGE LINEARITY (V_in vs I_out)
% -------------------------------------------------------------------------
disp(' ');
disp('--- INPUT VOLTAGE LINEARITY (V_in vs I_out) ---');

% Sweep input voltage from 0 to 2*V_peak
V_sweep = linspace(0, 2*V_peak, 50);
I_V_sweep = zeros(size(V_sweep));

for k = 1:length(V_sweep)
    V_current = V_sweep(k);
    % Linear relationship: I = |Y(s)| * V
    I_V_sweep(k) = abs(Y_s_op) * V_current;
end

% Best-fit straight line using linear regression
p_V = polyfit(V_sweep, I_V_sweep, 1); % [slope, intercept]
I_V_fit = polyval(p_V, V_sweep);

% Calculate linearity metrics
I_V_error = I_V_sweep - I_V_fit; % Deviation from best-fit line
I_V_max_error = max(abs(I_V_error));
I_V_FSO = max(I_V_sweep) - min(I_V_sweep); % Full-Scale Output
Linearity_V_percent = (I_V_max_error / I_V_FSO) * 100;

% R-squared (coefficient of determination)
SS_res_V = sum(I_V_error.^2); % Residual sum of squares
SS_tot_V = sum((I_V_sweep - mean(I_V_sweep)).^2); % Total sum of squares
R_squared_V = 1 - (SS_res_V / SS_tot_V);

disp(['Voltage Range:                  0 to ', num2str(max(V_sweep)), ' V']);
disp(['Current Range:                  0 to ', num2str(max(I_V_sweep)*1e6, '%.3f'), ' μA']);
disp(['Best-Fit Slope:                 ', num2str(p_V(1)*1e6, '%.6f'), ' μA/V']);
disp(['Best-Fit Intercept:             ', num2str(p_V(2)*1e9, '%.3f'), ' nA']);
disp(['Maximum Linearity Error:        ', num2str(I_V_max_error*1e12, '%.3f'), ' pA']);
disp(['Non-Linearity (% FSO):          ', num2str(Linearity_V_percent, '%.6f'), ' %']);
disp(['R-squared (R²):                 ', num2str(R_squared_V, '%.10f')]);

% -------------------------------------------------------------------------
% E2: MEASURAND LINEARITY (R_soil vs I_out)
% -------------------------------------------------------------------------
disp(' ');
disp('--- MEASURAND LINEARITY (R_soil vs I_out) ---');

% Use the existing R_sweep and I_sweep data (already calculated)
% Best-fit straight line for nonlinear relationship
p_R = polyfit(R_sweep, I_sweep, 1); % Linear fit to nonlinear data
I_R_fit = polyval(p_R, R_sweep);

% Calculate linearity metrics
I_R_error = I_sweep - I_R_fit; % Deviation from best-fit line
I_R_max_error = max(abs(I_R_error));
I_R_FSO = max(I_sweep) - min(I_sweep); % Full-Scale Output
Linearity_R_percent = (I_R_max_error / I_R_FSO) * 100;

% R-squared
SS_res_R = sum(I_R_error.^2);
SS_tot_R = sum((I_sweep - mean(I_sweep)).^2);
R_squared_R = 1 - (SS_res_R / SS_tot_R);

% Find point of maximum deviation
[~, idx_max_dev] = max(abs(I_R_error));
R_max_dev = R_sweep(idx_max_dev);
I_max_dev_actual = I_sweep(idx_max_dev);
I_max_dev_fit = I_R_fit(idx_max_dev);

disp(['Resistance Range:               ', num2str(min(R_sweep)), ' to ', num2str(max(R_sweep)/1000), ' kΩ']);
disp(['Current Range:                  ', num2str(min(I_sweep)*1e6, '%.3f'), ' to ', num2str(max(I_sweep)*1e6, '%.3f'), ' μA']);
disp(['Best-Fit Slope:                 ', num2str(p_R(1)*1e6, '%.6e'), ' μA/Ω']);
disp(['Best-Fit Intercept:             ', num2str(p_R(2)*1e6, '%.3f'), ' μA']);
disp(['Maximum Linearity Error:        ', num2str(I_R_max_error*1e6, '%.3f'), ' μA']);
disp(['Non-Linearity (% FSO):          ', num2str(Linearity_R_percent, '%.3f'), ' %']);
disp(['R-squared (R²):                 ', num2str(R_squared_R, '%.6f')]);
disp(['Max Deviation at R_soil:        ', num2str(R_max_dev/1000, '%.3f'), ' kΩ']);

% -------------------------------------------------------------------------
% E3: POLYNOMIAL FITTING FOR IMPROVED MEASURAND LINEARITY
% -------------------------------------------------------------------------
disp(' ');
disp('--- POLYNOMIAL COMPENSATION (2nd Order) ---');

% Second-order polynomial fit (quadratic)
p_R_quad = polyfit(R_sweep, I_sweep, 2);
I_R_quad_fit = polyval(p_R_quad, R_sweep);

% Calculate improved linearity metrics
I_R_quad_error = I_sweep - I_R_quad_fit;
I_R_quad_max_error = max(abs(I_R_quad_error));
Linearity_R_quad_percent = (I_R_quad_max_error / I_R_FSO) * 100;

% R-squared for quadratic fit
SS_res_R_quad = sum(I_R_quad_error.^2);
R_squared_R_quad = 1 - (SS_res_R_quad / SS_tot_R);

disp(['Quadratic Coefficients:         [', num2str(p_R_quad(1)*1e6, '%.3e'), ', ', ...
      num2str(p_R_quad(2)*1e6, '%.3e'), ', ', num2str(p_R_quad(3)*1e6, '%.3f'), '] μA']);
disp(['Max Error (Quadratic Fit):      ', num2str(I_R_quad_max_error*1e9, '%.3f'), ' nA']);
disp(['Non-Linearity (% FSO):          ', num2str(Linearity_R_quad_percent, '%.6f'), ' %']);
disp(['R-squared (R²):                 ', num2str(R_squared_R_quad, '%.10f')]);
disp(['Improvement over Linear:        ', num2str((Linearity_R_percent - Linearity_R_quad_percent), '%.3f'), ' % FSO']);

% Save linearity data
linearity_V_data = [V_sweep', I_V_sweep', I_V_fit', I_V_error'];
linearity_R_data = [R_sweep', I_sweep', I_R_fit', I_R_error', I_R_quad_fit', I_R_quad_error'];
writematrix(linearity_V_data, 'results/data/linearity_input_data.csv');
writematrix(linearity_R_data, 'results/data/linearity_measurand_data.csv');
disp(' ');
disp('Linearity data saved to linearity_input_data.csv and linearity_measurand_data.csv.');

disp(' ');
disp('===========================================================');
disp('LINEARITY ANALYSIS COMPLETE');
disp('===========================================================');

% =========================================================================
% PART F: VISUALIZATION
% =========================================================================

% Figure 1: Output Current and Sensitivity vs. R_soil
figure(1);
subplot(2,1,1);
loglog(R_sweep, I_sweep * 1e6, 'LineWidth', 2);
hold on;
plot(R_operating, I_mag_op * 1e6, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
title('Output Current vs. Soil Resistance');
xlabel('Soil Resistance R_{soil} (Ω)');
ylabel('Peak Output Current (μA)');
grid on;
legend('I_{out}(R_{soil})', 'Operating Point', 'Location', 'best');

subplot(2,1,2);
semilogx(R_sweep, Sensitivity_sweep * 1e6, 'LineWidth', 2);
hold on;
plot(R_operating, dI_dR_analytical * 1e6, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
title('Measurand Sensitivity vs. Soil Resistance');
xlabel('Soil Resistance R_{soil} (Ω)');
ylabel('Sensitivity dI/dR (μA/Ω)');
grid on;
legend('\partialI/\partialR_{soil}', 'Operating Point', 'Location', 'best');

% Figure 2: Summary Bar Chart of Relative Sensitivities
figure(2);
relative_sens = [abs(S_R), S_V, abs(S_L), abs(S_C), abs(S_f)];
sens_labels = {'S_R (Measurand)', 'S_V (Input)', 'S_L (Inductance)', 'S_C (Capacitance)', 'S_f (Frequency)'};
bar(relative_sens);
set(gca, 'XTickLabel', sens_labels);
title('Relative Sensitivities (Normalized)');
ylabel('Relative Sensitivity |S_i|');
grid on;
xtickangle(45);

% Figure 3: Input Voltage Linearity
figure(3);
subplot(2,1,1);
plot(V_sweep, I_V_sweep * 1e6, 'b-', 'LineWidth', 2);
hold on;
plot(V_sweep, I_V_fit * 1e6, 'r--', 'LineWidth', 1.5);
plot(V_peak, I_mag_op * 1e6, 'go', 'MarkerSize', 10, 'LineWidth', 2);
title(['Input Voltage Linearity (R² = ', num2str(R_squared_V, '%.10f'), ')']);
xlabel('Input Voltage V_{in} (V)');
ylabel('Output Current I_{out} (μA)');
grid on;
legend('Actual Response', 'Best-Fit Line', 'Operating Point', 'Location', 'northwest');

subplot(2,1,2);
plot(V_sweep, I_V_error * 1e12, 'b-', 'LineWidth', 2);
hold on;
yline(0, 'k--', 'LineWidth', 1);
yline(I_V_max_error * 1e12, 'r--', 'LineWidth', 1);
yline(-I_V_max_error * 1e12, 'r--', 'LineWidth', 1);
title(['Linearity Error (Max = ', num2str(I_V_max_error*1e12, '%.3f'), ' pA, Non-Linearity = ', num2str(Linearity_V_percent, '%.6f'), '% FSO)']);
xlabel('Input Voltage V_{in} (V)');
ylabel('Error (pA)');
grid on;
legend('Linearity Error', 'Zero Line', 'Max Error', 'Location', 'best');

% Figure 4: Measurand Linearity with Polynomial Compensation
figure(4);
subplot(2,2,1);
loglog(R_sweep, I_sweep * 1e6, 'b-', 'LineWidth', 2);
hold on;
plot(R_sweep, I_R_fit * 1e6, 'r--', 'LineWidth', 1.5);
plot(R_operating, I_mag_op * 1e6, 'go', 'MarkerSize', 10, 'LineWidth', 2);
plot(R_max_dev, I_max_dev_actual * 1e6, 'mo', 'MarkerSize', 8, 'LineWidth', 2);
title(['Measurand Linearity - Linear Fit (R² = ', num2str(R_squared_R, '%.6f'), ')']);
xlabel('Soil Resistance R_{soil} (Ω)');
ylabel('Output Current I_{out} (μA)');
grid on;
legend('Actual Response', 'Linear Fit', 'Operating Point', 'Max Deviation', 'Location', 'best');

subplot(2,2,2);
semilogx(R_sweep, I_R_error * 1e6, 'b-', 'LineWidth', 2);
hold on;
yline(0, 'k--', 'LineWidth', 1);
yline(I_R_max_error * 1e6, 'r--', 'LineWidth', 1);
yline(-I_R_max_error * 1e6, 'r--', 'LineWidth', 1);
plot(R_max_dev, (I_max_dev_actual - I_max_dev_fit) * 1e6, 'mo', 'MarkerSize', 10, 'LineWidth', 2);
title(['Linear Fit Error (Non-Linearity = ', num2str(Linearity_R_percent, '%.3f'), '% FSO)']);
xlabel('Soil Resistance R_{soil} (Ω)');
ylabel('Error (μA)');
grid on;
legend('Linearity Error', 'Zero Line', 'Max Error', 'Location', 'best');

subplot(2,2,3);
loglog(R_sweep, I_sweep * 1e6, 'b-', 'LineWidth', 2);
hold on;
plot(R_sweep, I_R_quad_fit * 1e6, 'g--', 'LineWidth', 1.5);
plot(R_operating, I_mag_op * 1e6, 'go', 'MarkerSize', 10, 'LineWidth', 2);
title(['Measurand Linearity - Quadratic Fit (R² = ', num2str(R_squared_R_quad, '%.10f'), ')']);
xlabel('Soil Resistance R_{soil} (Ω)');
ylabel('Output Current I_{out} (μA)');
grid on;
legend('Actual Response', 'Quadratic Fit', 'Operating Point', 'Location', 'best');

subplot(2,2,4);
semilogx(R_sweep, I_R_quad_error * 1e9, 'b-', 'LineWidth', 2);
hold on;
yline(0, 'k--', 'LineWidth', 1);
yline(I_R_quad_max_error * 1e9, 'r--', 'LineWidth', 1);
yline(-I_R_quad_max_error * 1e9, 'r--', 'LineWidth', 1);
title(['Quadratic Fit Error (Non-Linearity = ', num2str(Linearity_R_quad_percent, '%.6f'), '% FSO)']);
xlabel('Soil Resistance R_{soil} (Ω)');
ylabel('Error (nA)');
grid on;
legend('Linearity Error', 'Zero Line', 'Max Error', 'Location', 'best');

disp(' ');
disp('===========================================================');
disp('SENSITIVITY AND LINEARITY ANALYSIS COMPLETE');
disp('===========================================================');
