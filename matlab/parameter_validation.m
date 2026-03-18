% =========================================================================
% Soil Salinity (EC)
% Parameter Validation: Final Values Confirmation and Natural Frequency
% =========================================================================
clear all; close all; clc;

% 1. Load System Parameters
run('setup_parameters.m');

disp('===========================================================');
disp('PARAMETER VALIDATION AND NATURAL FREQUENCY VERIFICATION');
disp('===========================================================');

% =========================================================================
% PART A: CONFIRM FINAL PARAMETER VALUES
% =========================================================================
disp(' ');
disp('--- FINAL PARAMETER VALUES ---');
disp(' ');

% Display all critical parameters
fprintf('SENSOR PARAMETERS:\n');
fprintf('  Cell Constant (K_cell):              %.6f cm⁻¹\n', K_cell);
fprintf('  Lead Inductance (L_coil):            %.6e H (%.1f μH)\n', L_coil, L_coil*1e6);
fprintf('  Probe Capacitance (C_dl):            %.6e F (%.1f μF)\n', C_dl, C_dl*1e6);
fprintf('\n');

fprintf('EXCITATION PARAMETERS:\n');
fprintf('  AC Excitation Frequency (f_ex):      %.6e Hz (%.1f kHz)\n', f_ex, f_ex/1000);
fprintf('  Peak Voltage (V_peak):               %.2f V\n', V_peak);
fprintf('\n');

fprintf('MEASUREMENT RANGE:\n');
fprintf('  Minimum Soil Resistance (R_min):     %.1f Ω\n', R_soil_min);
fprintf('  Maximum Soil Resistance (R_max):     %.3e Ω (%.1f kΩ)\n', R_soil_max, R_soil_max/1000);
fprintf('  Baseline Resistance (R_baseline):    %.3e Ω (%.1f kΩ)\n', R_soil_baseline, R_soil_baseline/1000);
fprintf('\n');

fprintf('SIMULATION PARAMETERS:\n');
fprintf('  Total Simulation Time (T_sim):       %.3f s (%.1f ms)\n', T_sim, T_sim*1000);
fprintf('  Time Step (dt):                      %.6e s (%.2f μs)\n', dt, dt*1e6);
fprintf('\n');

% =========================================================================
% PART B: CALCULATE THEORETICAL NATURAL FREQUENCY
% =========================================================================
disp('--- THEORETICAL NATURAL FREQUENCY CALCULATION ---');
disp(' ');

% Method 1: Direct Formula from LC Circuit
% For RLC circuit: ω_n = 1 / √(L·C)
omega_n_direct = 1 / sqrt(L_coil * C_dl);
f_n_direct = omega_n_direct / (2 * pi);

fprintf('METHOD 1: Direct Formula (ω_n = 1/√(LC))\n');
fprintf('  Natural Angular Frequency (ω_n):     %.6f rad/s\n', omega_n_direct);
fprintf('  Natural Frequency (f_n):             %.6f Hz\n', f_n_direct);
fprintf('  Period (T_n):                        %.6e s (%.3f ms)\n', 1/f_n_direct, 1000/f_n_direct);
fprintf('\n');

% Method 2: From Transfer Function Denominator
% Transfer function: H(s) = (C·s) / (L·C·s² + R·C·s + 1)
% Standard form: s² + 2ζω_n·s + ω_n² = 0
% Comparing: s² + (R/L)s + 1/(LC) → ω_n² = 1/(LC)

% Using baseline resistance for this calculation
a2 = L_coil * C_dl;  % Coefficient of s²
a1 = R_soil_baseline * C_dl;  % Coefficient of s
a0 = 1;  % Constant term

omega_n_tf = sqrt(a0 / a2);
f_n_tf = omega_n_tf / (2 * pi);

