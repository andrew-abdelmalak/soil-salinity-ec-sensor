function[I_meas, n_t, b_t] =
    add_noise_and_drift(I_true, t_vec, SNR_dB, drift_amp, drift_freq) % Add noise and drift to ideal sensor output

          P_signal = mean(I_true.^ 2);
SNR_linear = 10 ^ (SNR_dB / 10);
P_noise = P_signal / SNR_linear;
noise_std = sqrt(P_noise);
n_t = noise_std * randn(size(I_true));

I_mean = mean(abs(I_true));
drift_amplitude = drift_amp * I_mean;
b_t = drift_amplitude * sin(2 * pi * drift_freq * t_vec);

I_meas = I_true + b_t + n_t;

actual_SNR = 10 * log10(P_signal / var(n_t));
drift_percentage = (max(abs(b_t)) / I_mean) * 100;

fprintf('  Added noise: SNR = %.1f dB (target: %.1f dB)\n', actual_SNR, SNR_dB);
fprintf('  Added drift: %.1f%% amplitude, f = %.3f Hz\n', drift_percentage,
        drift_freq);
fprintf('  Noise std: %.3f microA, Drift peak: %.3f microA\n', std(n_t) * 1e6,
        max(abs(b_t)) * 1e6);

end
