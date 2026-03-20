% 仿真设置
function settingSimulation()
    global dt te;
    global LoadEquivDroop;
    global refPos;
    
    dt = 0.005;  % 仿真步长
    te = 10;    % 仿真时长

    LoadEquivDroop = 0; % load equivalent P-theta/Q-V droop strength ( = 0 for constant power load) 

    refPos = 30; % NOT APPLICABLE NOW! (phase-angle reference position)
end