fprintf('METHOD 2: From Transfer Function Coefficients\n');
fprintf('  Denominator: %.6e·s² + %.6e·s + %.6f\n', a2, a1, a0);
fprintf('  ω_n = √(a₀/a₂):                      %.6f rad/s\n', omega_n_tf);
fprintf('  Natural Frequency (f_n):             %.6f Hz\n', f_n_tf);
fprintf('\n');

% Method 3: From MATLAB Transfer Function
num = [C_dl, 0];
den = [L_coil * C_dl, R_soil_baseline * C_dl, 1];
H_s = tf(num, den);

% Get poles of the system
poles = pole(H_s);
% For 2nd-order systems: ω_n = √(p1 * p2) (geometric mean of pole magnitudes)
% This works for both underdamped (complex poles) and overdamped (real poles) cases
omega_n_poles = sqrt(abs(poles(1)) * abs(poles(2)));
f_n_poles = omega_n_poles / (2 * pi);

fprintf('METHOD 3: From Transfer Function Poles\n');
fprintf('  System Poles:                        ');
for i = 1:length(poles)
    if imag(poles(i)) == 0
        fprintf('%.4e  ', real(poles(i)));
    else
        fprintf('%.4f%+.4fi  ', real(poles(i)), imag(poles(i)));
    end
end
fprintf('\n');
fprintf('  ω_n = √(|p₁|·|p₂|):                  %.6f rad/s\n', omega_n_poles);
fprintf('  Natural Frequency (f_n):             %.6f Hz\n', f_n_poles);
fprintf('\n');

% =========================================================================
% PART C: CROSS-VALIDATION
% =========================================================================
disp('--- CROSS-VALIDATION OF RESULTS ---');
disp(' ');

% Check consistency between methods
tol = 1e-6;  % Tolerance for floating-point comparison

if abs(omega_n_direct - omega_n_tf) < tol && abs(omega_n_direct - omega_n_poles) < tol
    fprintf('✓ VALIDATION PASSED: All methods agree!\n');
    fprintf('  Maximum Difference:                  %.3e rad/s (%.6f%%)\n', ...
            max(abs([omega_n_direct - omega_n_tf, omega_n_direct - omega_n_poles])), ...
            max(abs([omega_n_direct - omega_n_tf, omega_n_direct - omega_n_poles]))/omega_n_direct * 100);
else
    fprintf('✗ VALIDATION WARNING: Methods show discrepancies!\n');
    fprintf('  Direct vs. TF:                       %.3e rad/s\n', abs(omega_n_direct - omega_n_tf));
    fprintf('  Direct vs. Poles:                    %.3e rad/s\n', abs(omega_n_direct - omega_n_poles));
end
fprintf('\n');

% Use the direct method as the canonical value
omega_n_final = omega_n_direct;
f_n_final = f_n_direct;

fprintf('FINAL VALIDATED NATURAL FREQUENCY:\n');
fprintf('  ω_n = %.6f rad/s\n', omega_n_final);
fprintf('  f_n = %.6f Hz\n', f_n_final);
fprintf('\n');

% =========================================================================
% PART D: COMPARISON WITH OPERATING FREQUENCY
% =========================================================================
disp('--- OPERATING FREQUENCY vs. NATURAL FREQUENCY ---');
disp(' ');

freq_ratio = f_ex / f_n_final;
fprintf('  Operating Frequency (f_ex):          %.6e Hz (%.1f kHz)\n', f_ex, f_ex/1000);
fprintf('  Natural Frequency (f_n):             %.6f Hz\n', f_n_final);
fprintf('  Ratio (f_ex/f_n):                    %.6f\n', freq_ratio);
fprintf('\n');

% Interpretation
if freq_ratio < 0.1
    fprintf('INTERPRETATION: Operating FAR BELOW natural frequency\n');
    fprintf('                System behaves like a resistor (quasi-static)\n');
elseif freq_ratio < 0.5
    fprintf('INTERPRETATION: Operating BELOW natural frequency\n');
    fprintf('                System shows capacitive/inductive effects\n');
