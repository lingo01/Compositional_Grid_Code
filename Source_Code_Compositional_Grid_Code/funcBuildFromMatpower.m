function out = funcBuildFromMatpower(mpc, deviceOverride, opts)
% Build EMTSimulator ElementList and Network_netY from a MATPOWER case struct.
% Usage:
%   mpc = loadcase('case118');
%   out = funcBuildFromMatpower(mpc);
%   out = funcBuildFromMatpower(mpc, strings(size(mpc.bus,1),1), struct('powerTol', 1e-5));
%
% Inputs:
%   mpc            : MATPOWER case struct.
%   deviceOverride : optional string/cellstr array in mpc.bus row order.
%                    Allowed values: Gen/VSG/CDInv/QDInv/PLLInv/Load/Cnct.
%                    Empty value means using default conversion rules.
%   opts           : optional struct with fields
%                    - powerTol      (default 1e-6)
%                    - elementName   (default 'ElementList_FromMATPOWER')
%                    - networkName   (default 'Network_netY_FromMATPOWER')
%                    - mpopt         (default mpoption('verbose',0,'out.all',0))
%
% Default conversion rules:
%   1) Online generator bus -> VSG
%   2) Non-generator bus with non-zero net injection (|P| or |Q| > tol) -> Load
%   3) Otherwise -> Cnct
%
% Notes:
%   - All powers are converted to per-unit by mpc.baseMVA.
%   - This function writes globals directly then calls funcSaveElement/funcSaveNetwork.

    if nargin < 2 || isempty(deviceOverride)
        deviceOverride = strings(0, 1);
    end
    if nargin < 3 || isempty(opts)
        opts = struct();
    end

    opts = parseOptions(opts);
    validateMpcInput(mpc);

    % MATPOWER power flow
    if isfield(opts, 'mpopt') && ~isempty(opts.mpopt)
        [pfRes, success] = runpf(mpc, opts.mpopt);
    else
        [pfRes, success] = runpf(mpc);
    end
    if ~success
        error('funcBuildFromMatpower:RunpfFailed', 'MATPOWER runpf did not converge.');
    end

    nBus = size(pfRes.bus, 1);
    override = normalizeOverride(deviceOverride, nBus);

    % Build bus-id -> local index mapping in mpc.bus row order.
    busIds = pfRes.bus(:, 1);
    busMap = containers.Map('KeyType', 'double', 'ValueType', 'double');
    for ii = 1:nBus
        busMap(busIds(ii)) = ii;
    end

    % Build Ybus via MATPOWER library function.
    [Ybus, ~, ~] = makeYbus(pfRes);
    netYLocal = full(Ybus);

    % Compute bus net injection from solved V and Ybus.
    Vm = pfRes.bus(:, 8);
    VaRad = pfRes.bus(:, 9) * pi / 180;
    V = Vm .* exp(1j * VaRad);
    SInj = V .* conj(netYLocal * V);
    PInj = real(SInj);
    QInj = imag(SInj);

    % Use mpc.gen only to identify online generator buses.
    baseMVA = pfRes.baseMVA;
    onlineGenAtBus = false(nBus, 1);

    nGen = size(pfRes.gen, 1);
    for gg = 1:nGen
        if pfRes.gen(gg, 8) <= 0
            continue;
        end
        gBusId = pfRes.gen(gg, 1);
        if ~isKey(busMap, gBusId)
            continue;
        end
        jj = busMap(gBusId);
        onlineGenAtBus(jj) = true;
    end

    % Globals expected by existing simulator functions.
    global Info type nNet netY netG netB;
    global Gen VSG CDInv QDInv PLLInv Load Cnct;
    global SG_reactance_flag;

    nNet = nBus;
    netY = netYLocal;
    netG = real(netY);
    netB = imag(netY);

    type = cell(1, nNet);
    Gen = cell(1, nNet);
    VSG = cell(1, nNet);
    CDInv = cell(1, nNet);
    QDInv = cell(1, nNet);
    PLLInv = cell(1, nNet);
    Load = cell(1, nNet);
    Cnct = cell(1, nNet);

    % netY is directly from MATPOWER makeYbus, without SG xdp folded in.
    SG_reactance_flag = 0;
    vsgDefault = struct('M', 0.30, 'D', 1.20, 'Td', 0.10, 'xd', 0.395, 'xdp', 0.315);

    for ii = 1:nBus
        desiredType = decideType(override(ii), onlineGenAtBus(ii), PInj(ii), QInj(ii), opts.powerTol);
        type{ii} = char(desiredType);

        if strcmp(desiredType, 'VSG')
            s = vsgDefault;
            s.Pm = PInj(ii);
            if abs(Vm(ii)) < 1e-12
                error('funcBuildFromMatpower:ZeroVoltage', 'Bus %d solved voltage is too close to zero.', ii);
            end
            % Use solved Q injection to seed Ef for equilibrium consistency.
            s.Ef = Vm(ii) + (s.xd - s.xdp) * QInj(ii) / Vm(ii);
            VSG{ii} = s;

        elseif strcmp(desiredType, 'Gen')
            s = vsgDefault;
            s.Pm = PInj(ii);
            if abs(Vm(ii)) < 1e-12
                error('funcBuildFromMatpower:ZeroVoltage', 'Bus %d solved voltage is too close to zero.', ii);
            end
            s.Ef = Vm(ii) + (s.xd - s.xdp) * QInj(ii) / Vm(ii);
            Gen{ii} = s;

        elseif strcmp(desiredType, 'Load')
            s = struct();
            s.Ps = PInj(ii);
            s.Qs = QInj(ii);
            Load{ii} = s;

        elseif strcmp(desiredType, 'CDInv')
            s = struct();
            s.t1 = 0.2;
            s.t2 = 0.2;
            s.As = VaRad(ii);
            s.Vs = Vm(ii);
            s.Ps = PInj(ii);
            s.Qs = QInj(ii);
            s.D1 = 0.5;
            s.D2 = 0.5;
            CDInv{ii} = s;

        elseif strcmp(desiredType, 'QDInv')
            s = struct();
            s.t1 = 0.2;
            s.t2 = 0.2;
            s.As = VaRad(ii);
            s.Vs = Vm(ii);
            s.Ps = PInj(ii);
            s.Qs = QInj(ii);
            s.D1 = 0.5;
            s.D2 = 0.5;
            QDInv{ii} = s;

        % elseif strcmp(desiredType, 'PLLInv')
        %     s = struct();
        %     s.Ki = 18.0;
        %     s.Kp = 600.0;
        %     s.tau1 = 0.05;
        %     s.Ps = PInj(ii);
        %     s.D1 = 2.0;
        %     s.tau2 = 0.05;
        %     s.Qs = QInj(ii);
        %     s.Vs = Vm(ii);
        %     s.D2 = 1.0;
        %     PLLInv{ii} = s;

        elseif strcmp(desiredType, 'Cnct')
            Cnct{ii} = 0;

        else
            error('funcBuildFromMatpower:UnknownType', 'Unknown target type at bus %d: %s', ii, desiredType);
        end
    end

    % Build an Info table in the same layout as ElementList for traceability.
    Info = buildInfoTable(type, Gen, VSG, CDInv, QDInv, PLLInv, Load);

    % Save files through existing helper functions.
    funcSaveElement(opts.elementName);
    funcSaveNetwork(opts.networkName);

    out = struct();
    out.elementName = opts.elementName;
    out.networkName = opts.networkName;
    out.nBus = nBus;
    out.baseMVA = baseMVA;
    out.type = string(type(:));
    out.busIds = busIds;
    out.PInj = PInj;
    out.QInj = QInj;
