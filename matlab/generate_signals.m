function[EC_true, R_soil_true, I_true] = generate_signals(t_vec, params) %
                                         MS3
    : Generate true EC trajectory and ideal sensor output

          K_cell = params.K_cell;
L_coil = params.L_coil;
C_dl = params.C_dl;
f_ex = params.f_ex;
V_peak = params.V_peak;
EC_levels = params.EC_levels;
EC_times = params.EC_times;

N = length(t_vec);
EC_true = zeros(1, N);

    for
      i = 1 : N t = t_vec(i);
    idx = find(t >= EC_times, 1, 'last');
    if isempty (idx)
      idx = 1;
    end EC_true(i) = EC_levels(idx);
    end

        R_soil_true = K_cell./ EC_true;

    I_true = zeros(1, N);
    s = 1j * 2 * pi * f_ex;

    for
      i = 1 : N R = R_soil_true(i);
    Y_s = (C_dl * s) / (L_coil * C_dl * s ^ 2 + R * C_dl * s + 1);
    I_true(i) = abs(Y_s) * V_peak;
    end

        fprintf('  Generated true EC trajectory with %d levels\n',
                length(EC_levels));
    fprintf('  R_soil range: %.1f Ohm to %.1f kOhm\n', min(R_soil_true),
            max(R_soil_true) / 1000);
    fprintf('  I_true range: %.3f to %.3f mA\n', min(I_true) * 1000,
            max(I_true) * 1000);

    end
