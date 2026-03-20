function J = funcJacobi(x, f, disturb)

    if isempty(disturb) || isnan(disturb) || disturb <= 0
        disturb = 1e-7;
    end

    n = length(x);
    J = zeros(n, n);

    for ii = 1:n
        dx = zeros(size(x)); dx(ii) = disturb;

        f_pos = f(x+dx);
        f_neg = f(x-dx);

        J(:, ii) = (f_pos - f_neg) / (2*disturb);
    end
end