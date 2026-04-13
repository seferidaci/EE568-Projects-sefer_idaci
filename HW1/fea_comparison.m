%% EE568 HW1 - FEA vs Analytical Comparison
% Reads Maxwell parametric sweep CSV and plots against analytical model

clear; clc; close all;

%% 1. READ FEA DATA
raw      = readcell('ParametricSetup1_Result.csv');
raw      = raw(2:end, :);   % skip header

theta_fea = cellfun(@(s) str2double(erase(s,'deg')),         raw(:,2));
T_fea     = cellfun(@(s) str2double(erase(s,'NewtonMeter')), raw(:,3)) * 1e3;  % mN*m
L_fea     = cellfun(@(s) str2double(erase(s,'nH')),          raw(:,4)) * 1e-6; % mH

%% 2. ANALYTICAL MODEL
N    = 300;  I = 2.5;  mu0 = 4*pi*1e-7;
Acore = 15e-3 * 25e-3;
Lmax  = N^2 * mu0 * Acore / (2 * 0.5e-3);
Lmin  = N^2 * mu0 * Acore / (2 * 2.5e-3);
Lavg  = (Lmax + Lmin) / 2;
Lamp  = (Lmax - Lmin) / 2;

theta_an = (0:0.5:360)';
L_an = (Lavg + Lamp * cos(2*deg2rad(theta_an))) * 1e3;
T_an = -0.5 * I^2 * 2 * Lamp * sin(2*deg2rad(theta_an)) * 1e3;

%% 3. KEY VALUES TABLE
fprintf('FEA Results at key positions (I = %.1f A):\n', I);
fprintf('%-6s  %-10s  %-12s  %-12s\n', 'Angle', 'L (mH)', 'W (mJ)', 'T (mN*m)');
for ang = [0, 45, 90]
    idx  = find(theta_fea == ang, 1);
    Lval = L_fea(idx);
    Wval = 0.5 * (Lval*1e-3) * I^2 * 1e3;   % linear approx: W = 0.5*L*I^2 [mJ]
    Tval = T_fea(idx);
    fprintf('%-6d  %-10.3f  %-12.3f  %-12.3f\n', ang, Lval, Wval, Tval);
end

%% 4. SUBSAMPLE TO 10-DEGREE STEPS
mask      = mod(theta_fea, 1) == 0;
theta_10  = theta_fea(mask);
L_10      = L_fea(mask);
T_10      = T_fea(mask);

%% 5. COMPARISON PLOTS
fig = figure('Units','centimeters','Position',[2 2 22 16]);

% -- Inductance --
ax1 = subplot(2,1,1);
plot(theta_an, L_an, 'b--', 'LineWidth', 1.5, 'DisplayName', 'Analytical');
hold on;
plot(theta_10, L_10, 'b-o', 'LineWidth', 1.5, 'MarkerSize', 4, ...
     'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b', 'DisplayName', 'FEA (linear iron, \mu_r=4000)');
xlabel('Rotor angle \theta (deg)', 'FontSize', 11);
ylabel('L(\theta)  (mH)',          'FontSize', 11);
title('Inductance vs. Rotor Angle -- FEA vs Analytical', 'FontSize', 12);
legend('Location','northeast', 'FontSize', 10);
grid on;  xlim([0 360]);  xticks(0:45:360);
set(ax1, 'FontSize', 10);

% -- Torque --
ax2 = subplot(2,1,2);
plot(theta_an, T_an, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Analytical');
hold on;
plot(theta_10, T_10, 'r-o', 'LineWidth', 1.5, 'MarkerSize', 4, ...
     'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'DisplayName', 'FEA (linear iron, \mu_r=4000)');
yline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');
xlabel('Rotor angle \theta (deg)', 'FontSize', 11);
ylabel('T(\theta)  (mN*m)',        'FontSize', 11);
title('Torque vs. Rotor Angle -- FEA vs Analytical', 'FontSize', 12);
legend('Location','northeast', 'FontSize', 10);
grid on;  xlim([0 360]);  xticks(0:45:360);
set(ax2, 'FontSize', 10);

exportgraphics(fig, 'fea_comparison.png', 'Resolution', 300);
fprintf('Figure saved: fea_comparison.png\n');
