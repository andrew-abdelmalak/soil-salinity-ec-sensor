% == == == == == == == == == == == == == == == == == == == == == == == == == ==
    == == == == == == == == == ==
    = % ELCT 903 - Sensor Technology -
          Project 13 : Soil Salinity(EC) % MAIN SCRIPT -
          Noise and Drift Compensation %
      == == == == == == == == == == == == == == == == == == == == == == == == ==
      == == == == == == == == == == ==
    = clear all;
close all;
clc;

fprintf('\n===========================================================\n');
fprintf('NOISE AND DRIFT COMPENSATION\n');
fprintf('===========================================================\n\n');

% % Configuration Parameters K_cell = 0.1;
L_coil = 3e-6;
C_dl = 20e-6;
f_ex = 1e3;
V_peak = 1;

T_total = 20;
fs = 1000;
dt = 1 / fs;
t_vec = 0 : dt : T_total;

R_soil_levels = [ 15e3, 50e3, 100e3, 30e3, 10e3 ];
EC_levels = K_cell./ R_soil_levels;
EC_times = [ 0, 4, 8, 12, 16 ];

SNR_dB = 30;
drift_amp = 0.08;
drift_freq = 0.05;

window_noise = round(0.5 * fs);
window_drift = round(5 * fs);

fprintf('Config: Duration=%.1f s, SNR=%.0f dB, Drift=%.1f%%\n\n', T_total,
        SNR_dB, drift_amp * 100);

% % Generate True Signals fprintf('STEP 1: Generating True EC Trajectory...\n');

params.K_cell = K_cell;
params.L_coil = L_coil;
params.C_dl = C_dl;
params.f_ex = f_ex;
params.V_peak = V_peak;
params.EC_levels = EC_levels;
params.EC_times = EC_times;

[ EC_true, R_soil_true, I_true ] = generate_signals(t_vec, params);

% Build calibration lookup table(R_soil to I_true) R_calib =
    logspace(log10(min(R_soil_true)), log10(max(R_soil_true)), 500);
I_calib = zeros(size(R_calib));
s = 1j * 2 * pi * f_ex;
for
  i = 1 : length(R_calib) Y_s =
              (C_dl * s) / (L_coil * C_dl * s ^ 2 + R_calib(i) * C_dl * s + 1);
I_calib(i) = abs(Y_s) * V_peak;
end EC_calib = K_cell./ R_calib;

fprintf('\n');

% % Add Noise and Drift fprintf('STEP 2: Adding Noise and Drift...\n');

[ I_meas, n_t, b_t ] =
    add_noise_and_drift(I_true, t_vec, SNR_dB, drift_amp, drift_freq);

% Convert current to EC using calibration curve(I is monotonic with R) %
    Use reverse lookup
    : I -> R->EC R_raw = interp1(I_calib, R_calib, I_meas, 'linear', 'extrap');
EC_raw = K_cell./ R_raw;

fprintf('\n');

% % Apply Compensation fprintf('STEP 3: Applying Compensation Filter...\n');

filter_params.window_noise = window_noise;
filter_params.window_drift = window_drift;
filter_params.K_cell = K_cell;

[ I_comp, EC_est_temp, I_filt, b_est ] =
    compensation_filter(I_meas, t_vec, filter_params);

% Convert compensated current to EC R_comp =
    interp1(I_calib, R_calib, I_comp, 'linear', 'extrap');
EC_est = K_cell./ R_comp;

fprintf('\n');

% % Error Analysis fprintf('STEP 4: Computing Error Metrics...\n\n');

[ metrics, summary_str ] = error_metrics(EC_true, EC_raw, EC_est, t_vec);
fprintf('\n');

% %
    Create Output Directories if ~exist('results/figures', 'dir')
        mkdir('results/figures');
end if ~exist('results/data', 'dir') mkdir('results/data');
end

    % % Visualization fprintf('STEP 5: Generating Plots...\n');

err_raw = EC_raw - EC_true;
err_comp = EC_est - EC_true;

