% 元件设置
function settingElement(filename)
    global type; 
    global Info Gen VSG CDInv QDInv PLLInv Load Cnct;
    global nNet;
    global SG_reactance_flag;

    if isempty(nNet) || nNet <= 0
        error('Initial error: settingNetwork error');
    end
    
    type = {};
    
    filePath = ['./data&figure/', filename, '.xlsx'];
    Info = readtable(filePath);

    % Read marker from raw Excel cell A2 to avoid readtable type inference issues.
    markerCell = readcell(filePath, 'Range', 'A2');
    markerText = "";
    if ~isempty(markerCell)
        markerText = strtrim(string(markerCell{1}));
    end

    if strcmpi(markerText, "with SG reactance")
        SG_reactance_flag = 1; % 同步机暂态电抗【已经】折算进入网络的设备表
    else
        SG_reactance_flag = 0; % 同步机暂态电抗【尚未】折算进入网络的设备表
    end

    Info = Info(2:end, :);
    
    for rr = 1:nNet
        if isempty(find(rr == Info.Node))
            type(rr) = cellstr("Cnct");
            Cnct{rr} = 0;  
        else
            ii = find(rr == Info.Node, 1, 'first');
            typeRaw = Info{ii, 'Type'};
            if iscell(typeRaw)
                typeRaw = typeRaw{1};
            end
            typeText = char(strtrim(string(typeRaw)));
            type(rr) = cellstr(typeText);
            if strcmp(typeText, 'Gen')
                Gen{rr}.M = Info.Para1(ii);    Gen{rr}.D = Info.Para2(ii);   Gen{rr}.Td = Info.Para3(ii);  
                Gen{rr}.xd = Info.Para4(ii);   Gen{rr}.xdp = Info.Para5(ii);
                Gen{rr}.Pm = Info.Para6(ii);   Gen{rr}.Ef = Info.Para7(ii);
            elseif strcmp(typeText, 'VSG')
                VSG{rr}.M = Info.Para1(ii);    VSG{rr}.D = Info.Para2(ii);   VSG{rr}.Td = Info.Para3(ii);  
                VSG{rr}.xd = Info.Para4(ii);   VSG{rr}.xdp = Info.Para5(ii);
                VSG{rr}.Pm = Info.Para6(ii);   VSG{rr}.Ef = Info.Para7(ii);
            elseif strcmp(typeText, 'CDInv')
                CDInv{rr}.t1 = Info.Para1(ii);      CDInv{rr}.t2 = Info.Para2(ii);  
                CDInv{rr}.As = Info.Para3(ii);      CDInv{rr}.Vs = Info.Para4(ii); 
                CDInv{rr}.Ps = Info.Para5(ii);      CDInv{rr}.Qs = Info.Para6(ii); 
                CDInv{rr}.D1 = Info.Para7(ii);      CDInv{rr}.D2 = Info.Para8(ii);
            elseif strcmp(typeText, 'QDInv')
                QDInv{rr}.t1 = Info.Para1(ii);      QDInv{rr}.t2 = Info.Para2(ii);  
                QDInv{rr}.As = Info.Para3(ii);      QDInv{rr}.Vs = Info.Para4(ii); 
                QDInv{rr}.Ps = Info.Para5(ii);      QDInv{rr}.Qs = Info.Para6(ii); 
                QDInv{rr}.D1 = Info.Para7(ii);      QDInv{rr}.D2 = Info.Para8(ii);
%             elseif strcmp(typeText, 'PLLInv')
%                 PLLInv{rr}.Ki = Info.Para1(ii);      PLLInv{rr}.Kp = Info.Para2(ii);  
%                 PLLInv{rr}.tau1 = Info.Para3(ii);    PLLInv{rr}.Ps = Info.Para4(ii); 
%                 PLLInv{rr}.D1 = Info.Para5(ii);      
%                 PLLInv{rr}.tau2 = Info.Para6(ii);    
%                 PLLInv{rr}.Qs = Info.Para7(ii);      PLLInv{rr}.Vs = Info.Para8(ii);
%                 PLLInv{rr}.D2 = Info.Para9(ii);
            elseif strcmp(typeText, 'Load')
                Load{rr}.Ps = Info.Para1(ii);      Load{rr}.Qs = Info.Para2(ii);
            else
                error('Initial error: settingElement error');
            end
        end
    end
    
end

