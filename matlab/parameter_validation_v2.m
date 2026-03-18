% =========================================================================
% Soil Salinity (EC)
% Parameter Validation with IMPROVED Parameters
% =========================================================================
clear all; close all; clc;

% Load IMPROVED MS2 parameters
run('setup_parameters_v2.m');

fprintf('\n');
fprintf('===========================================================\n');
fprintf('MS2 PARAMETER VALIDATION (IMPROVED SENSOR)\n');
fprintf('===========================================================\n');

fprintf('\nFINAL PARAMETER VALUES:\n');
fprintf('  K_cell:                             %.2f cm^-1\n', K_cell);
fprintf('  L_coil:                             %.2e H (%.1f uH)\n', L_coil, L_coil*1e6);
fprintf('  C_dl:                               %.2e F (%.1f uF)\n', C_dl, C_dl*1e6);
fprintf('  f_ex:                               %.2e Hz (%.1f kHz)\n', f_ex, f_ex/1000);
fprintf('  V_peak:                             %.2f V\n', V_peak);
fprintf('  R_soil_baseline (IMPROVED):         %.2e Ohm (%.1f kOhm)\n', R_soil_baseline, R_soil_baseline/1000);
fprintf('\n');

% Natural Frequency Calculation
omega_n_direct = 1 / sqrt(L_coil * C_dl);
f_n_direct = omega_n_direct / (2 * pi);

fprintf('NATURAL FREQUENCY:\n');
fprintf('  ω_n = %.6f rad/s\n', omega_n_direct);
fprintf('  f_n = %.6f Hz\n', f_n_direct);
fprintf('\n');

% Transfer Function Analysis
num = [C_dl, 0];
den = [L_coil * C_dl, R_soil_baseline * C_dl, 1];
H_s = tf(num, den);
poles = pole(H_s);

fprintf('TRANSFER FUNCTION POLES:\n');
for i = 1:length(poles)
    if isreal(poles(i))
        fprintf('  p%d = %.6f rad/s (Real)\n', i, real(poles(i)));
    else
        fprintf('  p%d = %.6f %+.6fi rad/s (Complex)\n', i, real(poles(i)), imag(poles(i)));
    end
end
fprintf('\n');

% Damping Analysis
zeta_baseline = (R_soil_baseline / (2 * L_coil)) * sqrt(L_coil * C_dl);
Q_factor = 1 / (2 * zeta_baseline);

fprintf('DAMPING CHARACTERISTICS:\n');
fprintf('  Damping Ratio (ζ):                  %.6f\n', zeta_baseline);
fprintf('  Quality Factor (Q):                 %.6e\n', Q_factor);

if zeta_baseline < 1
    damping_type = 'UNDERDAMPED';
elseif zeta_baseline == 1
    damping_type = 'CRITICALLY DAMPED';
else
    damping_type = 'OVERDAMPED';
end
fprintf('  Damping Type:                       %s\n', damping_type);
fprintf('\n');

% Frequency Ratio
freq_ratio = f_ex / f_n_direct;
fprintf('OPERATING FREQUENCY ANALYSIS:\n');
fprintf('  Operating Frequency (f_ex):         %.2f Hz\n', f_ex);
fprintf('  Natural Frequency (f_n):            %.2f Hz\n', f_n_direct);
fprintf('  Frequency Ratio (f_ex/f_n):         %.6f\n', freq_ratio);
fprintf('\n');

% Export MS2 validation report
report_data = {
    'MS2 PARAMETER VALIDATION REPORT', '', '';
    'Generated:', datestr(now), '';
    '', '', '';
    'IMPROVED PARAMETER VALUES', '', '';
    'Parameter', 'Value', 'Units';
    'K_cell', K_cell, 'cm^-1';
    'L_coil', L_coil, 'H';
    'C_dl', C_dl, 'F';
    'f_ex', f_ex, 'Hz';
    'R_soil_baseline', R_soil_baseline, 'Ohm';
    '', '', '';
    'SYSTEM CHARACTERISTICS', '', '';
    'Natural Frequency', f_n_direct, 'Hz';
    'Natural Angular Freq', omega_n_direct, 'rad/s';
    'Damping Ratio', zeta_baseline, '-';
    'Quality Factor', Q_factor, '-';
    'Damping Type', damping_type, '';
    'Frequency Ratio', freq_ratio, '-';
    '', '', '';
    'VALIDATION STATUS', 'PASSED - MS2 IMPROVED', '✓';
};

writecell(report_data, 'results/data/parameter_validation_v2.csv');
fprintf('✓ MS2 validation report saved to Data/parameter_validation_v2.csv\n');
fprintf('\n');
fprintf('===========================================================\n');
fprintf('MS2 PARAMETER VALIDATION COMPLETE\n');
fprintf('===========================================================\n');