end

function opts = parseOptions(opts)
    if ~isfield(opts, 'powerTol') || isempty(opts.powerTol)
        opts.powerTol = 1e-6;
    end
    if ~isfield(opts, 'elementName') || isempty(opts.elementName)
        opts.elementName = 'ElementList_FromMATPOWER';
    end
    if ~isfield(opts, 'networkName') || isempty(opts.networkName)
        opts.networkName = 'Network_netY_FromMATPOWER';
    end
    if ~isfield(opts, 'mpopt') || isempty(opts.mpopt)
        try
            opts.mpopt = mpoption('verbose', 0, 'out.all', 0);
        catch
            opts.mpopt = [];
        end
    end
end

function validateMpcInput(mpc)
    if ~isstruct(mpc)
        error('funcBuildFromMatpower:InvalidInput', 'mpc must be a MATPOWER struct.');
    end
    required = {'bus', 'gen', 'branch', 'baseMVA'};
    for ii = 1:numel(required)
        if ~isfield(mpc, required{ii})
            error('funcBuildFromMatpower:MissingField', 'mpc.%s is required.', required{ii});
        end
    end
    if isempty(mpc.bus) || size(mpc.bus, 2) < 9
        error('funcBuildFromMatpower:InvalidBus', 'mpc.bus must have at least 9 columns.');
    end
    if isempty(mpc.branch) || size(mpc.branch, 2) < 11
        error('funcBuildFromMatpower:InvalidBranch', 'mpc.branch must have at least 11 columns.');
    end
    if isempty(mpc.gen) || size(mpc.gen, 2) < 8
        error('funcBuildFromMatpower:InvalidGen', 'mpc.gen must have at least 8 columns.');
    end
    if mpc.baseMVA <= 0
        error('funcBuildFromMatpower:InvalidBaseMVA', 'mpc.baseMVA must be positive.');
    end
end

function override = normalizeOverride(deviceOverride, nBus)
    allowed = ["Gen", "VSG", "CDInv", "QDInv", "PLLInv", "Load", "Cnct"];

    if isempty(deviceOverride)
        override = strings(nBus, 1);
        return;
    end

    override = string(deviceOverride(:));

    if numel(override) ~= nBus
        error('funcBuildFromMatpower:OverrideSize', ...
            'deviceOverride must have exactly %d entries (mpc.bus row order).', nBus);
    end

    for ii = 1:nBus
        if strlength(strtrim(override(ii))) == 0
            continue;
        end
        v = strip(override(ii));
        if ~any(strcmp(v, allowed))
            error('funcBuildFromMatpower:OverrideType', ...
                'Invalid override type at row %d: %s', ii, v);
        end
        override(ii) = v;
    end
