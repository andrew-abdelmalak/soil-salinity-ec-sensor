% =========================================================================
% Soil Salinity (EC)
% ODE Function (Charge-based, Second Order)
% =========================================================================
function dydt = ode_function(t, y, L_coil, C_dl, R_soil_baseline, V_peak, f_ex)

% y(1) = q (Charge, C)
% y(2) = q_dot = I (Current, A)
q = y(1);
I = y(2);

% Input Voltage (AC Excitation)
V_in_t = V_peak * sin(2*pi*f_ex * t);

% Calculate the charge acceleration (q_double_dot) from the EOM:
% L*q_double_dot + R_soil*q_dot + (1/C_dl)*q = V_in(t)
% q_double_dot = (V_in(t) - R_soil*q_dot - (1/C_dl)*q) / L

q_double_dot = (V_in_t - R_soil_baseline * I - (1/C_dl) * q) / L_coil;

% State-space form: [q_dot; q_double_dot]
dydt = [I; q_double_dot];

end