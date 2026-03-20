% 计算电网潮流解的迭代初始值
% Parameters:
%   x = [delta_1 V_1 delta_2 V_2 ...]

function xInit = calcPowerflowInit()
    global type Gen VSG CDInv QDInv PLLInv;
    global nNet;
	xInit = zeros(1,2*nNet);
    
    % 求解工作点
    bias = 0;
    for ii = 1:nNet
        % 发电机
        if strcmp(type{ii}, 'Gen')
            xInit(bias+1) = 0;
            xInit(bias+2) = Gen{ii}.Ef;
            bias = bias + 2;
        elseif strcmp(type{ii}, 'VSG')
            xInit(bias+1) = 0;
            xInit(bias+2) = VSG{ii}.Ef;
            bias = bias + 2;
        elseif strcmp(type{ii}, 'CDInv')
            xInit(bias+1) = CDInv{ii}.As;
            xInit(bias+2) = CDInv{ii}.Vs;
            bias = bias + 2;
        elseif strcmp(type{ii}, 'QDInv')
            xInit(bias+1) = QDInv{ii}.As;
            xInit(bias+2) = QDInv{ii}.Vs;
            bias = bias + 2;
        elseif strcmp(type{ii}, 'PLLInv')
            xInit(bias+1) = 0;
            xInit(bias+2) = PLLInv{ii}.Vs;
            bias = bias + 2;
        elseif strcmp(type{ii}, 'Load')
            xInit(bias+1) = 0;
            xInit(bias+2) = 1.05;
            bias = bias + 2;
        elseif strcmp(type{ii}, 'Cnct')
            xInit(bias+1) = 0;
            xInit(bias+2) = 1.05;
            bias = bias + 2;
        else
            error('Initial error: settingElement error');
        end
    end
end