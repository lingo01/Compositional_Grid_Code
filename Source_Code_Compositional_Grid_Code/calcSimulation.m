% 计算电网动态解的导数
% Parameters:
%   x = [delta_1 omega_1 V_1 delta_2 omega_2 V_2 ...]

function dx = calcSimulation(t,x)
    % dx = [delta, omega, V]
    
    global type Gen VSG CDInv QDInv PLLInv Load;
    global nNet;
    global LoadEquivDroop;

    dx_len = 3*length(find(type=="Gen"))...
        + 3*length(find(type=="VSG"))...
        + 2*length(find(type=="CDInv"))...
        + 2*length(find(type=="QDInv"))...
        + 6*length(find(type=="PLLInv"))...
        + 2*length(find(type=="Load"))...
        + 2*length(find(type=="Cnct"));
    dx = zeros(dx_len,1);
    
    % 求解工作点
    xReduced = zeros(2*nNet, 1);
    xReduced(1:2:end) = funcSearch(x', "Angle");
    xReduced(2:2:end) = funcSearch(x', "Voltage");
    S = calcPower(xReduced);
    Pout = real(S); Qout = imag(S);
    
    % 求导数
    bias = 0;
    for ii = 1:nNet
        if strcmp(type{ii}, 'Gen')
            dx(bias+1) = x(bias+2);
            dx(bias+2) = 1/Gen{ii}.M  * (-Gen{ii}.D*x(bias+2) + Gen{ii}.Pm - Pout(ii));
            dx(bias+3) = 1/Gen{ii}.Td * (-x(bias+3) - (Gen{ii}.xd-Gen{ii}.xdp)*Qout(ii)/x(bias+3) + Gen{ii}.Ef);
            bias = bias + 3;
        elseif strcmp(type{ii}, 'VSG')
            dx(bias+1) = x(bias+2);
            dx(bias+2) = 1/VSG{ii}.M  * (-VSG{ii}.D*x(bias+2) + VSG{ii}.Pm - Pout(ii));
            dx(bias+3) = 1/VSG{ii}.Td * (-x(bias+3) - (VSG{ii}.xd-VSG{ii}.xdp)*Qout(ii)/x(bias+3) + VSG{ii}.Ef);
            bias = bias + 3;
        elseif strcmp(type{ii}, 'CDInv')
            dx(bias+1) = 1/CDInv{ii}.t1 * ( -(x(bias+1)-CDInv{ii}.As) - CDInv{ii}.D1 * (Pout(ii) - CDInv{ii}.Ps) );
            dx(bias+2) = 1/CDInv{ii}.t2 * ( -(x(bias+2)  -CDInv{ii}.Vs) - CDInv{ii}.D2 * (Qout(ii) - CDInv{ii}.Qs) );
            bias = bias + 2;
        elseif strcmp(type{ii}, 'QDInv')
            dx(bias+1) = 1/QDInv{ii}.t1 * ( -(x(bias+1)-QDInv{ii}.As) - QDInv{ii}.D1 * (Pout(ii) - QDInv{ii}.Ps) );
            us = QDInv{ii}.Vs + QDInv{ii}.D2 * QDInv{ii}.Qs/QDInv{ii}.Vs;
            dx(bias+2) = 1/QDInv{ii}.t2 * ( -QDInv{ii}.D2 * Qout(ii) - x(bias+2) * (x(bias+2)-us) );
            bias = bias + 2;
        elseif strcmp(type{ii}, 'PLLInv')
            dx(bias+1) = x(bias+6) * sin(x(bias+5) - x(bias+1));
            dx(bias+2) = PLLInv{ii}.Kp * x(bias+6) * sin(x(bias+5)-x(bias+2)) + PLLInv{ii}.Ki * x(bias+1);
            dx(bias+3) = -1/PLLInv{ii}.tau1 * (-Pout(ii) + PLLInv{ii}.Ps - PLLInv{ii}.D1*dx(bias+2));
            dx(bias+4) = -1/PLLInv{ii}.tau2 * (-Qout(ii) + PLLInv{ii}.Qs - PLLInv{ii}.D2*(x(bias+6) - PLLInv{ii}.Vs));
            dx(bias+5) = -(Pout(ii) - x(bias+3));
            dx(bias+6) = -(Qout(ii) - x(bias+4));
            bias = bias + 6;
        elseif strcmp(type{ii}, 'Load')
            dx(bias+1) = ( -LoadEquivDroop * (x(bias+1)-0) - (Pout(ii) - Load{ii}.Ps) );
            dx(bias+2) = ( -LoadEquivDroop * (x(bias+2)-1) - (Qout(ii) - Load{ii}.Qs) );
            bias = bias + 2;
        elseif strcmp(type{ii}, 'Cnct')
            dx(bias+1) = ( -LoadEquivDroop * (x(bias+1)-0) - (Pout(ii) - 0) );
            dx(bias+2) = ( -LoadEquivDroop * (x(bias+2)-1) - (Qout(ii) - 0) );
            bias = bias + 2;
        else
            error('Initial error: settingElement error');
        end
    end
    
end

