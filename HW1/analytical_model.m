%% EE568 HW1 - Variable Reluctance Machine: Analytical Model
%  Q1a: Inductance variation as a function of rotor angle
%  Q1b: Torque under constant DC excitation
%
%  Assumptions:
%   - Core is infinitely permeable (mu_r -> inf), so only air-gap reluctance matters
%   - Sinusoidal inductance variation with electrical period = pi (2 poles)
%   - Uniform flux distribution across core cross-section (no fringing)
%   - Air-gap effective area equals core cross-section area at all positions
%
%  Machine geometry (from dimensions figure):
%   - Stator outer: 60 mm wide x 70 mm tall
%   - Core yoke thickness: 15 mm on all sides
%   - Inner window: 30 mm x 40 mm
%   - Core depth (into page): 25 mm
%   - Rotor: D-shaped, outer radius = 12.5 mm, flat at 12 mm from center
%   - Air gap clearance at aligned position: g = 0.5 mm each side

clear; clc; close all;

%% =========================================================
%  1. MACHINE PARAMETERS
%% =========================================================

% Electrical parameters
N  = 300;             % Number of turns
I  = 2.5;             % Coil current [A] (DC)
mu0 = 4*pi*1e-7;      % Permeability of free space [H/m]

% Core geometry
depth      = 25e-3;   % Core depth into page [m]
core_w     = 15e-3;   % Core (yoke/leg) width [m]
A_core     = core_w * depth;   % Core cross-sectional area [m^2]
% A_core = 15e-3 * 25e-3 = 375e-6 m^2

% Mean core path length (center-line of magnetic circuit)
% Score = 2*(inner_width + yoke) + 2*(inner_height + yoke)
%       = 2*(30 + 15) + 2*(40 + 15) = 90 + 110 = 200 mm
l_core = 200e-3;      % Mean core path length [m] (for reference; unused with inf. mu_r)

% Air-gap lengths (total = two gaps in series: flux crosses gap twice)
g_each   = 0.5e-3;            % Air-gap clearance at each pole face [m]
l_gap_min = 2 * g_each;       % Total gap at ALIGNED position (theta = 0 deg) [m]
%                               = 2 * 0.5 mm = 1 mm

% At UNALIGNED position (theta = 90 deg), the D-rotor flat faces the pole:
%   Each effective gap = 2.5 mm  ->  total = 2 * 2.5 mm = 5 mm
l_gap_max = 2 * 2.5e-3;   % Total gap at UNALIGNED [m] = 5 mm

fprintf('=== Geometry ===\n');
fprintf('Core cross-section area : A_core  = %.1f mm^2\n', A_core*1e6);
fprintf('Mean core path length   : l_core  = %.0f mm\n', l_core*1e3);
fprintf('Min total air-gap length: l_gap_min = %.1f mm (aligned)\n', l_gap_min*1e3);
fprintf('Max total air-gap length: l_gap_max = %.1f mm (unaligned)\n\n', l_gap_max*1e3);

%% =========================================================
%  2. RELUCTANCE AND INDUCTANCE (infinite core permeability)
%% =========================================================
% Reluctance: R = l_gap / (mu0 * A_core)   [A-turns/Wb]
R_min = l_gap_min / (mu0 * A_core);   % Minimum reluctance (aligned)
R_max = l_gap_max / (mu0 * A_core);   % Maximum reluctance (unaligned)

% Inductance: L = N^2 / R   [H]
L_max = N^2 / R_min;   % Maximum inductance (aligned,   theta = 0 deg)
L_min = N^2 / R_max;   % Minimum inductance (unaligned, theta = 90 deg)

fprintf('=== Reluctance & Inductance ===\n');
fprintf('R_min (aligned)    = %.4e A/Wb\n', R_min);
fprintf('R_max (unaligned)  = %.4e A/Wb\n', R_max);
fprintf('L_max (aligned)    = %.4f mH\n', L_max*1e3);
fprintf('L_min (unaligned)  = %.4f mH\n\n', L_min*1e3);

%% =========================================================
%  3. INDUCTANCE VARIATION: L(theta)
%% =========================================================
% Assuming sinusoidal variation (one full electrical cycle per 180 deg):
%
%   L(theta) = (L_max + L_min)/2  +  (L_max - L_min)/2 * cos(2*theta)
%
% theta = 0   -> L = L_max  (aligned, minimum reluctance)
% theta = 90  -> L = L_min  (unaligned, maximum reluctance)

theta_deg = 0 : 0.5 : 360;          % Rotor angle [degrees], full rotation
theta_rad = deg2rad(theta_deg);

L_avg  = (L_max + L_min) / 2;
L_amp  = (L_max - L_min) / 2;

L_theta = L_avg + L_amp * cos(2 * theta_rad);   % [H]