figure(1);
plot(t_vec, EC_true, 'k-', 'LineWidth', 2);
hold on;
plot(t_vec, EC_raw, 'r-', 'LineWidth', 1);
plot(t_vec, EC_est, 'b-', 'LineWidth', 1.5);
hold off;
grid on;
xlabel('Time (s)');
ylabel('EC (S/m)');
title('EC Measurement Comparison');
legend('True EC', 'Raw EC (Noisy)', 'Compensated EC', 'Location', 'best');
saveas(gcf, 'results/figures/ec_time_comparison.png');

figure(2);
plot(t_vec, err_raw, 'r-', 'LineWidth', 1);
hold on;
plot(t_vec, err_comp, 'b-', 'LineWidth', 1.5);
plot(t_vec, zeros(size(t_vec)), 'k--');
hold off;
grid on;
xlabel('Time (s)');
ylabel('EC Error');
title('Error Analysis');
legend('Raw Error', 'Compensated Error', 'Location', 'best');
saveas(gcf, 'results/figures/error_vs_time.png');

figure(3);
plot(t_vec, I_true * 1000, 'k-', 'LineWidth', 2);
hold on;
plot(t_vec, I_meas * 1000, 'r-', 'LineWidth', 0.5);
plot(t_vec, I_comp * 1000, 'b-', 'LineWidth', 1.5);
hold off;
grid on;
xlabel('Time (s)');
ylabel('Output Current (mA)');
title('Current Signal Comparison');
legend('True Current', 'Measured (Noisy)', 'Compensated', 'Location', 'best');
saveas(gcf, 'results/figures/current_comparison.png');

fprintf('  Saved figures to results/figures/\n');

% % Data Export fprintf('STEP 6: Exporting Data...\n');

data_table = table(t_vec ', EC_true', R_soil_true ', I_true', I_meas ', I_comp',
                   EC_raw ', EC_est', err_raw ', err_comp');
data_table.Properties.VariableNames = {
    'Time_s',   'EC_true', 'R_soil_true_Ohm', 'I_true_A',  'I_meas_A',
    'I_comp_A', 'EC_raw',  'EC_est',          'Error_raw', 'Error_comp'};
writetable(data_table, 'results/data/compensation_signals.csv');

metrics_names = {'RMSE';
'RMSE_percent';
'Max_Error';
'Std_Dev';
'Mean_Error'
}
;
metrics_raw = [metrics.rmse_raw; metrics.rmse_raw_pct; metrics.max_err_raw;
               metrics.std_err_raw; metrics.mean_err_raw];
metrics_comp = [metrics.rmse_comp; metrics.rmse_comp_pct; metrics.max_err_comp;
                metrics.std_err_comp; metrics.mean_err_comp];
metrics_table = table(metrics_names, metrics_raw, metrics_comp);
metrics_table.Properties.VariableNames = {'Metric', 'Raw_Noisy', 'Compensated'};
writetable(metrics_table, 'results/data/compensation_metrics.csv');

save('results/data/compensation_workspace.mat', 'params', 'metrics', 't_vec', 'EC_true',
     'EC_raw', 'EC_est', 'I_true', 'I_meas', 'I_comp', 'SNR_dB', 'drift_amp',
     'drift_freq');

fprintf('  Exported data to ms3_data/\n\n');

% %
    Final Summary fprintf(
        '===========================================================\n');
fprintf('SIMULATION COMPLETE\n');
fprintf('===========================================================\n');
fprintf('RMSE Improvement:         %.2f%%\n', metrics.improvement_rmse_pct);
fprintf('Max Error Improvement:    %.2f%%\n', metrics.improvement_max_pct);
fprintf('Original RMSE:            %.6e\n', metrics.rmse_raw);
fprintf('Compensated RMSE:         %.6e\n', metrics.rmse_comp);
fprintf('===========================================================\n\n');

summary_file = fopen('results/data/compensation_summary.txt', 'w');
fprintf(summary_file, 'SUMMARY - NOISE AND DRIFT COMPENSATION\n\n');
fprintf(summary_file, 'Config: SNR=%.0f dB, Drift=%.1f%%, Duration=%.1f s\n\n',
        SNR_dB, drift_amp * 100, T_total);
fprintf(summary_file, '%s\n', summary_str);
fclose(summary_file);

fprintf(
    'All deliverables ready!\n===========================================================\n');
