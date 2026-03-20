% 网络设置
function settingNetwork(filename)
    % 规模设置
    global nNet;
    
    global netY netG netB;
    load(['.\data&figure\', filename, '.mat']);

    if size(netY, 1) ~= size(netY, 2)
        error('Initial error: settingNetwork error');
    end

    nNet = size(netY, 1);

    netG = real(netY);
    netB = imag(netY); 
end

