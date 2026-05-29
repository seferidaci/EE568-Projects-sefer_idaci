%% EE568 HW1 -- Q3: Nonlinear FEA vs Linear FEA vs Analytical
% Both parametric sweeps were run CCW.  Torque is negated on import to
% match the CW-positive convention used in the analytical model.

clear; clc; close all;

%% 1. READ NONLINEAR CSV
raw_nl   = readcell('ParametricSetup1_Result_nonlinear.csv');
raw_nl   = raw_nl(2:end, :);
theta_nl = cellfun(@(s) str2double(erase(s,'deg')),         raw_nl(:,2));
T_nl     = cellfun(@(s) str2double(erase(s,'NewtonMeter')), raw_nl(:,3)) * 1e3;  % mN*m
L_nl     = cellfun(@(s) str2double(erase(s,'nH')),          raw_nl(:,4)) * 1e-6; % mH
% CCW sweep -- Maxwell already reports torque with the same sign convention
% as the analytical model (positive = CCW), so no negation is needed.

%% 2. READ LINEAR CSV
raw_lin   = readcell('ParametricSetup1_Result.csv');
raw_lin   = raw_lin(2:end, :);
theta_lin = cellfun(@(s) str2double(erase(s,'deg')),         raw_lin(:,2));
T_lin     = cellfun(@(s) str2double(erase(s,'NewtonMeter')), raw_lin(:,3)) * 1e3;
L_lin     = cellfun(@(s) str2double(erase(s,'nH')),          raw_lin(:,4)) * 1e-6;

%% 3. READ B-H CURVE
bh   = readmatrix('steel1010_bh_curve.tab', 'FileType','text', 'NumHeaderLines',1);
H_bh = bh(:,1);   % A/m
B_bh = bh(:,2);   % T

%% 4. ANALYTICAL MODEL
N     = 300;  I = 2.5;  mu0 = 4*pi*1e-7;  Acore = 15e-3 * 25e-3;
Lmax_a = N^2 * mu0 * Acore / (2 * 0.5e-3);
Lmin_a = N^2 * mu0 * Acore / (2 * 2.5e-3);
Lavg_a = (Lmax_a + Lmin_a) / 2;
Lamp_a = (Lmax_a - Lmin_a) / 2;
theta_an = (0:0.5:360)';
L_an = (Lavg_a + Lamp_a * cos(2*deg2rad(theta_an))) * 1e3;
T_an = -0.5 * I^2 * 2 * Lamp_a * sin(2*deg2rad(theta_an)) * 1e3;

%% 5. KEY VALUES TABLE
fprintf('Nonlinear FEA (steel_1010, I = %.1f A):\n', I);
fprintf('%-6s  %-10s  %-14s  %-12s\n','Angle','L (mH)','W_approx (mJ)','T (mN*m)');
for ang = [0, 45, 90]
    idx = find(theta_nl == ang, 1);
    Lv  = L_nl(idx);
    Wv  = 0.5 * (Lv*1e-3) * I^2 * 1e3;   % linear approx [mJ]
    Tv  = T_nl(idx);
    fprintf('%-6d  %-10.3f  %-14.3f  %-12.3f\n', ang, Lv, Wv, Tv);
end

%% 6. B-H CURVE FIGURE
fig1 = figure('Units','centimeters','Position',[2 2 14 10]);
plot(H_bh, B_bh, 'k-o', 'LineWidth',1.5, 'MarkerSize',0.1, 'MarkerFaceColor','k');
xlabel('H  (A/m)', 'FontSize',11);
ylabel('B  (T)',   'FontSize',11);
title('B--H Curve: steel\_1010', 'FontSize',12);
grid on;
set(gca,'FontSize',10);
exportgraphics(fig1, 'bh_curve_steel1010.png', 'Resolution',300);
fprintf('Saved: bh_curve_steel1010.png\n');

%% 7. THREE-WAY COMPARISON FIGURE
fig2 = figure('Units','centimeters','Position',[2 2 22 16]);

% -- Inductance --
ax1 = subplot(2,1,1);
plot(theta_an, L_an, 'b--', 'LineWidth',1.5, 'DisplayName','Analytical');
hold on;
plot(theta_lin, L_lin, 'b-o', 'LineWidth',1.2, 'MarkerSize',0.1, ...
     'MarkerFaceColor','b', 'DisplayName','FEA linear (\mu_r=4000)');
plot(theta_nl,  L_nl,  'g-s', 'LineWidth',1.2, 'MarkerSize',0.1, ...
     'MarkerFaceColor','g', 'DisplayName','FEA nonlinear (steel\_1010)');
xlabel('Rotor angle \theta (deg)', 'FontSize',11);
ylabel('L(\theta)  (mH)',          'FontSize',11);
title('Inductance vs. Rotor Angle -- All Models', 'FontSize',12);
legend('Location','northeast', 'FontSize',10);
grid on;  xlim([0 360]);  xticks(0:45:360);
set(ax1,'FontSize',10);

% -- Torque --
ax2 = subplot(2,1,2);
plot(theta_an, T_an, 'r--', 'LineWidth',1.5, 'DisplayName','Analytical');
hold on;
plot(theta_lin, T_lin, 'r-o', 'LineWidth',1.2, 'MarkerSize',0.1, ...
     'MarkerFaceColor','r', 'DisplayName','FEA linear (\mu_r=4000)');
plot(theta_nl,  T_nl,  'g-s', 'LineWidth',1.2, 'MarkerSize',0.1, ...
     'MarkerFaceColor','g', 'DisplayName','FEA nonlinear (steel\_1010)');
yline(0, 'k-', 'LineWidth',0.8, 'HandleVisibility','off');
xlabel('Rotor angle \theta (deg)', 'FontSize',11);
ylabel('T(\theta)  (mN*m)',        'FontSize',11);
title('Torque vs. Rotor Angle -- All Models', 'FontSize',12);
legend('Location','northeast', 'FontSize',10);
grid on;  xlim([0 360]);  xticks(0:45:360);
set(ax2,'FontSize',10);

exportgraphics(fig2, 'nonlinear_comparison.png', 'Resolution',300);
fprintf('Saved: nonlinear_comparison.png\n');
