%% Nonlinear Verification of the Grid-Code Stability Condition
% This script validates the main theoretical conclusion using the nonlinear
% EMTSimulator-based DAE model.
%
% Workflow:
% 1) Construct the element/network lists from a MATPOWER case, with all
%    non-connection buses mapped to VSG devices.
% 2) Reconstruct the network synchronization-reversal metric Hnet and obtain
%    the minimum stability requirement.
% 3) Compare two scenarios:
%       (i)  parameters violating the grid-code condition,
%      (ii)  parameters satisfying the grid-code condition.
% 4) Perform small-signal analysis and nonlinear transient simulation for
%    both scenarios, then visualize bus-angle and bus-voltage trajectories.

clear; clc; close all;
tic;

%% User configuration
casename = 'case39';
loadscaling = 1.0;
powerTol = 1e-6;

elementName = ['ElementList_', casename, '_AllVSG'];
networkName = ['Network_netY_', casename, '_AllVSG'];

%% Build from MATPOWER: map all non-connection nodes to VSG
mpc = loadcase(casename);
mpc.bus(:, [3, 4]) = mpc.bus(:, [3, 4]) * loadscaling;

try
    mpopt = mpoption('verbose', 0, 'out.all', 0);
catch
    mpopt = [];
end

[override, pfRes] = buildAllVsgOverride(mpc, powerTol, mpopt);

opts = struct();
opts.powerTol = powerTol;
opts.elementName = elementName;
opts.networkName = networkName;
opts.mpopt = mpopt;

buildOut = funcBuildFromMatpower(mpc, override, opts);
fprintf("================================================================\n")
fprintf('Case: %s, loadscaling = %.3f\n', casename, loadscaling);
fprintf('Built files: %s, %s\n', buildOut.elementName, buildOut.networkName);

%% Initialize simulator data structures
funcInitialization(networkName, elementName);

%% Compute Hnet and the associated stability threshold from power-flow data
[Hnet, Hnet_schur, minEigHnet] = buildHnetFromPf(pfRes, override);
threshold = -minEigHnet;

fprintf('Minimal network reversal: min(eig(Hnet)) = %.6f\n', minEigHnet);
fprintf('Minimal stability threshold: -min(eig(Hnet)) + 0.05 = %.6f\n', threshold+0.05);
fprintf("================================================================\n")

%% Compute the equilibrium point (used as initialization for both cases)
[state0_init, state0_flag_init] = funcSteady();

%% Case I: Parameters violating the grid-code condition
d_bad = threshold - 0.1;
k_bad = threshold - 0.1;

applyVSG_para_adjust(d_bad, k_bad);

funcRewriteEquilibrium(state0_init);

res_bad = runOneScenario('Violation scenario', state0_init, state0_flag_init);

%% Case II: Parameters satisfying the grid-code condition
d_fix = threshold + 0.1;
k_fix = threshold + 0.1;

applyVSG_para_adjust(d_fix, k_fix);

funcRewriteEquilibrium(state0_init);

res_fix = runOneScenario('Adjusted scenario', state0_init, state0_flag_init);

%% Visualization of nonlinear trajectories
global te;

figure(1);
subplot(2,2,1);
plot(res_bad.t, res_bad.angDeg, 'LineWidth', 1.0); grid on;
title('Violation scenario: bus angles');
xlabel('t (s)'); ylabel('Angle (deg)'); xlim([0, te])
subplot(2,2,2);
plot(res_fix.t, res_fix.angDeg, 'LineWidth', 1.0); grid on;
title('Adjusted scenario: bus angles');
xlabel('t (s)'); ylabel('Angle (deg)'); xlim([0, te])

subplot(2,2,3);
plot(res_bad.t, res_bad.vol, 'LineWidth', 1.0); grid on;
title('Violation scenario: bus voltages');
xlabel('t (s)'); ylabel('Voltage (p.u.)'); xlim([0, te])
subplot(2,2,4);
plot(res_fix.t, res_fix.vol, 'LineWidth', 1.0); grid on;
title('Adjusted scenario: bus voltages');
xlabel('t (s)'); ylabel('Voltage (p.u.)'); xlim([0, te])

toc;

%% Local functions
function [override, pfRes] = buildAllVsgOverride(mpc, powerTol, mpopt)
    % Build bus-wise device overrides from solved net injections.
    % Rule: non-connection buses are mapped to VSG; zero-injection buses
    %       are retained as Cnct.
    if ~isempty(mpopt)
        [pfRes, success] = runpf(mpc, mpopt);
    else
        [pfRes, success] = runpf(mpc);
    end
    if ~success
        error('buildAllVsgOverride:RunpfFailed', 'runpf did not converge.');
    end

    nBus = size(pfRes.bus, 1);
    override = strings(nBus, 1);

    busIds = pfRes.bus(:, 1);
    busMap = containers.Map('KeyType', 'double', 'ValueType', 'double');
    for ii = 1:nBus
        busMap(busIds(ii)) = ii;
    end

    % online generator buses
    onlineGenAtBus = false(nBus, 1);
    for gg = 1:size(pfRes.gen, 1)
        if pfRes.gen(gg, 8) <= 0
            continue;
        end
        gBus = pfRes.gen(gg, 1);
        if isKey(busMap, gBus)
            onlineGenAtBus(busMap(gBus)) = true;
        end
    end

    % net injection from solved V,Y
    [Ybus, ~, ~] = makeYbus(pfRes);
    Vm = pfRes.bus(:, 8);
    Va = pfRes.bus(:, 9) * pi / 180;
    V = Vm .* exp(1j * Va);
    SInj = V .* conj(full(Ybus) * V);
    PInj = real(SInj);
    QInj = imag(SInj);

    for ii = 1:nBus
        if onlineGenAtBus(ii) || abs(PInj(ii)) > powerTol || abs(QInj(ii)) > powerTol
            override(ii) = "VSG";
        else
            override(ii) = "Cnct";
        end
    end
