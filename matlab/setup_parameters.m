% =========================================================================
% Soil Salinity (EC)
% Baseline Simulation Parameters
% =========================================================================

% 1. Sensor & System Parameters (from Table I of your document)
K_cell = 1.0;          % Cell Constant (cm^-1, though assumed unitless for modeling) [cite: 97]
L_coil = 3e-6;         % Lead Inductance (H) [cite: 97]
C_dl = 10e-6;          % Probe Capacitance (F) [cite: 97]
f_ex = 1e3;            % AC Excitation Frequency (Hz) [cite: 97]
R_soil_min = 5;        % Minimum Soil Resistance (Ohm) [cite: 97]
R_soil_max = 200e3;    % Maximum Soil Resistance (Ohm) [cite: 97]

% --- Test Condition for Baseline Characterization ---

% 2. Measurand Value (Baseline R_soil)
% Choosing a mid-range R_soil (e.g., 10 kOhm) for stability.
R_soil_baseline = 10e3; % Baseline Soil Resistance (Ohm) 

% 3. Simulation Time Parameters
T_sim = 0.1;          % Total simulation time (s) - chosen to capture transient/steady-state
dt = 1/(f_ex * 50);    % Time step (s) - 50 times oversampling of the excitation frequency

% 4. Excitation Signal
V_peak = 1;            % Peak voltage of AC excitation (V)
t_vec = 0:dt:T_sim;    % Time vector
V_in = V_peak * sin(2*pi*f_ex * t_vec); % AC excitation signal (V)