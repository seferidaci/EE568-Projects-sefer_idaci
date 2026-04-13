%% EE568 HW1 - Variable Reluctance Machine: Analytical Model
% Q1a: Inductance vs. rotor angle
% Q1b: Torque under DC excitation
%
% Assumptions:
%   - Infinitely permeable core (air-gap reluctance only)
%   - Sinusoidal L(theta), period = 180 deg (2-pole)
%   - No fringing; uniform flux across Acore

clear; clc; close all;

%% 1. PARAMETERS
N   = 300;           % Turns
I   = 2.5;           % DC current [A]
mu0 = 4*pi*1e-7;     % [H/m]

depth  = 25e-3;      % Core depth [m]
wcore  = 15e-3;      % Core width [m]
Acore  = wcore * depth;   % = 375e-6 m^2

g_aligned   = 2 * 0.5e-3;    % Total air-gap at aligned   (2x0.5 mm) [m]
g_unaligned = 2 * 2.5e-3;    % Total air-gap at unaligned (2x2.5 mm) [m]

%% 2. RELUCTANCE & INDUCTANCE
R_aligned   = g_aligned   / (mu0 * Acore);
R_unaligned = g_unaligned / (mu0 * Acore);

Lmax = N^2 / R_aligned;    % Inductance at aligned   position [H]
Lmin = N^2 / R_unaligned;  % Inductance at unaligned position [H]

fprintf('Lmax = %.4f mH,  Lmin = %.4f mH\n', Lmax*1e3, Lmin*1e3);

%% 3. L(theta)
theta_deg = 0:0.5:360;
theta_rad = deg2rad(theta_deg);

Lavg = (Lmax + Lmin) / 2;
Lamp = (Lmax - Lmin) / 2;

L = Lavg + Lamp * cos(2 * theta_rad);   % [H]

%% 4. T(theta)
dLdtheta = -2 * Lamp * sin(2 * theta_rad);  % [H/rad]
T        = 0.5 * I^2 * dLdtheta;            % [N*m]
Tpeak    = 0.5 * I^2 * (Lmax - Lmin);

fprintf('Tpeak = %.4f mN*m\n', Tpeak*1e3);

%% 5. PLOTS
fig1 = figure('Name','Analytical Model', ...
              'Units','centimeters','Position',[2 2 22 16]);

% -- Inductance --
ax1 = subplot(2,1,1);
plot(theta_deg, L*1e3, 'b-', 'LineWidth', 2);
hold on;
plot([0 180 360], Lmax*1e3*ones(1,3), 'ko', 'MarkerFaceColor','k', 'MarkerSize', 7);
plot([90 270],    Lmin*1e3*ones(1,2), 'ko', 'MarkerFaceColor','k', 'MarkerSize', 7);
text(5,  Lmax*1e3 + 0.8, sprintf('L_{max} = %.2f mH', Lmax*1e3), 'FontSize', 10);
text(95, Lmin*1e3 + 0.8, sprintf('L_{min} = %.2f mH', Lmin*1e3), 'FontSize', 10);
xlabel('Rotor angle \theta (deg)', 'FontSize', 11);
ylabel('L(\theta)  (mH)',          'FontSize', 11);
title('Inductance vs. Rotor Angle', 'FontSize', 12);
grid on;  xlim([0 360]);  xticks(0:45:360);
set(ax1, 'FontSize', 10);

% -- Torque --
ax2 = subplot(2,1,2);
plot(theta_deg, T*1e3, 'r-', 'LineWidth', 2);
hold on;
yline(0, 'k-', 'LineWidth', 0.8);
plot([135 315],  Tpeak*1e3*ones(1,2), 'ko', 'MarkerFaceColor','k', 'MarkerSize', 7);
plot([45  225], -Tpeak*1e3*ones(1,2), 'ko', 'MarkerFaceColor','k', 'MarkerSize', 7);
text(140,  Tpeak*1e3 + 3, sprintf('+%.1f mN*m', Tpeak*1e3), 'FontSize', 10);
text(50,  -Tpeak*1e3 - 6, sprintf('-%.1f mN*m', Tpeak*1e3), 'FontSize', 10);
xlabel('Rotor angle \theta (deg)', 'FontSize', 11);
ylabel('T(\theta)  (mN*m)',        'FontSize', 11);
title('Torque vs. Rotor Angle  (DC excitation)', 'FontSize', 12);
grid on;  xlim([0 360]);  xticks(0:45:360);
set(ax2, 'FontSize', 10);

exportgraphics(fig1, 'analytical_LT_plots.png', 'Resolution', 300);
fprintf('Figure saved: analytical_LT_plots.png\n');

%% 6. SUMMARY
fprintf('\nSummary:\n');
fprintf('  Lmax  = %.4f mH\n', Lmax*1e3);
fprintf('  Lmin  = %.4f mH\n', Lmin*1e3);
fprintf('  Lavg  = %.4f mH\n', Lavg*1e3);
fprintf('  Tpeak = %.4f mN*m\n', Tpeak*1e3);
fprintf('  Tavg (full rotation, DC) = %.6f N*m\n', mean(T));