end

function [Hnet, Hnet_schur, minEigHnet] = buildHnetFromPf(pfRes, override)
    % Reconstruct reduced admittance by Kron reduction over connection buses,
    % then build Hnet and its Schur complement representation.
    [Ybus, ~, ~] = makeYbus(pfRes);
    Yfull = full(Ybus);
    devIdx = find(override == "VSG");
    cIdx = find(override == "Cnct");

    if isempty(cIdx)
        Yre = Yfull(devIdx, devIdx);
    else
        Ydd = Yfull(devIdx, devIdx);
        Ydc = Yfull(devIdx, cIdx);
        Ycd = Yfull(cIdx, devIdx);
        Ycc = Yfull(cIdx, cIdx);

        % Use pinv for robustness when Ycc is ill-conditioned.
        Yre = Ydd - Ydc * pinv(Ycc) * Ycd;
    end

    netB_re = imag(Yre);

    bus_As = pfRes.bus(:, 9) * pi / 180;
    bus_Vs = pfRes.bus(:, 8);
    dev_As = bus_As(devIdx);
    dev_Vs = bus_Vs(devIdx);

    dev_num = numel(devIdx);
    [Hnet, Hnet_schur] = HnetSchurGeneration(dev_num, dev_As, dev_Vs, netB_re);

    eigH = eig((Hnet + Hnet.') / 2);
    minEigHnet = min(real(eigH));
end

function applyVSG_para_adjust(dVal, kVal)
    % Apply grid-code parameters to all VSG units.
    % d is mapped directly to VSG.D.
    % k is enforced via 1/k = (xd - xdp), implemented by uniform scaling
    % of (xd, xdp) to preserve their relative proportion.
    global type VSG;

    if abs(kVal) < 1e-6
        error('applyVSG_para_adjust:InvalidK', 'k is too close to zero for xdp mapping.');
    end

    targetDelta = 1 / kVal;

    for ii = 1:numel(type)
        if strcmp(type{ii}, 'VSG')
            VSG{ii}.D = dVal;

            currentDelta = VSG{ii}.xd - VSG{ii}.xdp;
            if abs(currentDelta) < 1e-10
                error('applyVSG_para_adjust:InvalidXdPair', ...
                    'VSG{%d} has xd-xdp too small for scaling.', ii);
            end

            scaleRatio = targetDelta / currentDelta;
            VSG{ii}.xd = VSG{ii}.xd * scaleRatio;
            VSG{ii}.xdp = VSG{ii}.xdp * scaleRatio;
        end
    end

    fprintf('\nApplied to all VSG parameters by minimal grid codes: d=%.6f, k=%.6f\n', dVal, kVal);
end

function res = runOneScenario(tag, state0, state0_flag)
    % Run linearization + nonlinear transient simulation for one scenario.
    % Angles are reported in degrees with respect to refPos.
    global refPos;
    Jac = funcLinearization(state0, 'ODE');
    eigJac = eig(Jac);

    [t, state, transient_flag] = funcTransient(state0, state0_flag);
    ang = funcSearch(state, {'Angle'});
    vol = funcSearch(state, {'Voltage'});

    if isempty(refPos) || refPos < 1 || refPos > size(ang, 2)
        error('runOneScenario:InvalidRefPos', 'refPos is out of angle channel range.');
    end
    angDeg = 180 / pi * (ang - ang(:, refPos));

    fprintf("\n\n================================================================\n")
    fprintf('Scenario: %s\n', tag);
    fprintf('steady_exitflag = %d, transient_exitflag = %d\n', state0_flag, transient_flag);
    fprintf('max real eig(Jac) = %.6f\n', max(real(eigJac)));
    fprintf("================================================================\n\n\n")

    res = struct();
    res.t = t;
    res.state = state;
    res.ang = ang;
    res.angDeg = angDeg;
    res.vol = vol;
    res.maxRealEig = max(real(eigJac));
    res.eigJac = eigJac;
end

function [Hnet, Hnet_schur] = HnetSchurGeneration(dev_num, dev_As, dev_Vs, netB_re)
    % Construct Hnet and its Schur complement from bus-level operating point.
    matA = zeros(dev_num, dev_num);
    matC = zeros(dev_num, dev_num);
    matD = zeros(dev_num, dev_num);

    for ii = 1:dev_num
        for jj = 1:dev_num
            if ii ~= jj
                matA(ii, jj) = -netB_re(ii, jj) * dev_Vs(ii) * dev_Vs(jj) * cos(dev_As(ii)-dev_As(jj));
            end
        end
        matA(ii, ii) = -sum(matA(ii, :));
    end

    for ii = 1:dev_num
        for jj = 1:dev_num
            if ii ~= jj
                matC(ii, jj) = -netB_re(ii, jj) * cos(dev_As(ii)-dev_As(jj));
            else
                matC(ii, ii) = -netB_re(ii, ii);
            end
        end
    end

    for ii = 1:dev_num
        for jj = 1:dev_num
            if ii ~= jj
                matD(ii, jj) = netB_re(ii, jj) * dev_Vs(ii) * sin(dev_As(ii)-dev_As(jj));
            end
        end
    end
    for ii = 1:dev_num
        matD(ii, ii) = -sum(matD(:, ii));
    end

    Hnet = [matA, matD; matD', matC];
    Hnet_schur = matC - matD.' * pinv(matA) * matD;
end
