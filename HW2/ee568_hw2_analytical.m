%% EE568 HW2 – Winding Design & Analytical Modelling
%  Student : Sefer IDACI   |   ID: 2575421
%  Design  : Design 1  (ID mod 5 = 1)  →  Ns = 15, Nm = 8
%  Deadline: 01 June 2026

clear; clc; close all;

%% ================================================================
%% Q1 – INTEGRAL-SLOT WINDING  (6-pole, 72-slot, 3-phase DL)
%% ================================================================
fprintf('=== Q1: Integral-Slot Winding (72-slot, 6-pole, 3-phase) ===\n\n');

Ns1 = 72;   p1 = 3;   m  = 3;           % slots, pole-pairs, phases
ae1 = p1*360/Ns1;                        % elec. deg per slot = 15°
q1  = Ns1/(2*p1*m);                      % slots/pole/phase  = 4
tau1 = Ns1/(2*p1);                       % pole pitch in slots = 12

fprintf('  Slot pitch (elec.)  αe = %.1f°\n', ae1);
fprintf('  Slots/pole/phase     q = %.4g\n', q1);
fprintf('  Pole pitch          τp = %d slots\n\n', tau1);

configs  = [tau1, 11];                   % full-pitch, 11/12 short-pitch
cnames   = {'Full-pitched (y=12)', '11/12 Short-pitched (y=11)'};
harmonics = [1, 3, 5];

for ci = 1:2
    y = configs(ci);
    fprintf('--- %s ---\n', cnames{ci});
    fprintf('  %-22s %8s %8s %8s\n', 'Harmonic', 'kd', 'kp', 'kw');
    fprintf('  %s\n', repmat('-',1,50));
    for n = harmonics
        kd = sin(n*q1*ae1/2 * pi/180) / (q1 * sin(n*ae1/2 * pi/180));
        kp = sin(n*y*pi / (2*tau1));
        kw = abs(kd) * abs(kp);
        fprintf('  %-22s %8.4f %8.4f %8.4f\n', sprintf('n = %d',n), abs(kd), abs(kp), kw);
    end
    fprintf('\n');
end

% ---- Q1 winding diagram (one pole-pair = 24 slots, slots 1..24) ---------
q1_slots = 2*p1*m*q1;     % slots per pole-pair = 24 (one period)
slots_pp = 1 : q1_slots;

% Assign upper layer: sectors of 60° each, A+(0-60) C-(60-120) B+(120-180)
%                                           A-(180-240) C+(240-300) B-(300-360)
ang1 = mod((slots_pp-1)*ae1, 360);
[phase1_up, dir1_up] = assign_phase(ang1);  % helper at end of file

% Lower layer is shifted by (y) slots (coil return path)
ang1_lo = mod((slots_pp-1+configs(1))*ae1, 360);  % full-pitch lower
[ph1_lo_fp, di1_lo_fp] = assign_phase(ang1_lo);
ang1_lo_sp = mod((slots_pp-1+configs(2))*ae1, 360); % short-pitch lower
[ph1_lo_sp, di1_lo_sp] = assign_phase(ang1_lo_sp);

figure('Name','Q1 Winding Layout – One Pole-Pair','Position',[50 50 1100 500]);
for ci = 1:2
    subplot(1,2,ci);
    if ci==1; ph_lo=ph1_lo_fp; di_lo=di1_lo_fp; else; ph_lo=ph1_lo_sp; di_lo=di1_lo_sp; end
    draw_winding_layout(slots_pp, phase1_up, dir1_up, ph_lo, di_lo, cnames{ci});
end
saveas(gcf, 'q1_winding_layout.png');

%% ================================================================
%% Q2 – FRACTIONAL-SLOT WINDING  (15-slot, 8-pole, 3-phase)
%% ================================================================
fprintf('=== Q2: Fractional-Slot Winding (15-slot, 8-pole, 3-phase) ===\n\n');

Ns = 15;  Nm = 8;  p = Nm/2;  m = 3;
as = Nm*180/Ns;              % electrical degrees per slot = 96°
q  = Ns/(Nm*m);              % slots per pole per phase = 0.625
sa = mod((0:Ns-1)*as, 360);  % slot phasor angles [°], slots indexed 1..Ns

