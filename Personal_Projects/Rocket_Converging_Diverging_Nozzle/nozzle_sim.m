% This is a prototype script for a chemsitry & math research project
% Quasi-1D, isentropic conical C–D nozzle with straight throat.
% Independent converging/diverging half-angles
% Dependent Mach number/p/T/V/thrust.
% Author: Brilliant G. Purnawan

clear; clc; close all;

%% ---------------- Nozzle Geometry (m) ----------------
Lconv   = 8.25e-3;   % Converging Length
Lthroat = 3.50e-3;   % Straight Throat Length
Ldiv    = 16.25e-3;  % Diverging Length
rt      = 4.00e-3;   % Throat Radius

%% ---- Angle input (degrees) ----
ang_c_str = input('Enter converging half-angle θc [deg]  (default 30): ', 's');
ang_d_str = input('Enter diverging  half-angle θd [deg]  (default 12): ', 's');

if isempty(ang_c_str), ang_c_deg = 30; else, ang_c_deg = str2double(ang_c_str); end
if isempty(ang_d_str), ang_d_deg = 12; else, ang_d_deg = str2double(ang_d_str); end
if isnan(ang_c_deg) || isnan(ang_d_deg)
    error('Invalid input: please enter numeric angles in degrees.');
end

theta_c = deg2rad(ang_c_deg);   % converging half-angle  [rad]
theta_d = deg2rad(ang_d_deg);   % diverging  half-angle  [rad]

% -------- Angle Realistic Limits --------
if ang_c_deg < 0 || ang_d_deg < 0
    error('Angles must be non-negative half-angles (degrees).');
end
% Typical conical ranges:
%   converging: ~20–45°   (faster contraction vs losses)
%   diverging : ~10–15°   (>~18–20° risk of separation)
if ang_c_deg < 10 || ang_c_deg > 60
    warning('Converging half-angle %.1f° is unusual (typical ~20–45°).', ang_c_deg);
end
if ang_d_deg < 5 || ang_d_deg > 20
    warning('Diverging half-angle %.1f° may cause separation or excessive length (typical ~10–15°).', ang_d_deg);
end

% Derived inlet/exit radii from angles (conical)
rin = rt + Lconv*tan(theta_c);     % inlet radius at start of converger
re  = rt + Ldiv *tan(theta_d);     % exit radius at end of diverger

%% ---- Axial grid ----
Nx_c = 150; Nx_t = 40; Nx_d = 300;
x_c = linspace(-Lconv, 0,       Nx_c);
x_t = linspace(0,      Lthroat, Nx_t);
x_d = linspace(Lthroat, Lthroat+Ldiv, Nx_d);
x   = [x_c, x_t(2:end), x_d(2:end)];

% Radius profile (conical -> straight -> conical)
r_c = rin + (rt - rin) * ((x_c + Lconv)/Lconv);
r_t = rt * ones(size(x_t));
r_d = rt  + (re - rt ) * ((x_d - Lthroat)/Ldiv);
r   = [r_c, r_t(2:end), r_d(2:end)];
A   = pi*r.^2;
Astar = pi*rt^2;

%% ---------------- Gas & BCs ----------------
% For KNSU (Rocket Candy) exhaust, gamma ~ 1.18–1.25, R ~ 330–370 J/(kg.K)
gamma = 1.22;     % specific heat ratio
R     = 355;      % J/(kg.K)
Pc    = 5e5;      % Pa (chamber pressure)
Tc    = 2000;     % K  (chamber temperature)
Pa    = 1.013e5;  % Pa (ambient)

%% ---------------- Solve M(x) ----------------
M = zeros(size(A));
for i = 1:numel(A)
    AR = A(i)/Astar;
    if x(i) < 0                      % converging
        M(i) = mach_from_area(AR, gamma, 'sub');
    elseif x(i) <= Lthroat           % straight throat (force ~1)
        M(i) = 1.0;
    else                             % diverging
        M(i) = mach_from_area(AR, gamma, 'sup');
    end
end

%% ---------------- Flow properties ----------------
% Choked mass flow from chamber stagnation conditions:
mdot = Astar * Pc * sqrt(gamma/(R*Tc)) * (2/(gamma+1))^((gamma+1)/(2*(gamma-1)));

