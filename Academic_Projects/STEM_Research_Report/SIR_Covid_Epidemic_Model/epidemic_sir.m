% Minimal SIR simulation, without vaccination considerations done in the paper
% Parameters and initial conditions used are approximate data from Jakarta at that time.
% By Brilliant G Purnawan

clear; clc; close all;

%% --- Parameters (per day) ---
beta  = 0.079;   % transmission rate
gamma = 0.023;   % recovery rate

%% --- Initial conditions (people) ---
N  = 10900000;     % total population (scales the y-axis)
I0 = 3000;        % initial infected
R0 = 0;         % initial recovered
S0 = N - I0 - R0;

y0 = [S0; I0; R0];

%% --- Time span (days) ---
t_end = 500;
tspan = [0 t_end];

%% --- SIR ODEs: dS/dt = -beta*S*I/N, dI/dt = beta*S*I/N - gamma*I, dR/dt = gamma*I
odefun = @(t,y) [ -beta * y(1) * y(2) / N; ...
                   beta * y(1) * y(2) / N - gamma * y(2); ...
                   gamma * y(2) ];

%% --- Integrate ---
opts = odeset('RelTol',1e-7,'AbsTol',1e-9);
[t, Y] = ode45(odefun, tspan, y0, opts);

S = Y(:,1); I = Y(:,2); R = Y(:,3);

%% --- Plot results ---
figure('Color','w','Position',[100 100 900 420]);
plot(t, S, 'LineWidth',1.8); hold on;
plot(t, I, 'LineWidth',1.8);
plot(t, R, 'LineWidth',1.8);
grid on; box on;
xlabel('Time [days]');
ylabel('People');
legend({'Susceptible','Infected','Recovered'}, 'Location','best');
title(sprintf('SIR Simulation (N = %.0f, \\beta = %.2f, \\gamma = %.2f, R_0 = %.2f)', ...
    N, beta, gamma, beta/gamma));

% Peak infection
[peakI, idx] = max(I);
t_peak = t(idx);
plot(t_peak, peakI, 'ko', 'MarkerFaceColor','k');
text(t_peak, peakI, sprintf(' Peak: %.0f @ %.0f d', peakI, t_peak), ...
    'VerticalAlignment','bottom','HorizontalAlignment','left');

tightfig();
saveas(gcf, 'sir_example.png');