%% =========================================================
%  4. TORQUE: T(theta)
%% =========================================================
% From energy/co-energy principle (constant current excitation):
%
%   T(theta) = (1/2) * i^2 * dL/dtheta
%
%   dL/dtheta = -(L_max - L_min) * sin(2*theta)
%
%   T(theta) = -(i^2 / 2) * (L_max - L_min) * sin(2*theta)
%
% Positive torque -> rotation in increasing theta direction

dL_dtheta = -(L_max - L_min) * sin(2 * theta_rad);   % [H/rad]
T_theta   = 0.5 * I^2 * dL_dtheta;                   % [N*m]

T_peak = 0.5 * I^2 * (L_max - L_min);   % Peak torque amplitude

fprintf('=== Torque ===\n');
fprintf('Peak torque amplitude: T_peak = %.4f mN*m\n\n', T_peak*1e3);

%% =========================================================
%  5. PLOTS
%% =========================================================

% Peak locations for inductance
theta_Lmax = [0 180 360];
theta_Lmin = [90 270];

% Peak locations for torque  (T positive peaks at 135, 315; negative at 45, 225)
theta_Tpos = [135 315];
theta_Tneg = [45 225];
L_at_Lmax  = L_avg + L_amp;   % = L_max
L_at_Lmin  = L_avg - L_amp;   % = L_min
T_at_pos   =  T_peak;
T_at_neg   = -T_peak;

fig1 = figure('Name','Analytical Model', ...
              'Units','centimeters','Position',[2 2 22 16]);

% --- Subplot 1: Inductance ---
ax1 = subplot(2,1,1);
plot(theta_deg, L_theta*1e3, 'b-', 'LineWidth', 2);
hold on;
plot(theta_Lmax, L_at_Lmax*1e3*ones(size(theta_Lmax)), 'ko', ...
     'MarkerFaceColor','k', 'MarkerSize', 7);
plot(theta_Lmin, L_at_Lmin*1e3*ones(size(theta_Lmin)), 'ko', ...
     'MarkerFaceColor','k', 'MarkerSize', 7);
% Annotate peak values
text(5,  L_at_Lmax*1e3 + 0.8, sprintf('L_{max} = %.2f mH', L_max*1e3), 'FontSize', 10);
text(95, L_at_Lmin*1e3 + 0.8, sprintf('L_{min} = %.2f mH', L_min*1e3), 'FontSize', 10);
xlabel('Rotor angle \theta (deg)', 'FontSize', 11);
ylabel('L(\theta)  (mH)',          'FontSize', 11);
title('Inductance vs. Rotor Angle', 'FontSize', 12);
grid on;  xlim([0 360]);  xticks(0:45:360);
set(ax1, 'FontSize', 10);

% --- Subplot 2: Torque ---
ax2 = subplot(2,1,2);
plot(theta_deg, T_theta*1e3, 'r-', 'LineWidth', 2);
hold on;
yline(0, 'k-', 'LineWidth', 0.8);
plot(theta_Tpos, T_at_pos*1e3*ones(size(theta_Tpos)), 'ko', ...
     'MarkerFaceColor','k', 'MarkerSize', 7);
plot(theta_Tneg, T_at_neg*1e3*ones(size(theta_Tneg)), 'ko', ...
     'MarkerFaceColor','k', 'MarkerSize', 7);
% Annotate peak values
text(140,  T_at_pos*1e3 + 3, sprintf('+%.1f mN*m', T_peak*1e3), 'FontSize', 10);
text(50,   T_at_neg*1e3 - 6, sprintf('-%.1f mN*m', T_peak*1e3), 'FontSize', 10);
xlabel('Rotor angle \theta (deg)', 'FontSize', 11);
ylabel('T(\theta)  (mN*m)',        'FontSize', 11);
title('Torque vs. Rotor Angle  (DC excitation)', 'FontSize', 12);
grid on;  xlim([0 360]);  xticks(0:45:360);
set(ax2, 'FontSize', 10);

exportgraphics(fig1, 'analytical_LT_plots.png', 'Resolution', 300);
fprintf('Figure saved as analytical_LT_plots.png\n');

%% =========================================================
%  6. SUMMARY TABLE
%% =========================================================
fprintf('\n=== Summary ===\n');
fprintf('L_max  = %.4f mH  (at theta = 0, 180, 360 deg)\n', L_max*1e3);
fprintf('L_min  = %.4f mH  (at theta = 90, 270 deg)\n', L_min*1e3);
fprintf('L_avg  = %.4f mH\n', L_avg*1e3);
fprintf('L_amp  = %.4f mH  (half peak-to-peak)\n', L_amp*1e3);
fprintf('T_peak = %.4f mN*m (at theta = 45, 135, 225, 315 deg)\n', T_peak*1e3);
fprintf('Average torque over full rotation = %.6f N*m (zero for DC)\n', mean(T_theta));