% Static properties along nozzle
T   = Tc ./ (1 + (gamma-1)/2 .* M.^2);
p   = Pc .* (T./Tc).^(gamma/(gamma-1));
rho = p ./ (R*T);
V   = M .* sqrt(gamma*R.*T);

Ae = A(end);  Me = M(end);  pe = p(end);  Ve = V(end);
Thrust = mdot*Ve + (pe - Pa)*Ae;

% Expansion status
if pe > Pa, status = "UNDER-expanded (pe > Pa)";
elseif abs(pe-Pa)/Pa < 0.05, status = "NEAR perfectly-expanded";
else, status = "OVER-expanded (pe < Pa)";
end

%% ---------------- Plots ----------------
figure('Color','w','Position',[80 80 1180 740]);

% (1) Nozzle profile + Mach coloured centerline
subplot(2,2,1);
hold on; box on; grid on;
% draw filled half-profile
xp = [x, fliplr(x)];  yp = [r, -fliplr(r)];
fill(xp*1e3, yp*1e3, [0.95 0.95 0.98], 'EdgeColor',[0.4 0.4 0.4]);
% colour Mach along centreline
scatter(x*1e3, zeros(size(x)), 14, M, 'filled'); colormap(turbo); c = colorbar;
c.Label.String = 'Mach number';
xlabel('Axial position x [mm]'); ylabel('Radius r [mm]');
title(sprintf('Nozzle geometry (\\theta_c = %.1f^\\circ, \\theta_d = %.1f^\\circ)', ...
      rad2deg(theta_c), rad2deg(theta_d)));

% Mach
subplot(2,2,2);
plot(x*1e3, M,'LineWidth',1.9);
xlabel('x [mm]'); ylabel('M'); grid on; title('Mach distribution');

% Pressure
subplot(2,2,3);
plot(x*1e3, p/1e5,'LineWidth',1.9);
xlabel('x [mm]'); ylabel('p [bar]'); grid on; title('Static pressure');

% Velocity
subplot(2,2,4);
plot(x*1e3, V,'LineWidth',1.9);
xlabel('x [mm]'); ylabel('V [m/s]'); grid on; title('Velocity');

sgtitle(sprintf('mdot = %.3f g/s | Me = %.2f | Ve = %.0f m/s | pe = %.2f bar | Thrust = %.2f N | %s', ...
        mdot*1e3, Me, Ve, pe/1e5, Thrust, status));

%% ---------------- Thrust vs diverging angle ----------------
theta_d_list = deg2rad(linspace(6,20,20));
Th = zeros(size(theta_d_list));
for k = 1:numel(theta_d_list)
    re_k = rt + Ldiv*tan(theta_d_list(k));
    A_d  = [A(1:find(x>=Lthroat,1)-1), pi*(rt + (re_k-rt)*((x_d - Lthroat)/Ldiv)).^2];
    A_d  = [A_d(1:numel(x))];  % align length
    Th(k)= thrust_from_profile(A_d, x, Astar, gamma, R, Pc, Tc, Pa);
end

figure('Color','w');
plot(rad2deg(theta_d_list), Th,'-o','LineWidth',1.8);
xlabel('Diverging half-angle \theta_d [deg]'); ylabel('Thrust [N]');
title('Thrust vs Diverging Angle (converging angle fixed)'); grid on;

