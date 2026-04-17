%% EE568 HW1 - Variable Reluctance Machine: all figures

clear; clc; close all;

%% Parameters
N = 300;  I = 2.5;  mu0 = 4*pi*1e-7;  Acore = 15e-3 * 25e-3;

%% Analytical model
Lmax = N^2 * mu0 * Acore / (2 * 0.5e-3);
Lmin = N^2 * mu0 * Acore / (2 * 2.5e-3);
Lavg = (Lmax+Lmin)/2;  Lamp = (Lmax-Lmin)/2;
th_an = (0:0.5:360)';
L_an  = (Lavg + Lamp*cos(2*deg2rad(th_an))) * 1e3;          % mH
T_an  = -0.5*I^2 * 2*Lamp * sin(2*deg2rad(th_an)) * 1e3;   % mN*m
Tp    =  0.5*I^2 * (Lmax-Lmin) * 1e3;
fprintf('Analytical: Lmax=%.2f mH  Lmin=%.2f mH  Tpeak=%.1f mN*m\n', Lmax*1e3, Lmin*1e3, Tp);

%% Linear FEA data
r      = readcell('ParametricSetup1_Result.csv');  r = r(2:end,:);
th_lin = cellfun(@(s) str2double(erase(s,'deg')),         r(:,2));
T_lin  = cellfun(@(s) str2double(erase(s,'NewtonMeter')), r(:,3)) * 1e3;
L_lin  = cellfun(@(s) str2double(erase(s,'nH')),          r(:,4)) * 1e-6;

%% Nonlinear FEA data
r     = readcell('ParametricSetup1_Result_nonlinear.csv');  r = r(2:end,:);
th_nl = cellfun(@(s) str2double(erase(s,'deg')),         r(:,2));
T_nl  = cellfun(@(s) str2double(erase(s,'NewtonMeter')), r(:,3)) * 1e3;
L_nl  = cellfun(@(s) str2double(erase(s,'nH')),          r(:,4)) * 1e-6;

%% B-H data
bh   = readmatrix('steel1010_bh_curve.tab','FileType','text','NumHeaderLines',1);
H_bh = bh(:,1);  B_bh = bh(:,2);

%% Key values
fprintf('\nLinear FEA key positions:\n');
fprintf('%-6s  %-10s  %-12s  %-10s\n','Angle','L (mH)','W (mJ)','T (mN*m)');
for ang = [0 45 90]
    idx = find(th_lin==ang,1);
    Lv=L_lin(idx); Tv=T_lin(idx); Wv=0.5*(Lv*1e-3)*I^2*1e3;
    fprintf('%-6d  %-10.3f  %-12.3f  %-10.3f\n',ang,Lv,Wv,Tv);
end
fprintf('\nNonlinear FEA key positions:\n');
fprintf('%-6s  %-10s  %-12s  %-10s\n','Angle','L (mH)','W (mJ)','T (mN*m)');
for ang = [0 45 90]
    idx = find(th_nl==ang,1);
    Lv=L_nl(idx); Tv=T_nl(idx); Wv=0.5*(Lv*1e-3)*I^2*1e3;
    fprintf('%-6d  %-10.3f  %-12.3f  %-10.3f\n',ang,Lv,Wv,Tv);
end

%% Fig 1: Analytical L and T
fig1 = figure('Units','centimeters','Position',[2 2 22 16]);

subplot(2,1,1);
plot(th_an, L_an, 'b-', 'LineWidth',2);
hold on;
yline(Lmax*1e3,'k:','LineWidth',0.8);
yline(Lmin*1e3,'k:','LineWidth',0.8);
text(5,  Lmax*1e3+0.8, sprintf('L_{max} = %.2f mH',Lmax*1e3),'FontSize',10);
text(95, Lmin*1e3+0.8, sprintf('L_{min} = %.2f mH',Lmin*1e3),'FontSize',10);
xlabel('Rotor angle \theta (deg)','FontSize',11);
ylabel('L(\theta)  (mH)','FontSize',11);
title('Inductance vs. Rotor Angle','FontSize',12);
grid on;  xlim([0 360]);  xticks(0:45:360);

subplot(2,1,2);
plot(th_an, T_an, 'r-', 'LineWidth',2);
hold on;
yline(0,'k-','LineWidth',0.8);
yline( Tp,'k:','LineWidth',0.8);
yline(-Tp,'k:','LineWidth',0.8);
text(140,  Tp+3, sprintf('+%.1f mN*m',Tp),'FontSize',10);
text(50,  -Tp-6, sprintf('-%.1f mN*m',Tp),'FontSize',10);
xlabel('Rotor angle \theta (deg)','FontSize',11);
ylabel('T(\theta)  (mN*m)','FontSize',11);
title('Torque vs. Rotor Angle (DC excitation)','FontSize',12);
grid on;  xlim([0 360]);  xticks(0:45:360);  ylim([-130 130]);

exportgraphics(fig1,'analytical_LT_plots.png','Resolution',300);

%% Fig 2: B-H curve
fig2 = figure('Units','centimeters','Position',[2 2 14 10]);
plot(H_bh, B_bh, 'k-', 'LineWidth',1.5);
xlabel('H  (A/m)','FontSize',11);
ylabel('B  (T)','FontSize',11);
title('B--H Curve: steel\_1010','FontSize',12);
grid on;
exportgraphics(fig2,'bh_curve_steel1010.png','Resolution',300);

%% Fig 3: Q2 - Linear FEA vs Analytical
fig3 = figure('Units','centimeters','Position',[2 2 22 16]);

