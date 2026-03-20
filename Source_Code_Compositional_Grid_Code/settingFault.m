% 仿真设置
function settingFault()
    global shortPos shortRes shortCT;
    
    shortCT = 0.1;  % fault clearing time
    shortPos = 16;   % fault bus
    shortRes = 1e1;  % short-circuit impedance, set "nan" for no fault
    
end