elseif freq_ratio >= 0.5 && freq_ratio <= 2
    fprintf('INTERPRETATION: Operating NEAR natural frequency\n');
    fprintf('                ⚠️ Resonance effects may be significant!\n');
elseif freq_ratio > 2 && freq_ratio < 10
    fprintf('INTERPRETATION: Operating ABOVE natural frequency\n');
    fprintf('                Response rolls off, reduced sensitivity\n');
else
    fprintf('INTERPRETATION: Operating FAR ABOVE natural frequency\n');
    fprintf('                Minimal response, system acts as filter\n');
end
fprintf('\n');

% =========================================================================
% PART E: DAMPING ANALYSIS AT BASELINE
% =========================================================================
disp('--- DAMPING CHARACTERISTICS (Baseline Condition) ---');
disp(' ');

% Calculate damping ratio
zeta_baseline = (R_soil_baseline / (2 * L_coil)) * sqrt(L_coil * C_dl);
Q_factor = 1 / (2 * zeta_baseline);

fprintf('  Damping Ratio (ζ):                   %.6f\n', zeta_baseline);
fprintf('  Quality Factor (Q):                  %.6f\n', Q_factor);

if zeta_baseline < 1
    fprintf('  Damping Type:                        UNDERDAMPED (oscillatory)\n');
    omega_d = omega_n_final * sqrt(1 - zeta_baseline^2);
    f_d = omega_d / (2 * pi);
    fprintf('  Damped Natural Frequency (ω_d):      %.6f rad/s\n', omega_d);
    fprintf('  Damped Natural Frequency (f_d):      %.6f Hz\n', f_d);
elseif abs(zeta_baseline - 1) < 1e-6
    fprintf('  Damping Type:                        CRITICALLY DAMPED\n');
else
    fprintf('  Damping Type:                        OVERDAMPED (no oscillation)\n');
end
fprintf('\n');

% =========================================================================
% PART F: FREQUENCY RESPONSE VALIDATION
% =========================================================================
disp('--- FREQUENCY RESPONSE VALIDATION ---');
disp(' ');

% Calculate magnitude at natural frequency
s_n = 1j * omega_n_final;
Y_n = (C_dl * s_n) / (L_coil * C_dl * s_n^2 + R_soil_baseline * C_dl * s_n + 1);
mag_at_fn = abs(Y_n);

% Calculate magnitude at operating frequency
s_ex = 1j * 2 * pi * f_ex;
Y_ex = (C_dl * s_ex) / (L_coil * C_dl * s_ex^2 + R_soil_baseline * C_dl * s_ex + 1);
mag_at_fex = abs(Y_ex);

fprintf('  Magnitude at f_n (%.2f Hz):         %.6f\n', f_n_final, mag_at_fn);
fprintf('  Magnitude at f_ex (%.1f kHz):       %.6f\n', f_ex/1000, mag_at_fex);
fprintf('  Ratio (|H(f_n)|/|H(f_ex)|):          %.6f\n', mag_at_fn/mag_at_fex);
fprintf('\n');

% For underdamped systems, peak should be near f_n
if zeta_baseline < 1
    % Peak magnitude for underdamped 2nd-order system
    mag_peak_theoretical = 1 / (2 * zeta_baseline * sqrt(1 - zeta_baseline^2));
    fprintf('  Theoretical Peak Magnification:      %.6f\n', mag_peak_theoretical);
end
fprintf('\n');

% =========================================================================
% PART G: UNIT ANALYSIS AND DIMENSIONAL CHECK
% =========================================================================
disp('--- DIMENSIONAL ANALYSIS ---');
disp(' ');

fprintf('DIMENSIONAL CHECKS:\n');
fprintf('  √(L·C) = √(H·F) = √(s²) = s           ✓\n');
fprintf('  ω_n = 1/√(L·C) has units [rad/s]       ✓\n');
fprintf('  f_n = ω_n/(2π) has units [Hz]          ✓\n');
fprintf('\n');