%% ---------------- Angle Sweep ----------------
makeGIF = true;  % set true if you want a GIF saved
if makeGIF
    fname = 'nozzle_sweep.gif';
    for td = deg2rad(6:1:20)
        re_k = rt + Ldiv*tan(td);
        A_d  = [A(1:find(x>=Lthroat,1)-1), pi*(rt + (re_k-rt)*((x_d - Lthroat)/Ldiv)).^2];
        A_d  = [A_d(1:numel(x))];
        [~, ~, ~, ~, M_gif, p_gif, V_gif] = flow_along(A_d, x, Astar, gamma, R, Pc, Tc, Pa);
        r_gif = sqrt(A_d/pi);
        figure(99); clf; set(gcf,'Color','w','Position',[100 100 700 380]);
        subplot(1,2,1);
        fill([x, fliplr(x)]*1e3, [r_gif, -fliplr(r_gif)]*1e3, [0.95 0.95 0.98], 'EdgeColor',[0.4 0.4 0.4]); hold on; grid on;
        scatter(x*1e3, zeros(size(x)), 12, M_gif, 'filled'); colormap(turbo); colorbar; caxis([0 3]);
        xlabel('x [mm]'); ylabel('r [mm]');
        title(sprintf('\\theta_d = %.1f^\\circ', rad2deg(td)));
        subplot(1,2,2);
        yyaxis left; plot(x*1e3, p_gif/1e5,'LineWidth',1.6); ylabel('p [bar]'); grid on;
        yyaxis right; plot(x*1e3, V_gif,'LineWidth',1.6); ylabel('V [m/s]');
        xlabel('x [mm]'); title('p & V profiles');
        drawnow;
        frame = getframe(gcf);
        [im,map] = rgb2ind(frame2im(frame),256);
        if td==deg2rad(6)
            imwrite(im,map,fname,'gif','LoopCount',inf,'DelayTime',0.12);
        else
            imwrite(im,map,fname,'gif','WriteMode','append','DelayTime',0.12);
        end
    end
end

%% ---------------- Functions ----------------
function M = mach_from_area(AR, gamma, branch)
    % Invert area–Mach via Newton iteration. 'sub' or 'sup' branch.
    if strcmp(branch,'sub'), M = 0.2; else, M = 2.0; end
    for it=1:60
        term = 1 + (gamma-1)/2*M^2;
        f  = (1/M) * ( (2/(gamma+1))*term )^((gamma+1)/(2*(gamma-1))) - AR;
        df = -(1/M^2) * ( (2/(gamma+1))*term )^((gamma+1)/(2*(gamma-1))) ...
             + (1/M) * ( (2/(gamma+1))*term )^((gamma+1)/(2*(gamma-1))) ...
               * ((gamma+1)/(2*(gamma-1))) * ((gamma-1)*M/term);
        Mnew = M - f/df;
        if strcmp(branch,'sub') && Mnew>=1, Mnew = 0.999; end
        if strcmp(branch,'sup') && Mnew<=1, Mnew = 1.001; end
        if abs(Mnew-M) < 1e-10, M = Mnew; return; end
        M = Mnew;
    end
end

function Th = thrust_from_profile(A, x, Astar, gamma, R, Pc, Tc, Pa)
    [mdot, Ve, pe, Ae] = exit_from_profile(A, x, Astar, gamma, R, Pc, Tc, Pa);
    Th = mdot*Ve + (pe - Pa)*Ae;
end

function [mdot, Ve, pe, Ae, Me, M, p, V] = exit_from_profile(A, x, Astar, gamma, R, Pc, Tc, Pa)
    % M(x)
    M = zeros(size(A));
    Lth = x(find(x==min(abs(x-0)),1));

    for i = 1:numel(A)
        AR = A(i)/Astar;
        if x(i) < 0
            M(i) = mach_from_area(AR, gamma, 'sub');
        else
            if A(i) == Astar, M(i) = 1; else, M(i) = mach_from_area(AR, gamma, 'sup'); end
        end
    end
    % mdot (choked)
    mdot = Astar * Pc * sqrt(gamma/(R*Tc)) * (2/(gamma+1))^((gamma+1)/(2*(gamma-1)));
    % properties
    T = Tc ./ (1 + (gamma-1)/2 .* M.^2);
    p = Pc .* (T./Tc).^(gamma/(gamma-1));
    V = M .* sqrt(gamma*R.*T);
    Ae = A(end); Me = M(end); pe = p(end); Ve = V(end);
end

function [mdot, Me, pe, Ve, M, p, V] = flow_along(A, x, Astar, gamma, R, Pc, Tc, Pa)
    [mdot, Ve, pe, Ae, Me, M, p, V] = exit_from_profile(A, x, Astar, gamma, R, Pc, Tc, Pa); %#ok<ASGLU>
end
