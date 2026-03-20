function [t, state, exit_flag] = funcTransient(state0, steady_exitflag, t0)
    % 当且仅当成功求解时exit_flag=0，否则=1
    global dt te;
    global refPos;
    global netB netG netY;
    global shortPos shortRes shortCT;

    DAE_mass = calc_DAEmass();
    DAE_opt = odeset('Mass',DAE_mass,'RelTol',1e-4,'AbsTol',1e-6*ones(1,size(DAE_mass,1)));

    % before-disturbance transient
    if ~exist('t0', 'var')
        t0 = 0.1 * (steady_exitflag > 0) + te/2 * (steady_exitflag <= 0);
    end

    [t_1,state_1] = ode15s(@calcSimulation, [0:dt:t0], state0, DAE_opt);  

    % during-disturbance transient
    if ~isnan(shortRes)
        shortAdm = 1/shortRes;
        netY(shortPos,shortPos) = netY(shortPos,shortPos) + shortAdm;
        netG = real(netY);      
        netB = imag(netY);
    end
    
    [t_2,state_2] = ode15s(@calcSimulation, [t0:dt:(t0+shortCT)], state_1(end,:), DAE_opt);

    % post-disturbance transient
    if ~isnan(shortRes)
        shortAdm = 1/shortRes;
        netY(shortPos,shortPos) = netY(shortPos,shortPos) - shortAdm;
        netG = real(netY);      
        netB = imag(netY);
    end
    [t, state] = ode15s(@calcSimulation, [(t0+shortCT):dt:te],  state_2(end,:), DAE_opt);

    % output
    t = [t_1; t_2; t];
    state = [state_1; state_2; state];
    % state(:,1:3:end) = state(:,1:3:end) - state(:,3*refPos-2);

    exit_flag = (t(end) ~= te);
end