function [state0, steady_exitflag] = funcSteady()
    global refPos;

    options = optimoptions('fsolve','MaxIterations',400, 'MaxFunctionEvaluations', 1200, 'Display', 'off');

    [state0, ~, steady_exitflag] = fsolve(@calcPowerflow, calcPowerflowInit(), options);

    % Before state transformation, shift all voltage angles by the reference angle.
    nNetLocal = floor(numel(state0) / 2);
    if isempty(refPos) || refPos < 1 || refPos > nNetLocal
        error('funcSteady:InvalidRefPos', 'refPos must be in [1, %d].', nNetLocal);
    end
    refAngle = state0(2 * refPos - 1);
    state0(1:2:end) = state0(1:2:end) - refAngle;

    state0 = funcStateTrans(state0);
    
    if steady_exitflag <= 0
        warning('Steady value warning: funcSteady warning');
    end
end