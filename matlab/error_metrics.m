function[metrics, summary_str] =
    error_metrics(EC_true, EC_raw, EC_est, t_vec) % Compute error metrics and performance evaluation

          err_raw = EC_raw - EC_true;
err_comp = EC_est - EC_true;

rmse_raw = sqrt(mean(err_raw.^ 2));
rmse_comp = sqrt(mean(err_comp.^ 2));

max_err_raw = max(abs(err_raw));
max_err_comp = max(abs(err_comp));

std_err_raw = std(err_raw);
std_err_comp = std(err_comp);

mean_err_raw = mean(err_raw);
mean_err_comp = mean(err_comp);

improvement_rmse = ((rmse_raw - rmse_comp) / rmse_raw) * 100;
improvement_max = ((max_err_raw - max_err_comp) / max_err_raw) * 100;

metrics.rmse_raw = rmse_raw;
metrics.rmse_comp = rmse_comp;
metrics.max_err_raw = max_err_raw;
metrics.max_err_comp = max_err_comp;
metrics.std_err_raw = std_err_raw;
metrics.std_err_comp = std_err_comp;
metrics.mean_err_raw = mean_err_raw;
metrics.mean_err_comp = mean_err_comp;
metrics.improvement_rmse_pct = improvement_rmse;
metrics.improvement_max_pct = improvement_max;

EC_mean = mean(EC_true);
metrics.rmse_raw_pct = (rmse_raw / EC_mean) * 100;
metrics.rmse_comp_pct = (rmse_comp / EC_mean) * 100;

summary_str = sprintf(
    [
      ... '===========================================================\n',
      ... 'MS3 ERROR ANALYSIS - PERFORMANCE METRICS\n',
      ... '===========================================================\n',
      ... 'Metric                          Raw (Noisy)    Compensated\n',
      ... '-----------------------------------------------------------\n',
      ... 'RMSE                            %.6e     %.6e\n',
      ... 'RMSE (%% of mean EC)             %.2f%%          %.2f%%\n',
      ... 'Max Absolute Error              %.6e     %.6e\n',
      ... 'Std Dev of Error                %.6e     %.6e\n',
      ... 'Mean Error (Bias)               %.6e     %.6e\n',
      ... '-----------------------------------------------------------\n',
      ... 'IMPROVEMENT:\n', ... '  RMSE Reduction:               %.2f%%\n',
      ... '  Max Error Reduction:          %.2f%%\n',
      ... '===========================================================\n'
    ],
    ... rmse_raw, rmse_comp, ... metrics.rmse_raw_pct, metrics.rmse_comp_pct,
    ... max_err_raw, max_err_comp, ... std_err_raw, std_err_comp,
    ... mean_err_raw, mean_err_comp, ... improvement_rmse, improvement_max);

fprintf('%s', summary_str);

end
