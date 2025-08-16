% lqr_pendulum_example.m
% Prototype framework LQR stabilisation for an inverted pendulum (cart–pole) scenario.
% By Brilliant G Purnawan

clear; clc; close all;

%% Parameters (Based on Experimental Variables)
M  = 0.635;     % cart mass [kg]
m  = 0.25;     % pendulum mass [kg]
l  = 0.5;     % pendulum length to CoM [m]
g  = 9.81;    % gravity [m/s^2]

% State vector: x = [cart_pos; cart_vel; pend_angle; pend_ang_vel]
% Linearised around upright (theta ~ 0 rad)
A = [ 0, 1, 0, 0;
      0, 0, (m*g)/M, 0;
      0, 0, 0, 1;
      0, 0, (g*(M+m))/(M*l), 0 ];

B = [ 0;
      1/M;
      0;
      1/(M*l) ];

% Outputs (for plotting): cart position and pendulum angle
C = [1 0 0 0;
     0 0 1 0];
D = zeros(2,1);

%% LQR design
% Tune Q and R to trade off cart position vs. pendulum angle and control effort.
Q = diag([40, 1, 200, 1]);   % penalise theta (state 3) and cart pos (state 1) more
R = 0.5;                     % control effort penalty

% LQR gain
K = lqr(A, B, Q, R);

% Closed-loop system: x_dot = (A - B*K) x
Acl = A - B*K;
sys_cl = ss(Acl, B, C, D);

%% Simulation from a small initial error
t  = 0:0.002:5;              % 5 seconds
x0 = [0.05; 0; 0.15; 0];     % 5 cm cart offset, 0.15 rad

% Simulate response to initial condition
[y, t_out, x] = initial(sys_cl, x0, t);

cart_pos   = y(:,1);
pend_angle = y(:,2);

%% Plots
figure('Color','w','Position',[100 100 900 360]);

subplot(1,2,1);
plot(t_out, cart_pos, 'LineWidth',1.8);
xlabel('Time [s]'); ylabel('Cart Position x [m]');
title('Cart Position (Closed-Loop LQR)');
grid on;

subplot(1,2,2);
plot(t_out, pend_angle, 'LineWidth',1.8);
xlabel('Time [s]'); ylabel('Pendulum Angle \theta [rad]');
title('Pendulum Angle (Closed-Loop LQR)');
grid on;

sgtitle('LQR Stabilisation of Inverted Pendulum (Prototype)');
