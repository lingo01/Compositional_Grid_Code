%% To generate Figure 3 of this paper:

% 1): to simulate system dynamics under varied operation situations
%     change loadscaling (Line 15) 

% 2): to simulate system dynamics with or without stability grid code
%     comment or uncomment k_des (Line 42)


%%
clear all; clc; close all;
tic;
%%  system configuration
casename = 'case118';   % following the name of MATPOWER standard test benckmark
loadscaling = 1.2;  % load scaling factor: rho_load in the paper

% dynamics code
M_des = 0.3;
d_des = 0.6;
tau_des = 0.1;
k_des = 0.5;

% stability code
stability_code_flag = 1; % enable/disable stability code flag = 1/0

%% RUN the following function if you want to verified on other systems
% To use this function, make sure you have installed MATPOWER: See https://matpower.org for install instruction.
% func_Hnet_generator(casename, 1, loadscaling); 

%% network matrix
load(strcat('./data&figure/Hnet_info_', casename, '_loadscaling', num2str(loadscaling), '.mat'));
Hnet = Hnet_info.Hnet;

% network synchronization reversal
dev_num = size(Hnet,1)/2;

A = Hnet(1:dev_num, 1:dev_num);
D = Hnet(1:dev_num, dev_num+1:end);
C = Hnet(dev_num+1:end, dev_num+1:end);

sigma_n = min(eig(C - D.'*pinv(A)*D));

%% stability grid code
if stability_code_flag == 1
    d_des = max(-sigma_n + 0.05, d_des); 
    k_des = max(-sigma_n + 0.05, k_des); 
end

%% device ID
dev_info = Hnet_info.dev_info;

%% closed-loop transfer function

% for devices: 
% dx/dt = A*x + B1*sref + B2*s
% y = Cx

% x = [theta, omega, V], sref = [Pref, Qref/Vref], s = [P, Q/V], y = [theta, V]
% A = [0,  1,  0;  0,  -d/M,  0;  0,  0,  -k/tau]
% B1 = [0,  0;  1/M,  0;  0,   1/tau]
% B2 = [0,  0;  -1/M,  0;  0,  -1/tau]
% C = [1,  0,  0;  0,  0,  1];

matA = zeros(3*dev_num, 3*dev_num);
matB2 = zeros(3*dev_num, 2*dev_num);

for ii = 1:dev_num
        kk = find(dev_info.dev.ID(ii)==dev_info.gen.ID);
        matA(0*dev_num+ii, 1*dev_num+ii) = 1;
        matA(1*dev_num+ii, 1*dev_num+ii) = -d_des / M_des;
        matA(2*dev_num+ii, 2*dev_num+ii) = -k_des / tau_des;

        matB2(1*dev_num+ii, 0*dev_num+ii) = -1 / M_des;
        matB2(2*dev_num+ii, 1*dev_num+ii) = -1 / tau_des;
end

matB1 = -matB2;

matC = zeros(size(Hnet,1), size(matA,1));
matC(1:size(Hnet,1)/2, 1:size(matA,1)/3) = eye(size(Hnet,1)/2);
matC(size(Hnet,1)/2+1:end, (size(matA,1)*2/3+1):end) = eye(size(Hnet,1)/2);

% closed-loop system dynamic matrix
matAc = matA + matB2 * Hnet * matC;

% frequency-voltage output matrix
matOut = zeros(size(Hnet,1), size(matA,1));
matOut(1:size(Hnet,1)/2, (size(matA,1)/3+1):(size(matA,1)*2/3)) = eye(size(Hnet,1)/2);
matOut(size(Hnet,1)/2+1:end, (size(matA,1)*2/3+1):end) = eye(size(Hnet,1)/2);


%% simluation: from Ps,Qs to frequency, V

disturb_dir = 10;     % disturbance power direction (P/Q=tan(dir))
disturb_amp = 0.05;  % disturbance power amplitude

dt_sim = 0.01;
t_sim = 0:dt_sim:10;

disturb = -disturb_amp * [cos(disturb_dir/180*pi)*ones(size(Hnet,1)/2,1); sin(disturb_dir/180*pi)*ones(size(Hnet,1)/2,1)];
disturb_seq = ones(length(t_sim), 1) * disturb';

sys_cl = ss(matAc, matB1, matOut, 0*eye(2*dev_num));
[state, t_sim] = lsim(sys_cl, disturb_seq, t_sim);

freq = state(:, 1:size(Hnet,1)/2);
vol = state(:, size(Hnet,1)/2+1:end);

%% plot
figure(1); 
plot(t_sim(1:1:end), freq(1:1:end,:), 'LineWidth', 1.0);

% if stability_code_flag == 1
%     exportgraphics(gcf, ['simulation_', casename, '_withCode_loadscaling', num2str(loadscaling), '.emf'], 'ContentType', 'vector');
% else
%     exportgraphics(gcf, ['simulation_', casename, '_withoutCode_loadscaling', num2str(loadscaling), '.emf'], 'ContentType', 'vector');
% end