subplot(2,1,1);
plot(th_an,  L_an,  'b--','LineWidth',1.5,'DisplayName','Analytical');
hold on;
plot(th_lin, L_lin, 'b-', 'LineWidth',1.5,'DisplayName','FEA linear (\mu_r=4000)');
xlabel('Rotor angle \theta (deg)','FontSize',11);
ylabel('L(\theta)  (mH)','FontSize',11);
title('Inductance vs. Rotor Angle -- FEA vs Analytical','FontSize',12);
legend('Location','northeast','FontSize',10);
grid on;  xlim([0 360]);  xticks(0:45:360);

subplot(2,1,2);
plot(th_an,  T_an,  'r--','LineWidth',1.5,'DisplayName','Analytical');
hold on;
plot(th_lin, T_lin, 'r-', 'LineWidth',1.5,'DisplayName','FEA linear (\mu_r=4000)');
yline(0,'k-','LineWidth',0.8,'HandleVisibility','off');
xlabel('Rotor angle \theta (deg)','FontSize',11);
ylabel('T(\theta)  (mN*m)','FontSize',11);
title('Torque vs. Rotor Angle -- FEA vs Analytical','FontSize',12);
legend('Location','northeast','FontSize',10);
grid on;  xlim([0 360]);  xticks(0:45:360);

exportgraphics(fig3,'fea_comparison.png','Resolution',300);

%% Fig 4: Q3 - All models
fig4 = figure('Units','centimeters','Position',[2 2 22 16]);

subplot(2,1,1);
plot(th_an,  L_an,  'b--','LineWidth',1.5,'DisplayName','Analytical');
hold on;
plot(th_lin, L_lin, 'b-', 'LineWidth',1.5,'DisplayName','FEA linear (\mu_r=4000)');
plot(th_nl,  L_nl,  'g-', 'LineWidth',1.5,'DisplayName','FEA nonlinear (steel\_1010)');
xlabel('Rotor angle \theta (deg)','FontSize',11);
ylabel('L(\theta)  (mH)','FontSize',11);
title('Inductance vs. Rotor Angle -- All Models','FontSize',12);
legend('Location','northeast','FontSize',10);
grid on;  xlim([0 360]);  xticks(0:45:360);

subplot(2,1,2);
plot(th_an,  T_an,  'r--','LineWidth',1.5,'DisplayName','Analytical');
hold on;
plot(th_lin, T_lin, 'r-', 'LineWidth',1.5,'DisplayName','FEA linear (\mu_r=4000)');
plot(th_nl,  T_nl,  'g-', 'LineWidth',1.5,'DisplayName','FEA nonlinear (steel\_1010)');
yline(0,'k-','LineWidth',0.8,'HandleVisibility','off');
xlabel('Rotor angle \theta (deg)','FontSize',11);
ylabel('T(\theta)  (mN*m)','FontSize',11);
title('Torque vs. Rotor Angle -- All Models','FontSize',12);
legend('Location','northeast','FontSize',10);
grid on;  xlim([0 360]);  xticks(0:45:360);

exportgraphics(fig4,'nonlinear_comparison.png','Resolution',300);

%% Fig 5: Q4 - Switched excitation
T_sw_an  = max(T_an,  0);
T_sw_lin = max(T_lin, 0);
T_sw_nl  = max(T_nl,  0);
Tavg_an  = mean(T_sw_an);
Tavg_lin = mean(T_sw_lin);
Tavg_nl  = mean(T_sw_nl);
fprintf('\nSwitched average torque:\n');
fprintf('  Analytical:    %.2f mN*m\n', Tavg_an);
fprintf('  Linear FEA:    %.2f mN*m\n', Tavg_lin);
fprintf('  Nonlinear FEA: %.2f mN*m\n', Tavg_nl);

fig5 = figure('Units','centimeters','Position',[2 2 22 10]);
plot(th_an,  T_sw_an,  'r--','LineWidth',1.5,'DisplayName','Analytical');
hold on;
plot(th_lin, T_sw_lin, 'b-', 'LineWidth',1.5,'DisplayName','FEA linear (\mu_r=4000)');
plot(th_nl,  T_sw_nl,  'g-', 'LineWidth',1.5,'DisplayName','FEA nonlinear (steel\_1010)');
yline(Tavg_an,  'r:', 'LineWidth',1.2, 'HandleVisibility','off');
yline(Tavg_lin, 'b:', 'LineWidth',1.2, 'HandleVisibility','off');
yline(Tavg_nl,  'g:', 'LineWidth',1.2, 'HandleVisibility','off');
yline(0,'k-','LineWidth',0.8,'HandleVisibility','off');
text(195, Tavg_an+3,  sprintf('%.1f mN*m',Tavg_an),  'Color','r',          'FontSize',9);
text(195, Tavg_lin+3, sprintf('%.1f mN*m',Tavg_lin), 'Color','b',          'FontSize',9);
text(195, Tavg_nl-5,  sprintf('%.1f mN*m',Tavg_nl),  'Color',[0 0.55 0],   'FontSize',9);
xlabel('Rotor angle \theta (deg)','FontSize',11);
ylabel('T(\theta)  (mN*m)','FontSize',11);
title('Switched Excitation -- Torque vs. Rotor Angle','FontSize',12);
legend('Location','northeast','FontSize',10);
grid on;  xlim([0 360]);  xticks(0:45:360);

exportgraphics(fig5,'switched_torque.png','Resolution',300);
fprintf('All figures saved.\n');