fprintf('  Electrical angle per slot  αs = %.2f°\n', as);
fprintf('  Slots per pole per phase    q = %.4f\n\n', q);

% Slot angle table
fprintf('  Slot  |  Angle (°)\n');
fprintf('  ------+-----------\n');
for k = 1:Ns
    fprintf('    %2d  |  %6.1f\n', k, sa(k));
end

% ================================================================
% USER INPUT — edit these 6 arrays to change the winding assignment
%
% Each array lists 5 slot numbers for one phase + one layer.
%   Layer 1:  first n_pos_L1 entries = positive slots (current IN,  +)
%             remaining entries      = negative slots (current OUT, -)
%   Layer 2:  first n_pos_L2 entries = positive slots
%             remaining entries      = negative slots
%
% Slot angles: sa(k) = (k-1)*96°  mod 360°
%   k=1: 0°, k=2: 96°, k=3: 192°, k=4: 288°, k=5: 24°, k=6: 120°,
%   k=7: 216°, k=8: 312°, k=9: 48°, k=10: 144°, k=11: 240°,
%   k=12: 336°, k=13: 72°, k=14: 168°, k=15: 264°
% ================================================================
n_pos_L1 = 3;   % Layer 1: first 3 entries are positive (+), last 2 are negative (-)
n_pos_L2 = 2;   % Layer 2: first 2 entries are positive (+), last 3 are negative (-)

% Winding  (kw=0.9566)
%            [  +    +    +     -    -  ]
A_layer1 = [  1,   5,   9,    3,   7  ];
B_layer1 = [  6,  10,  14,    8,  12  ];
C_layer1 = [  4,  11,  15,    2,  13  ];

%            [  +    +     -    -    -  ]
A_layer2 = [  4,   8,    2,   6,  10  ];
B_layer2 = [  9,  13,    7,  11,  15  ];
C_layer2 = [  3,  14,    1,   5,  12  ];



% ================================================================
% Winding factor — phasor summation for n = 1, 3, 5
% ================================================================
phase_labels = {'A', 'B', 'C'};
L1_all = {A_layer1; B_layer1; C_layer1};
L2_all = {A_layer2; B_layer2; C_layer2};

kw_L1 = zeros(3,3);   % rows = phase (A,B,C),  cols = harmonic (n=1,3,5)

for ph = 1:3
    L1 = L1_all{ph};
    pos_L1 = L1(1:n_pos_L1);          % positive slots, layer 1
    neg_L1 = L1(n_pos_L1+1:end);      % negative slots, layer 1

    for hi = 1:3
        n = harmonics(hi);
        % positive slots: phasor at n*angle
        % negative slots: phasor at n*angle + 180° (current reversal)
        ph_L1 = [n*sa(pos_L1),  n*sa(neg_L1)+180];
        kw_L1(ph,hi) = abs(sum(exp(1j * ph_L1 * pi/180))) / 5;
    end
end

kw_q2 = kw_L1(1,:);   % Phase A winding factors — used in Q3

fprintf('\n  Winding factors (concentrated-coil convention):\n');
fprintf('  Phase |   n=1       n=3       n=5\n');
fprintf('  %s\n', repmat('-',1,35));
for ph = 1:3
    fprintf('    %s   |  %.4f    %.4f    %.4f\n', phase_labels{ph}, kw_L1(ph,:));
end

% ================================================================
% Build per-slot phase/direction from Layer 1 (used by layout plot)
%   ph2 values: 1=A+, 2=A-, 3=B+, 4=B-, 5=C+, 6=C-
% ================================================================
ph2  = zeros(1,Ns);
dir2 = zeros(1,Ns);
for ph = 1:3
    L1 = L1_all{ph};
    ph2 (L1(1:n_pos_L1))      = 2*ph-1;  dir2(L1(1:n_pos_L1))      = +1;
    ph2 (L1(n_pos_L1+1:end))  = 2*ph;    dir2(L1(n_pos_L1+1:end))  = -1;
