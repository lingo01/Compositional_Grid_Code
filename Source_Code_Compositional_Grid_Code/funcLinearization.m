function y = funcLinearization(state0, flag)

    DAE_Jac = funcJacobi(state0, @(x) calcSimulation(0,x), 1e-7);

    DAE_pos = diag(calc_DAEmass());
    DE_pos = find(DAE_pos == 1);
    AE_pos = find(DAE_pos == 0);

    matA = DAE_Jac(DE_pos, DE_pos);
    matB = DAE_Jac(DE_pos, AE_pos);
    matC = DAE_Jac(AE_pos, DE_pos);
    matD = DAE_Jac(AE_pos, AE_pos);

    if strcmp(flag, 'DAE')
        y.Jac = DAE_Jac;
        y.A = matA;
        y.B = matB;
        y.C = matC;
        y.D = matD;
    elseif strcmp(flag, 'ODE')
        y = matA - matB * inv(matD) * matC;
    else
        error('Linearization error: Illegal linearization method');
    end
    
end


%%
% function matRe = zeros_reduced(mat)
%     if size(mat, 1) ~= size(mat, 2)
%         error('Linearization error: Illegal linearizated matrix')
%     end
% 
%     posRe = [];
%     for ii = 1:size(mat, 1)
%         if max(abs(mat(:,ii)))<1e-12 && max(abs(mat(ii,:)))<1e-12
%             posRe = [posRe, ii];
%         end
%     end
%     idx = setdiff(1:size(mat, 1), posRe);
%     matRe = mat(idx, idx);
% end