end

function t = decideType(overrideType, isGenBus, pInj, qInj, tol)
    if strlength(strtrim(overrideType)) > 0
        t = char(overrideType);
        return;
    end

    if isGenBus
        t = 'VSG';
    elseif abs(pInj) > tol || abs(qInj) > tol
        t = 'Load';
    else
        t = 'Cnct';
    end
end

function Info = buildInfoTable(type, Gen, VSG, CDInv, QDInv, PLLInv, Load)
    nNet = numel(type);
    rows = {};

    for rr = 1:nNet
        t = char(string(type{rr}));
        if strcmp(t, 'Cnct')
            continue;
        end

        para = nan(1, 9);
        if strcmp(t, 'Gen')
            para(1) = getFieldOrNaN(Gen{rr}, 'M');
            para(2) = getFieldOrNaN(Gen{rr}, 'D');
            para(3) = getFieldOrNaN(Gen{rr}, 'Td');
            para(4) = getFieldOrNaN(Gen{rr}, 'xd');
            para(5) = getFieldOrNaN(Gen{rr}, 'xdp');
            para(6) = getFieldOrNaN(Gen{rr}, 'Pm');
            para(7) = getFieldOrNaN(Gen{rr}, 'Ef');
        elseif strcmp(t, 'VSG')
            para(1) = getFieldOrNaN(VSG{rr}, 'M');
            para(2) = getFieldOrNaN(VSG{rr}, 'D');
            para(3) = getFieldOrNaN(VSG{rr}, 'Td');
            para(4) = getFieldOrNaN(VSG{rr}, 'xd');
            para(5) = getFieldOrNaN(VSG{rr}, 'xdp');
            para(6) = getFieldOrNaN(VSG{rr}, 'Pm');
            para(7) = getFieldOrNaN(VSG{rr}, 'Ef');
        elseif strcmp(t, 'CDInv')
            para(1) = getFieldOrNaN(CDInv{rr}, 't1');
            para(2) = getFieldOrNaN(CDInv{rr}, 't2');
            para(3) = getFieldOrNaN(CDInv{rr}, 'As');
            para(4) = getFieldOrNaN(CDInv{rr}, 'Vs');
            para(5) = getFieldOrNaN(CDInv{rr}, 'Ps');
            para(6) = getFieldOrNaN(CDInv{rr}, 'Qs');
            para(7) = getFieldOrNaN(CDInv{rr}, 'D1');
            para(8) = getFieldOrNaN(CDInv{rr}, 'D2');
        elseif strcmp(t, 'QDInv')
            para(1) = getFieldOrNaN(QDInv{rr}, 't1');
            para(2) = getFieldOrNaN(QDInv{rr}, 't2');
            para(3) = getFieldOrNaN(QDInv{rr}, 'As');
            para(4) = getFieldOrNaN(QDInv{rr}, 'Vs');
            para(5) = getFieldOrNaN(QDInv{rr}, 'Ps');
            para(6) = getFieldOrNaN(QDInv{rr}, 'Qs');
            para(7) = getFieldOrNaN(QDInv{rr}, 'D1');
            para(8) = getFieldOrNaN(QDInv{rr}, 'D2');
        elseif strcmp(t, 'PLLInv')
            para(1) = getFieldOrNaN(PLLInv{rr}, 'Ki');
            para(2) = getFieldOrNaN(PLLInv{rr}, 'Kp');
            para(3) = getFieldOrNaN(PLLInv{rr}, 'tau1');
            para(4) = getFieldOrNaN(PLLInv{rr}, 'Ps');
            para(5) = getFieldOrNaN(PLLInv{rr}, 'D1');
            para(6) = getFieldOrNaN(PLLInv{rr}, 'tau2');
            para(7) = getFieldOrNaN(PLLInv{rr}, 'Qs');
            para(8) = getFieldOrNaN(PLLInv{rr}, 'Vs');
            para(9) = getFieldOrNaN(PLLInv{rr}, 'D2');
        elseif strcmp(t, 'Load')
            para(1) = getFieldOrNaN(Load{rr}, 'Ps');
            para(2) = getFieldOrNaN(Load{rr}, 'Qs');
        else
            error('funcBuildFromMatpower:UnknownTypeInInfo', ...
                'Unknown type while building Info: %s', t);
        end

        rows(end + 1, :) = [{rr, t, ''}, num2cell(para)]; %#ok<AGROW>
    end

    headers = {'Node', 'Type', 'Code', 'Para1', 'Para2', 'Para3', 'Para4', ...
               'Para5', 'Para6', 'Para7', 'Para8', 'Para9'};

    if isempty(rows)
        Info = cell2table(cell(0, numel(headers)), 'VariableNames', headers);
    else
        Info = cell2table(rows, 'VariableNames', headers);
    end
end

function v = getFieldOrNaN(s, fieldName)
    if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
        v = s.(fieldName);
    else
        v = NaN;
    end
end