end

% Build per-slot phase/direction from Layer 2 (for Layer 2 star plot)
ph2_L2  = zeros(1,Ns);
dir2_L2 = zeros(1,Ns);
for ph = 1:3
    L2 = L2_all{ph};
    ph2_L2(L2(1:n_pos_L2))     = 2*ph-1;  dir2_L2(L2(1:n_pos_L2))     = +1;
    ph2_L2(L2(n_pos_L2+1:end)) = 2*ph;    dir2_L2(L2(n_pos_L2+1:end)) = -1;
end

% ================================================================
% Shared plot settings  (change once, applies to all figures)
% ================================================================
cA           = [0.85 0.15 0.15];   % Phase A colour
cB           = [0.15 0.45 0.85];   % Phase B colour
cC           = [0.15 0.70 0.20];   % Phase C colour
cArrow       = 'b';                % phasor arrow colour
cResultant   = 'r';                % resultant arrow colour
arrowWidth   = 1.2;                % individual phasor line width
resultWidth  = 2.5;                % resultant arrow line width
theta_circle = linspace(0, 2*pi, 200);   % unit circle

% ================================================================
% Figure 1 — Star of slots (each slot coloured by phase)
% ================================================================
phase_colors = {cA, cA, cB, cB, cC, cC};   % index 1..6 maps to ph2

figure('Name','Q2 Star of Slots','Position',[50 600 560 480]);
hold on;
for k = 1:Ns
    ang = sa(k) * pi/180;
    c   = phase_colors{ph2(k)};
    quiver(0,0, cos(ang), sin(ang), 0, ...
           'Color',c, 'LineWidth',1.5, 'MaxHeadSize',0.3);
    text(1.15*cos(ang), 1.15*sin(ang), num2str(k), ...
         'FontSize',8, 'HorizontalAlignment','center', 'Color',c);
end
plot(cos(theta_circle), sin(theta_circle), 'k--', 'LineWidth',0.5);
axis equal;  xlim([-1.4 1.4]);  ylim([-1.4 1.4]);  grid on;
xlabel('Real');  ylabel('Imaginary');
title('Star of Slots – 15-slot / 8-pole');
legend([patch(NaN,NaN,cA), patch(NaN,NaN,cB), patch(NaN,NaN,cC)], ...
       'Phase A','Phase B','Phase C', 'Location','southeast');
saveas(gcf, 'q2_star_of_slots.png');

% ================================================================
% Figure 2 — Phase A phasors  (n = 1, 3, 5)
% ================================================================
pos_A = A_layer1(1:n_pos_L1);
neg_A = A_layer1(n_pos_L1+1:end);

figure('Name','Q2 Phase A Phasors','Position',[630 600 900 300]);
for hi = 1:3
    n      = harmonics(hi);
    all_ph = [n*sa(pos_A),  n*sa(neg_A)+180];
    psum   = sum(exp(1j * all_ph * pi/180));

    subplot(1,3,hi);  hold on;
    for ii = 1:length(all_ph)
        a = all_ph(ii)*pi/180;
        quiver(0,0, cos(a),sin(a), 0, cArrow, 'LineWidth',arrowWidth, 'MaxHeadSize',0.4);
    end
    quiver(0,0, real(psum)/5, imag(psum)/5, 0, ...
           cResultant, 'LineWidth',resultWidth, 'MaxHeadSize',0.3);
    plot(cos(theta_circle), sin(theta_circle), 'k--', 'LineWidth',0.5);
    axis equal;  xlim([-1.4 1.4]);  ylim([-1.4 1.4]);  grid on;
    title(sprintf('Phase A,  n=%d   kw = %.4f', n, kw_L1(1,hi)));
    xlabel('Real');  ylabel('Imaginary');
end
saveas(gcf, 'q2_phase_A_phasors.png');

% ================================================================
% Figure 3 — Stator cross-section with teeth and double-layer slots
% ================================================================
figure('Name','Q2 Stator Winding Layout','Position',[50 100 800 800]);
draw_stator_winding(Ns, ph2, dir2, ph2_L2, dir2_L2, ...
                    'Design – 15-slot/8-pole, Double-Layer FSCW');