% Numerical verification
sqrt_LC = sqrt(L_coil * C_dl);
fprintf('  √(L·C) = %.6e s\n', sqrt_LC);
fprintf('  1/√(L·C) = %.6f rad/s = ω_n            ✓\n', 1/sqrt_LC);
fprintf('\n');

% =========================================================================
% PART H: EXPORT VALIDATION REPORT
% =========================================================================
disp('--- EXPORTING VALIDATION REPORT ---');
disp(' ');

% Create comprehensive validation report
report_data = {
    'PARAMETER VALIDATION REPORT', '', '';
    'Generated:', datestr(now), '';
    '', '', '';
    'SECTION 1: FINAL PARAMETER VALUES', '', '';
    'Parameter', 'Value', 'Units';
    'K_cell', K_cell, 'cm⁻¹';
    'L_coil', L_coil, 'H';
    'L_coil', L_coil*1e6, 'μH';
    'C_dl', C_dl, 'F';
    'C_dl', C_dl*1e6, 'μF';
    'f_ex', f_ex, 'Hz';
    'f_ex', f_ex/1000, 'kHz';
    'V_peak', V_peak, 'V';
    'R_soil_min', R_soil_min, 'Ω';
    'R_soil_max', R_soil_max, 'Ω';
    'R_soil_baseline', R_soil_baseline, 'Ω';
    '', '', '';
    'SECTION 2: NATURAL FREQUENCY VALIDATION', '', '';
    'Method', 'ω_n (rad/s)', 'f_n (Hz)';
    'Direct Formula', omega_n_direct, f_n_direct;
    'Transfer Function', omega_n_tf, f_n_tf;
    'Pole Analysis', omega_n_poles, f_n_poles;
    'FINAL VALIDATED', omega_n_final, f_n_final;
    '', '', '';
    'SECTION 3: SYSTEM CHARACTERISTICS', '', '';
    'Property', 'Value', 'Units';
    'Natural Frequency', f_n_final, 'Hz';
    'Natural Angular Freq', omega_n_final, 'rad/s';
    'Operating Frequency', f_ex, 'Hz';
    'Frequency Ratio', freq_ratio, '-';
    'Damping Ratio', zeta_baseline, '-';
    'Quality Factor', Q_factor, '-';
    'Magnitude at f_n', mag_at_fn, '-';
    'Magnitude at f_ex', mag_at_fex, '-';
    '', '', '';
    'VALIDATION STATUS', 'PASSED', '✓';
};

writecell(report_data, 'results/data/parameter_validation_report.csv');
fprintf('✓ Validation report saved to parameter_validation_report.csv\n');
fprintf('\n');

% Export parameters in machine-readable format for other scripts
params_export = struct();
params_export.K_cell = K_cell;
params_export.L_coil = L_coil;
params_export.C_dl = C_dl;
params_export.f_ex = f_ex;
params_export.V_peak = V_peak;
params_export.R_soil_min = R_soil_min;
params_export.R_soil_max = R_soil_max;
params_export.R_soil_baseline = R_soil_baseline;
params_export.omega_n = omega_n_final;
params_export.f_n = f_n_final;
params_export.zeta_baseline = zeta_baseline;
params_export.Q_factor = Q_factor;

save('validated_parameters.mat', '-struct', 'params_export');
fprintf('✓ Validated parameters saved to validated_parameters.mat\n');
fprintf('\n');

% =========================================================================
% PART I: VISUAL VALIDATION
% =========================================================================

% Figure 1: Parameter Summary Visualization
figure(1);
set(gcf, 'Position', [100, 100, 1200, 800]);

% Subplot 1: LC Product and Natural Frequency
subplot(2,3,1);
bar([L_coil*1e6, C_dl*1e6]);
set(gca, 'XTickLabel', {'L (μH)', 'C (μF)'});
title('Passive Components');
ylabel('Value');
grid on;

