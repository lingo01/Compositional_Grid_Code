function funcSaveElement(filename)
% Save element settings to an Excel file using the inverse format of settingElement.
    global Info Gen VSG CDInv QDInv PLLInv Load;
    global type nNet SG_reactance_flag;

    if nargin < 1 || isempty(filename)
        error('funcSaveElement:InvalidInput', 'filename is required.');
    end

    outFile = ['./data&figure/', filename, '.xlsx'];
    headers = {'Node', 'Type', 'Code', 'Para1', 'Para2', 'Para3', 'Para4', 'Para5', 'Para6', 'Para7', 'Para8', 'Para9'};

    rows = buildRowsFromGlobals(type, nNet, Gen, VSG, CDInv, QDInv, PLLInv, Load);

    % Fallback: if type/nNet is unavailable, try to export directly from Info.
    if isempty(rows)
        rows = buildRowsFromInfo(Info);
    end

    if SG_reactance_flag == 1
        marker = 'with SG reactance';
    else
        marker = 'without SG reactance';
    end

    % Row 1 must be headers; row 2 is the SG reactance marker row.
    raw = cell(size(rows, 1) + 2, numel(headers));
    raw(:) = {[]};
    raw(1, :) = headers;
    raw{2, 1} = marker;
    if ~isempty(rows)
        raw(3:end, :) = rows;
    end

    writecell(raw, outFile);
end

function rows = buildRowsFromGlobals(type, nNet, Gen, VSG, CDInv, QDInv, PLLInv, Load)
    rows = {};

    if isempty(type) || isempty(nNet)
        return;
    end

    for rr = 1:nNet
        if rr > numel(type) || isempty(type{rr})
            continue;
        end

        t = char(string(type{rr}));
        if strcmp(t, 'Cnct')
            continue;
        end

        para = nan(1, 9);
        if strcmp(t, 'Gen')
            if rr <= numel(Gen) && ~isempty(Gen{rr})
                para(1) = getFieldOrNaN(Gen{rr}, 'M');
                para(2) = getFieldOrNaN(Gen{rr}, 'D');
                para(3) = getFieldOrNaN(Gen{rr}, 'Td');
                para(4) = getFieldOrNaN(Gen{rr}, 'xd');
                para(5) = getFieldOrNaN(Gen{rr}, 'xdp');
                para(6) = getFieldOrNaN(Gen{rr}, 'Pm');
                para(7) = getFieldOrNaN(Gen{rr}, 'Ef');
            end
        elseif strcmp(t, 'VSG')
            if rr <= numel(VSG) && ~isempty(VSG{rr})
                para(1) = getFieldOrNaN(VSG{rr}, 'M');
                para(2) = getFieldOrNaN(VSG{rr}, 'D');
                para(3) = getFieldOrNaN(VSG{rr}, 'Td');
                para(4) = getFieldOrNaN(VSG{rr}, 'xd');
                para(5) = getFieldOrNaN(VSG{rr}, 'xdp');
                para(6) = getFieldOrNaN(VSG{rr}, 'Pm');
                para(7) = getFieldOrNaN(VSG{rr}, 'Ef');
            end
        elseif strcmp(t, 'CDInv')
            if rr <= numel(CDInv) && ~isempty(CDInv{rr})
                para(1) = getFieldOrNaN(CDInv{rr}, 't1');
                para(2) = getFieldOrNaN(CDInv{rr}, 't2');
                para(3) = getFieldOrNaN(CDInv{rr}, 'As');
                para(4) = getFieldOrNaN(CDInv{rr}, 'Vs');
                para(5) = getFieldOrNaN(CDInv{rr}, 'Ps');
                para(6) = getFieldOrNaN(CDInv{rr}, 'Qs');
                para(7) = getFieldOrNaN(CDInv{rr}, 'D1');
                para(8) = getFieldOrNaN(CDInv{rr}, 'D2');
            end
        elseif strcmp(t, 'QDInv')
            if rr <= numel(QDInv) && ~isempty(QDInv{rr})
                para(1) = getFieldOrNaN(QDInv{rr}, 't1');
                para(2) = getFieldOrNaN(QDInv{rr}, 't2');
                para(3) = getFieldOrNaN(QDInv{rr}, 'As');
                para(4) = getFieldOrNaN(QDInv{rr}, 'Vs');
                para(5) = getFieldOrNaN(QDInv{rr}, 'Ps');
                para(6) = getFieldOrNaN(QDInv{rr}, 'Qs');
                para(7) = getFieldOrNaN(QDInv{rr}, 'D1');
                para(8) = getFieldOrNaN(QDInv{rr}, 'D2');
            end
        elseif strcmp(t, 'PLLInv')
            if rr <= numel(PLLInv) && ~isempty(PLLInv{rr})
                para(1) = getFieldOrNaN(PLLInv{rr}, 'Ki');
                para(2) = getFieldOrNaN(PLLInv{rr}, 'Kp');
                para(3) = getFieldOrNaN(PLLInv{rr}, 'tau1');
                para(4) = getFieldOrNaN(PLLInv{rr}, 'Ps');
                para(5) = getFieldOrNaN(PLLInv{rr}, 'D1');
                para(6) = getFieldOrNaN(PLLInv{rr}, 'tau2');
                para(7) = getFieldOrNaN(PLLInv{rr}, 'Qs');
                para(8) = getFieldOrNaN(PLLInv{rr}, 'Vs');
                para(9) = getFieldOrNaN(PLLInv{rr}, 'D2');
            end
        elseif strcmp(t, 'Load')
            if rr <= numel(Load) && ~isempty(Load{rr})
                para(1) = getFieldOrNaN(Load{rr}, 'Ps');
                para(2) = getFieldOrNaN(Load{rr}, 'Qs');
            end
        else
            error('funcSaveElement:UnknownType', 'Unknown element type at node %d: %s', rr, t);
        end

        rows(end + 1, :) = [{rr, t, ''}, num2cell(para)]; %#ok<AGROW>
    end
end

function rows = buildRowsFromInfo(Info)
    rows = {};

    if isempty(Info) || ~istable(Info)
        return;
    end

    varNames = Info.Properties.VariableNames;
    needed = {'Node', 'Type'};
    if ~all(ismember(needed, varNames))
        return;
    end

    nRows = height(Info);
    rows = cell(nRows, 12);

    for ii = 1:nRows
        rows{ii, 1} = getTableValue(Info, ii, 'Node');
        rows{ii, 2} = char(string(getTableValue(Info, ii, 'Type')));
        if ismember('Code', varNames)
            codeVal = getTableValue(Info, ii, 'Code');
            if isempty(codeVal)
                rows{ii, 3} = '';
            else
                rows{ii, 3} = char(string(codeVal));
            end
        else
            rows{ii, 3} = '';
        end

        for kk = 1:9
            paraName = ['Para', num2str(kk)];
            if ismember(paraName, varNames)
                rows{ii, kk + 3} = getTableValue(Info, ii, paraName);
            else
                rows{ii, kk + 3} = NaN;
            end
        end
    end
end

function v = getFieldOrNaN(s, fieldName)
    if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
        v = s.(fieldName);
    else
        v = NaN;
    end
end

function v = getTableValue(T, rowIdx, varName)
    v = T{rowIdx, varName};
    if iscell(v)
        v = v{1};
    end
end