saveas(gcf, 'q2_winding_layout.png');

%% ================================================================
%% Q3 – ANALYTICAL MODELLING
%% ================================================================
fprintf('\n=== Q3: Analytical Modelling ===\n\n');

%--- Common specs --------------------------------------------------
Rso  = 50e-3;          % stator outer radius [m]
Rro  = 0.6*Rso;        % rotor outer radius  [m] = 30 mm
g    = 1e-3;           % air-gap length      [m]
lm   = 4e-3;           % magnet radial thickness [m]
Br   = 1.3;            % remanence [T]
mur  = 1.05;           % magnet relative permeability
am   = 160/180;        % magnet arc ratio (160° elec.)
Ls   = 100e-3;         % stack length [m]
J    = 5e6;            % current density (rms) [A/m²]
kwc  = 0.60;           % conductor fill factor
Bt   = 1.4;            % target peak flux density in iron [T]
Vdc  = 48;             % DC bus voltage [V]
n_rpm = 1500;          % rated speed [rpm]
kw1  = kw_q2(1);       % winding factor (fundamental)

%--- Derived radii -------------------------------------------------
Rsi      = Rro + g;          % stator inner radius [m] = 31 mm
Rro_core = Rro - lm;         % rotor core outer radius [m] = 26 mm

fprintf('Machine Geometry\n');
fprintf('  Rso (stator outer)     = %.1f mm\n', Rso*1e3);
fprintf('  Rsi (stator inner)     = %.1f mm\n', Rsi*1e3);
fprintf('  Rro (rotor outer)      = %.1f mm\n', Rro*1e3);
fprintf('  Rro_core (core outer)  = %.1f mm\n', Rro_core*1e3);
fprintf('  Air gap g              = %.1f mm\n', g*1e3);
fprintf('  Magnet thickness lm    = %.1f mm\n\n', lm*1e3);

%--- Slot pitch at stator bore ------------------------------------
tau_s = 2*pi*Rsi / Ns;       % slot pitch [m]
fprintf('Stator Slot Geometry\n');
fprintf('  Slot pitch at bore τs  = %.4f mm\n', tau_s*1e3);

%--- First-pass air-gap flux density (no Carter) ------------------
Bg0 = Br*lm / (lm + mur*g);
fprintf('\n  Bg_peak (no Carter)    = %.4f T\n', Bg0);

%--- Tooth width for Bt = 1.4 T ----------------------------------
Bg_avg0 = Bg0 * am;
wtb = Bg_avg0 * tau_s / Bt;
ws  = tau_s - wtb;
fprintf('  Tooth body width wtb   = %.4f mm\n', wtb*1e3);
fprintf('  Slot opening width ws  = %.4f mm\n', ws*1e3);

%--- Carter''s coefficient (exact formula) -----------------------
x   = ws/(2*g);
gam = (4/pi) * (x*atan(x) - log(sqrt(1+x^2)));  % length [m] when multiplied by g
kc  = tau_s / (tau_s - gam*g);
fprintf('\nCarter''s Coefficient\n');
fprintf('  ws / g                 = %.3f\n', ws/g);
fprintf('  γ (slot fringe)        = %.4f mm\n', gam*g*1e3);
fprintf('  Carter coefficient kc  = %.4f\n', kc);

%--- Effective air gap & corrected Bg ----------------------------
g_eff = kc*g + lm/mur;
Bg    = Br*lm / (lm + mur*kc*g);
fprintf('  g_eff = kc·g + lm/μr  = %.4f mm\n', g_eff*1e3);
fprintf('  Bg_peak (corrected)    = %.4f T\n', Bg);

%--- Effective axial length (fringing correction) ----------------
Le = Ls + 2*g;
fprintf('\nEffective Axial Length\n');
fprintf('  Ls (physical)          = %.1f mm\n', Ls*1e3);
fprintf('  Le = Ls + 2g           = %.2f mm\n', Le*1e3);

