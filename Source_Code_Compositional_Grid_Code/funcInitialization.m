function funcInitialization(networkSetName, deviceSetName)
    global SG_reactance_flag;
    %% basic settings
    % network settings
    settingNetwork(networkSetName);
    
    % fault settings
    settingFault();
    
    % simulation settings
    settingSimulation();

    % device type and parameter setting
    settingElement(deviceSetName);

    % configuration change: Generator xdp
    if SG_reactance_flag == 0
        funcInitialization_Gen();
        SG_reactance_flag = 1;
    end
end

function funcInitialization_Gen()
    global nNet netY netB netG;
    global type Gen;

    num_Gen = sum(strcmp(type, "Gen"));
    pos_Gen = find(strcmp(type, "Gen"));

    netY_tmp = blkdiag(netY, zeros(num_Gen));
    type_tmp = type;
    Gen_tmp = Gen;
    nNet_tmp = nNet;

    % network resetting
    for ii = 1:num_Gen
        add_Y = 1/(1j*Gen{pos_Gen(ii)}.xdp);
        netY_tmp(nNet+ii, nNet+ii) = netY_tmp(nNet+ii, nNet+ii) + add_Y;
        netY_tmp(pos_Gen(ii), pos_Gen(ii)) = netY_tmp(pos_Gen(ii), pos_Gen(ii)) + add_Y;
        netY_tmp(nNet+ii, pos_Gen(ii)) = netY_tmp(nNet+ii, pos_Gen(ii)) - add_Y;
        netY_tmp(pos_Gen(ii), nNet+ii) = netY_tmp(pos_Gen(ii), nNet+ii) - add_Y;
    end

    % device resetting
    for ii = 1:num_Gen
        Gen{nNet + ii} = Gen{pos_Gen(ii)};
        Gen{pos_Gen(ii)} = {};
        type{nNet + ii} = 'Gen';
        type{pos_Gen(ii)} = 'Cnct';
    end

    % setting
    netY = netY_tmp;
    netG = real(netY);
    netB = imag(netY); 
    nNet = size(netY, 1);
end