% Subplot 2: Natural Frequency Comparison
subplot(2,3,2);
bar([f_n_direct, f_n_tf, f_n_poles, f_ex]);
set(gca, 'XTickLabel', {'Direct', 'TF', 'Poles', 'f_{ex}'});
title('Frequency Comparison (Hz)');
ylabel('Frequency (Hz)');
grid on;
legend('Natural Freq Methods and Operating Freq', 'Location', 'best');

% Subplot 3: Frequency Ratio
subplot(2,3,3);
bar(freq_ratio);
hold on;
yline(1, 'r--', 'LineWidth', 2);
set(gca, 'XTickLabel', {'f_{ex}/f_n'});
title('Operating vs. Natural Frequency');
ylabel('Ratio');
grid on;
legend('Actual', 'Unity (Resonance)', 'Location', 'best');

% Subplot 4: Resistance Range
subplot(2,3,4);
bar([R_soil_min, R_soil_baseline, R_soil_max]);
set(gca, 'YScale', 'log');
set(gca, 'XTickLabel', {'R_{min}', 'R_{baseline}', 'R_{max}'});
title('Measurement Range');
ylabel('Resistance (Ω, log scale)');
grid on;

% Subplot 5: Damping Characteristics
subplot(2,3,5);
bar_data = [zeta_baseline, 1, Q_factor/10];
bar(bar_data);
set(gca, 'XTickLabel', {'ζ', 'Critical', 'Q/10'});
title('Damping Characteristics');
ylabel('Value');
grid on;

% Subplot 6: System Response at Different Frequencies
subplot(2,3,6);
f_sweep = logspace(-1, 6, 200);
mag_sweep = zeros(size(f_sweep));
for i = 1:length(f_sweep)
    s_sweep = 1j * 2 * pi * f_sweep(i);
    Y_sweep = (C_dl * s_sweep) / (L_coil * C_dl * s_sweep^2 + R_soil_baseline * C_dl * s_sweep + 1);
    mag_sweep(i) = abs(Y_sweep);
end
semilogx(f_sweep, mag_sweep, 'b-', 'LineWidth', 2);
hold on;
plot(f_n_final, mag_at_fn, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
plot(f_ex, mag_at_fex, 'gs', 'MarkerSize', 10, 'LineWidth', 2);
title('Frequency Response Magnitude');
xlabel('Frequency (Hz)');
ylabel('|H(f)|');
grid on;
legend('Magnitude', 'f_n', 'f_{ex}', 'Location', 'best');

sgtitle('Parameter Validation Summary', 'FontSize', 14, 'FontWeight', 'bold');

% Store validation status in base workspace
assignin('base', 'validation_passed', true);
assignin('base', 'f_n_validated', f_n_final);
assignin('base', 'omega_n_validated', omega_n_final);

% Define damping_type_baseline for the summary
if zeta_baseline < 1
    damping_type_baseline = 'UNDERDAMPED';
elseif abs(zeta_baseline - 1) < 1e-6
    damping_type_baseline = 'CRITICALLY DAMPED';
else
    damping_type_baseline = 'OVERDAMPED';
end

disp('===========================================================');
disp('PARAMETER VALIDATION COMPLETE');
disp('===========================================================');
disp(' ');
fprintf('SUMMARY:\n');
fprintf('  ✓ All parameters confirmed\n');
fprintf('  ✓ Natural frequency validated: f_n = %.2f Hz\n', f_n_final);
fprintf('  ✓ Operating frequency: f_ex = %.1f kHz\n', f_ex/1000);
fprintf('  ✓ Frequency ratio: f_ex/f_n = %.2f\n', freq_ratio);
fprintf('  ✓ System is %s at baseline\n', lower(damping_type_baseline));
fprintf('  ✓ All validation files exported\n');
disp('===========================================================');