%--- Pole pitch & flux per pole ----------------------------------
tau_p = pi*Rsi / p;              % pole pitch at stator bore [m]
Phi   = Bg * am * tau_p * Le;    % flux per pole [Wb]
fprintf('\nFlux Per Pole\n');
fprintf('  Pole pitch τp          = %.4f mm\n', tau_p*1e3);
fprintf('  Flux per pole Φ        = %.6f Wb  (%.4f mWb)\n', Phi, Phi*1e3);

%--- Stator and rotor yoke widths --------------------------------
wsy = Phi / (2 * Bt * Le);
wry = Phi / (2 * Bt * Le);
fprintf('\nIron Yoke Widths\n');
fprintf('  Stator yoke wsy        = %.4f mm\n', wsy*1e3);
fprintf('  Rotor yoke wry         = %.4f mm\n', wry*1e3);
fprintf('  Rotor shaft radius     = %.4f mm\n', (Rro_core - wry)*1e3);

%--- Slot dimensions & electrical loading -----------------------
h_total = Rso - Rsi;
h_slot  = h_total - wsy;
A_slot  = ws * h_slot;           % slot area (simplified rectangular) [m²]
A_rms   = J * kwc * A_slot / tau_s;  % linear current density rms [A/m]
A_peak  = A_rms * sqrt(2);

fprintf('\nElectrical Loading\n');
fprintf('  Stator radial height   = %.4f mm\n', h_total*1e3);
fprintf('  Slot height h_slot     = %.4f mm\n', h_slot*1e3);
fprintf('  Slot area (rect.)      = %.4f mm²\n', A_slot*1e6);
fprintf('  A_rms (linear)         = %.2f kA/m\n', A_rms/1e3);

%--- Magnetic loading (average Bg over rotor surface) -----------
Bav = Bg * am;
fprintf('\nMagnetic Loading\n');
fprintf('  Bav = Bg·αm            = %.4f T\n', Bav);

%--- Specific machine constant & shear stress -------------------
% Average electromagnetic shear stress: σ = kw·Bav·A_rms  (N/m²)
% More precisely: σ = (1/2)·kw·Bg_peak·A_peak
sigma = 0.5 * kw1 * Bg * A_peak;
fprintf('\nShear Stress\n');
fprintf('  σ = ½·kw·Bg·A_peak     = %.2f kPa\n', sigma/1e3);

%--- Expected torque & power ------------------------------------
T_exp = sigma * 2*pi * Rsi^2 * Le;
omega = n_rpm * 2*pi / 60;
P_exp = T_exp * omega;
fprintf('\nPerformance Estimates\n');
fprintf('  Expected torque        = %.3f N·m\n', T_exp);
fprintf('  Rated speed ω          = %.2f rad/s\n', omega);
fprintf('  Expected power         = %.1f W\n', P_exp);

%--- Number of turns per phase (for Vdc=48V, n=1500rpm) ---------
omega_e  = p * omega;
Vph_peak = Vdc / sqrt(3);        % peak phase voltage (star, full modulation)
Nph_float = Vph_peak / (kw1 * omega_e * Phi);
Ncs_float = 2*Nph_float*m / Ns; % conductors per slot (must be integer)
% Round to nearest integer conductors/slot
Ncs  = round(Ncs_float);
Nph  = Ncs * Ns / (2*m);
Vph_actual = kw1 * Nph * omega_e * Phi;

fprintf('\nWinding Turns (for Vdc = %.0f V, n = %.0f rpm)\n', Vdc, n_rpm);
fprintf('  ωe (elec. freq.)       = %.2f rad/s\n', omega_e);
fprintf('  Vph_peak (star)        = %.2f V\n', Vph_peak);
fprintf('  Nph (ideal)            = %.2f turns/phase\n', Nph_float);
fprintf('  Ncs (conductors/slot)  = %d  (rounded to integer)\n', Ncs);
fprintf('  Nph (actual)           = %d turns/phase\n', Nph);
fprintf('  Back-EMF (peak)        = %.2f V\n', Vph_actual);

