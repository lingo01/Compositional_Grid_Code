function funcRewriteEquilibrium(stateEq)
% Rewrite device setpoints using steady-state equilibrium values.
% Usage:
%   [state0, ~] = funcSteady();
%   funcRewriteEquilibrium(state0);

    global type nNet;
    global Gen VSG CDInv QDInv;
    global SG_reactance_flag;

    if nargin < 1 || isempty(stateEq)
        [stateEq, stateEq_calcflag] = funcSteady();
    end

    if size(stateEq, 1) ~= 1
        if size(stateEq, 2) == 1
            stateEq = stateEq';
        else
            error('funcRewriteEquilibrium:InvalidInput', 'stateEq must be a single equilibrium state row/column vector.');
        end
    end

    ang0 = funcSearch(stateEq, "Angle");
    vol0 = funcSearch(stateEq, "Voltage");
    P0 = funcSearch(stateEq, "P");
    Q0 = funcSearch(stateEq, "Q");

    for ii = 1:nNet
        t = char(string(type{ii}));

        if strcmp(t, 'CDInv')
            CDInv{ii}.As = ang0(ii);
            CDInv{ii}.Vs = vol0(ii);
            CDInv{ii}.Ps = P0(ii);
            CDInv{ii}.Qs = Q0(ii);
        elseif strcmp(t, 'QDInv')
            QDInv{ii}.As = ang0(ii);
            QDInv{ii}.Vs = vol0(ii);
            QDInv{ii}.Ps = P0(ii);
            QDInv{ii}.Qs = Q0(ii);
        elseif strcmp(t, 'VSG')
            if abs(vol0(ii)) < 1e-12
                error('funcRewriteEquilibrium:ZeroVoltage', 'Node %d voltage is too close to zero.', ii);
            end
            VSG{ii}.Pm = P0(ii);
            VSG{ii}.Ef = vol0(ii) + (VSG{ii}.xd - VSG{ii}.xdp) * Q0(ii) / vol0(ii);
            % fprintf('%.6f\n', VSG{ii}.Ef)
        elseif strcmp(t, 'Gen')
            if SG_reactance_flag == 0
                error('funcRewriteEquilibrium:SGReactanceFlag', ...
                    'Gen rewrite requires SG_reactance_flag == 1.');
            end
            if abs(vol0(ii)) < 1e-12
                error('funcRewriteEquilibrium:ZeroVoltage', 'Node %d voltage is too close to zero.', ii);
            end
            Gen{ii}.Pm = P0(ii);
            Gen{ii}.Ef = vol0(ii) + (Gen{ii}.xd - Gen{ii}.xdp) * Q0(ii) / vol0(ii);
        end
    end
end
