% =========================================================================
% Soil Salinity (EC)
% IMPROVED Simulation Parameters
% =========================================================================
%
% IMPROVEMENT STRATEGY:
% ---------------------
% Problem Identified (MS1): Extremely slow response time in fresh water
%   - R_soil_baseline = 150 kOhm (fresh water)
%   - Time constant τ = RC = 150k × 10μF = 1.5 seconds → TOO SLOW!
%
% Solution (MS2): Modify probe geometry to reduce cell constant K_cell
%   - Decrease electrode distance (d) by 5x
%   - Increase electrode area (A) by 2x
%   - Result: K_cell = d/A drops from 1.0 to 0.1 cm^-1
%
% Physical Impact:
%   - Resistance scales with K_cell → R drops by 10x
%   - Capacitance scales inversely with gap and directly with area → C doubles
%   - New time constant τ = 15k × 20μF = 0.3 seconds → 5x FASTER!
%
% =========================================================================

% --- COMPARISON: MS1 vs MS2 ---
fprintf('\n');
fprintf('===========================================================\n');
fprintf('MILESTONE 2: PARAMETER COMPARISON\n');
fprintf('===========================================================\n');
fprintf('Parameter                 MS1 (Baseline)    MS2 (Improved)\n');
fprintf('-----------------------------------------------------------\n');
fprintf('Cell Constant K_cell      1.0 cm^-1         0.1 cm^-1\n');
fprintf('Probe Capacitance C_dl    10 uF             20 uF\n');
fprintf('Baseline Resistance       150 kOhm          15 kOhm\n');
fprintf('Time Constant (tau)       1.5 s             0.3 s\n');
fprintf('Expected Improvement      Baseline          5x Faster!\n');
fprintf('===========================================================\n');
fprintf('\n');

% 1. Sensor & System Parameters (IMPROVED for MS2)
K_cell = 0.1;          % Cell Constant (cm^-1) - REDUCED from 1.0 to 0.1
L_coil = 3e-6;         % Lead Inductance (H) - UNCHANGED
C_dl = 20e-6;          % Probe Capacitance (F) - INCREASED from 10uF to 20uF
f_ex = 1e3;            % AC Excitation Frequency (Hz) - UNCHANGED
R_soil_min = 5;        % Minimum Soil Resistance (Ohm)
R_soil_max = 200e3;    % Maximum Soil Resistance (Ohm)

% --- Test Condition for Improved Characterization ---

% 2. Measurand Value (Improved Baseline R_soil)
% Fresh water baseline IMPROVED by geometry change
R_soil_baseline = 15e3; % Improved Baseline Soil Resistance (Ohm) - was 150k

% Verification of scaling factors
scaling_factor_R = 0.1;  % Resistance scaling (10% of original)
scaling_factor_C = 2.0;  % Capacitance scaling (2x original)

% Verify calculations
R_soil_baseline_old = 150e3;
C_dl_old = 10e-6;
tau_old = R_soil_baseline_old * C_dl_old;
tau_new = R_soil_baseline * C_dl;
improvement_factor = tau_old / tau_new;

fprintf('VALIDATION:\n');
fprintf('  Old R_soil (MS1):           %.1f kOhm\n', R_soil_baseline_old/1000);
fprintf('  New R_soil (MS2):           %.1f kOhm\n', R_soil_baseline/1000);
fprintf('  Old C_dl (MS1):             %.1f uF\n', C_dl_old*1e6);
fprintf('  New C_dl (MS2):             %.1f uF\n', C_dl*1e6);
fprintf('  Old Time Constant (MS1):    %.3f s\n', tau_old);
fprintf('  New Time Constant (MS2):    %.3f s\n', tau_new);
fprintf('  Speed Improvement Factor:   %.1fx FASTER\n', improvement_factor);
fprintf('===========================================================\n');
fprintf('\n');

% 3. Simulation Time Parameters
T_sim = 0.1;          % Total simulation time (s)
dt = 1/(f_ex * 50);    % Time step (s) - 50 times oversampling

% 4. Excitation Signal
V_peak = 1;            % Peak voltage of AC excitation (V)
t_vec = 0:dt:T_sim;    % Time vector
V_in = V_peak * sin(2*pi*f_ex * t_vec); % AC excitation signal (V)