%--- Summary table for report -----------------------------------
fprintf('\n=== Summary Table ===\n');
fprintf('  %-35s %12s\n', 'Parameter', 'Value');
fprintf('  %s\n', repmat('-',1,50));
params = {
  'Stator inner radius Rsi',     sprintf('%.1f mm',  Rsi*1e3);
  'Effective air gap g_eff',     sprintf('%.3f mm',  g_eff*1e3);
  'Carter coefficient kc',       sprintf('%.4f',     kc);
  'Effective axial length Le',   sprintf('%.1f mm',  Le*1e3);
  'Air-gap peak flux density Bg',sprintf('%.4f T',   Bg);
  'Flux per pole Φ',             sprintf('%.4f mWb', Phi*1e3);
  'Average flux density Bav',    sprintf('%.4f T',   Bav);
  'Electrical loading A_rms',    sprintf('%.2f kA/m',A_rms/1e3);
  'Shear stress σ',              sprintf('%.2f kPa', sigma/1e3);
  'Expected torque',             sprintf('%.3f N·m', T_exp);
  'Expected power',              sprintf('%.1f W',   P_exp);
  'Turns per phase Nph',         sprintf('%d',       Nph);
};
for i = 1:size(params,1)
    fprintf('  %-35s %12s\n', params{i,1}, params{i,2});
end

fprintf('\nDone. Figures saved to HW2 folder.\n');

%% ================================================================
%% LOCAL HELPER FUNCTIONS
%% ================================================================

function [ph, d] = assign_phase(angles)
% Returns phase index (1=A+, 2=A-, 3=B+, 4=B-, 5=C+, 6=C-)
% and direction (+1 or -1) for each angle in [0,360).
    n   = length(angles);
    ph  = zeros(1,n);
    d   = zeros(1,n);
    for k = 1:n
        a = mod(angles(k), 360);
        if     a <  60,  ph(k)=1; d(k)= 1;   % A+
        elseif a < 120,  ph(k)=6; d(k)=-1;   % C- (ph=6 for C-, reuse index)
        elseif a < 180,  ph(k)=3; d(k)= 1;   % B+
        elseif a < 240,  ph(k)=2; d(k)=-1;   % A-
        elseif a < 300,  ph(k)=5; d(k)= 1;   % C+
        else,            ph(k)=4; d(k)=-1;   % B-
        end
    end
    % Remap to simple phase 1=A, 2=A, 3=B, 4=B, 5=C, 6=C
    % (direction stored separately in d)
end

function draw_winding_layout(slots, ph_up, dir_up, ph_lo, dir_lo, ttl)
% Simple bar chart layout for one pole-pair of integral-slot winding.
    cmap = [0.85 0.15 0.15;   % A+ red
            0.15 0.45 0.85;   % C- blue
            0.15 0.70 0.20;   % B+ green
            0.85 0.15 0.15;   % A- red
            0.15 0.70 0.20;   % C+ green
            0.15 0.45 0.85];  % B- blue
    Ns = length(slots);
    hold on;
    for k = 1:Ns
        % upper layer (y = 0.5 .. 1)
        fill([k-0.9 k-0.1 k-0.1 k-0.9], [0.5 0.5 1 1], cmap(ph_up(k),:), ...
             'EdgeColor','k','LineWidth',0.5);
        % lower layer (y = 0 .. 0.5)
        fill([k-0.9 k-0.1 k-0.1 k-0.9], [0 0 0.5 0.5], cmap(ph_lo(k),:), ...
             'EdgeColor','k','LineWidth',0.5,'FaceAlpha',0.5);
        % direction arrows
        if dir_up(k) > 0; sym = '\bullet'; else; sym = '\times'; end
        text(k-0.5, 0.75, sym, 'HorizontalAlignment','center','FontSize',7);
        if dir_lo(k) > 0; sym = '\bullet'; else; sym = '\times'; end
        text(k-0.5, 0.25, sym, 'HorizontalAlignment','center','FontSize',7);
    end
    xlim([0 Ns+1]); ylim([-0.2 1.3]); axis off;
    title(ttl, 'FontSize', 9);
    legend([patch(NaN,NaN,[0.85 0.15 0.15]), ...
            patch(NaN,NaN,[0.15 0.45 0.85]), ...
            patch(NaN,NaN,[0.15 0.70 0.20])], ...
           'Phase A','Phase B','Phase C','Location','south','FontSize',7);
