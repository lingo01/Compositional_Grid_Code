function M = calc_DAEmass()
    global type;
    global nNet;

    dx_len = 3*length(find(type=="Gen"))...
        + 3*length(find(type=="VSG"))...
        + 2*length(find(type=="CDInv"))...
        + 2*length(find(type=="QDInv"))...
        + 6*length(find(type=="PLLInv"))...
        + 2*length(find(type=="Load"))...
        + 2*length(find(type=="Cnct"));
    dx = zeros(1, dx_len);

    bias =  0;
    for ii = 1:nNet
        if strcmp(type{ii}, 'Gen')
            dx(bias+1:bias+3) = [1, 1, 1];
            bias = bias + 3;    
        elseif strcmp(type{ii}, 'VSG')
            dx(bias+1:bias+3) = [1, 1, 1];
            bias = bias + 3;   
        elseif strcmp(type{ii}, 'CDInv')
            dx(bias+1:bias+2) = [1, 1];
            bias = bias + 2;     
        elseif strcmp(type{ii}, 'QDInv')
            dx(bias+1:bias+2) = [1, 1];
            bias = bias + 2;
        elseif strcmp(type{ii}, 'PLLInv')
            dx(bias+1:bias+6) = [1, 1, 1, 1, 0, 0];
            bias = bias + 6;
        elseif strcmp(type{ii}, "Load")
            dx(bias+1:bias+2) = [0, 0];
            bias = bias + 2;
        elseif strcmp(type{ii}, "Cnct")
            dx(bias+1:bias+2) = [0, 0];
            bias = bias + 2;
        else
            error('Initial error: settingElement error');
        end
    end

    M = diag(dx);
end