end

function draw_winding_layout_radial(Ns, ph2, dir2, ttl)
% Circular slot layout for fractional-slot winding.
    cA = [0.85 0.15 0.15];
    cB = [0.15 0.45 0.85];
    cC = [0.15 0.70 0.20];
    cmap_full = {cA, cA, cB, cB, cC, cC};  % index 1..6

    hold on; axis equal; axis off;
    R = 1.0;  w = 0.25;
    angles_slot = linspace(90, 90-360, Ns+1) * pi/180;
    for k = 1:Ns
        th1 = angles_slot(k);
        th2 = angles_slot(k+1);
        th  = linspace(th1, th2, 20);
        % outer arc polygon
        xo = R*cos(th); yo = R*sin(th);
        xi = (R-w)*cos(fliplr(th)); yi = (R-w)*sin(fliplr(th));
        c = cmap_full{ph2(k)};
        fill([xo xi], [yo yi], c, 'EdgeColor','k','LineWidth',0.6);
        % direction symbol
        tmid = (th1+th2)/2;
        rm   = R - w/2;
        if dir2(k) > 0; sym = '\bullet'; else; sym = '\times'; end
        text(rm*cos(tmid), rm*sin(tmid), sym, ...
             'HorizontalAlignment','center','FontSize',7,'Color','w','FontWeight','bold');
        % slot number
        text(1.15*cos(tmid), 1.15*sin(tmid), num2str(k), ...
             'HorizontalAlignment','center','FontSize',7);
    end
    title(ttl, 'FontSize', 10);
    legend([patch(NaN,NaN,cA), patch(NaN,NaN,cB), patch(NaN,NaN,cC)], ...
           'Phase A','Phase B','Phase C','Location','south');
end

function draw_stator_winding(Ns, ph_L1, dir_L1, ph_L2, dir_L2, ttl)
% Stator cross-section for an FSCW (single-tooth concentrated winding).
% Each slot holds two coil sides SIDE-BY-SIDE (tangential split):
%   - The half nearer tooth k       = go-side of coil k       (Layer 1)
%   - The half nearer tooth k-1     = return-side of coil k-1 (Layer 2)
% Slots ordered clockwise with slot 1 at the top.

    % Phase colours
    cA = [0.95 0.55 0.55];
    cB = [0.55 0.70 0.95];
    cC = [0.55 0.85 0.60];
    phase_colors = {cA, cA, cB, cB, cC, cC};   % index 1..6

    % Geometry (normalised)
    R_yoke_out = 1.00;
    R_yoke_in  = 0.85;     % yoke inner edge / tooth root
    R_bore     = 0.55;     % stator bore / tooth tip
    R_rotor    = 0.50;
    tooth_frac = 0.4;     % tooth angular width / slot pitch

    slot_pitch = 2*pi / Ns;
    tooth_half = tooth_frac      * slot_pitch / 2;
    slot_half  = (1-tooth_frac)  * slot_pitch / 2;
    theta0     = pi/2;

    hold on; axis equal; axis off;
    th_full = linspace(0, 2*pi, 360);

    % --- Back-iron annulus -------------------------------------------
    fill([R_yoke_out*cos(th_full), fliplr(R_yoke_in*cos(th_full))], ...
         [R_yoke_out*sin(th_full), fliplr(R_yoke_in*sin(th_full))], ...
         [0.80 0.80 0.80], 'EdgeColor','k','LineWidth',0.8);

    % --- Teeth -------------------------------------------------------
    for k = 1:Ns
        slot_c  = theta0 - (k-1)*slot_pitch;
        tooth_c = slot_c - slot_pitch/2;          % tooth k between slot k and slot k+1
        th_t = linspace(tooth_c - tooth_half, tooth_c + tooth_half, 20);
        xo = R_yoke_in*cos(th_t);       yo = R_yoke_in*sin(th_t);
        xi = R_bore   *cos(fliplr(th_t)); yi = R_bore *sin(fliplr(th_t));
        fill([xo xi], [yo yi], [0.75 0.75 0.75], ...
             'EdgeColor','k','LineWidth',0.6);
    end

    % --- Slot fillings (TANGENTIAL split: L1 right side, L2 left side)
    phase_letter = {'A','A','B','B','C','C'};
    for k = 1:Ns
        slot_c = theta0 - (k-1)*slot_pitch;

        % Slot 1 is at theta = pi/2 (top); slots advance CLOCKWISE so
        % "smaller theta" is to the RIGHT of the slot (closer to tooth k),
        % "larger theta" is to the LEFT (closer to tooth k-1).
        th_R = linspace(slot_c - slot_half, slot_c, 14);     % right side  (Layer 1)
        th_L = linspace(slot_c, slot_c + slot_half, 14);     % left side   (Layer 2)

        % --- Right side of slot = Layer 1 (go-side of coil k) -------
        c1 = phase_colors{ph_L1(k)};
        xo = R_yoke_in*cos(th_R);       yo = R_yoke_in*sin(th_R);
        xi = R_bore   *cos(fliplr(th_R)); yi = R_bore *sin(fliplr(th_R));
        fill([xo xi], [yo yi], c1, 'EdgeColor','k','LineWidth',0.4);

        % --- Left side of slot = Layer 2 (return of coil k-1) -------
        c2 = phase_colors{ph_L2(k)};
        xo = R_yoke_in*cos(th_L);       yo = R_yoke_in*sin(th_L);
        xi = R_bore   *cos(fliplr(th_L)); yi = R_bore *sin(fliplr(th_L));
        fill([xo xi], [yo yi], c2, 'EdgeColor','k','LineWidth',0.4);

        % --- Radial separator line between the two coil sides --------
        plot([R_yoke_in*cos(slot_c), R_bore*cos(slot_c)], ...
             [R_yoke_in*sin(slot_c), R_bore*sin(slot_c)], ...
             'k-', 'LineWidth',0.6);

        % --- Direction symbols and phase labels ---------------------
        rm  = (R_yoke_in + R_bore)/2;
        thR = slot_c - slot_half/2;     % centre of right half  (Layer 1)
        thL = slot_c + slot_half/2;     % centre of left half   (Layer 2)
        if dir_L1(k) > 0, s1 = '\bullet'; else, s1 = '\times'; end
        if dir_L2(k) > 0, s2 = '\bullet'; else, s2 = '\times'; end
        sgn1 = '+'; if dir_L1(k) < 0, sgn1 = char(8722); end
        sgn2 = '+'; if dir_L2(k) < 0, sgn2 = char(8722); end

        text(rm*cos(thR), rm*sin(thR), ...
             {s1, [phase_letter{ph_L1(k)} sgn1]}, ...
             'HorizontalAlignment','center','VerticalAlignment','middle','FontSize',7);
        text(rm*cos(thL), rm*sin(thL), ...
             {s2, [phase_letter{ph_L2(k)} sgn2]}, ...
             'HorizontalAlignment','center','VerticalAlignment','middle','FontSize',7);

        % --- Slot number ----------------------------------------------
        text(1.10*cos(slot_c), 1.10*sin(slot_c), num2str(k), ...
             'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
    end

    % --- Rotor (visual reference) ------------------------------------
    fill(R_rotor*cos(th_full), R_rotor*sin(th_full), [0.95 0.90 0.75], ...
         'EdgeColor','k','LineWidth',0.6);
    text(0, 0, 'Rotor', 'HorizontalAlignment','center','FontSize',8, ...
         'Color',[0.4 0.4 0.4]);

    xlim([-1.25 1.25]); ylim([-1.25 1.25]);
    title(ttl, 'FontSize', 11);
    legend([patch(NaN,NaN,cA), patch(NaN,NaN,cB), patch(NaN,NaN,cC)], ...
           'Phase A','Phase B','Phase C', ...
           'Location','southoutside','Orientation','horizontal');
end
