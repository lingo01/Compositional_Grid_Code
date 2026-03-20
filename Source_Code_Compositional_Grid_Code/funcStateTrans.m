function xRe = funcStateTrans(x, flag)
    global nNet;
    global type;

    xRe_len = 3*sum(strcmp(type, "Gen"))...
        + 3*sum(strcmp(type, "VSG"))...
        + 2*sum(strcmp(type, "CDInv"))...
        + 2*sum(strcmp(type, "QDInv"))...
        + 6*sum(strcmp(type, "PLLInv"))...
        + 2*sum(strcmp(type, "Load"))...
        + 2*sum(strcmp(type, "Cnct"));

    if size(x,2) == 1
        x = x';
    end
    
    if ~exist('flag', 'var')
        flag = 'Expand';
    end
    
    if strcmp(flag, 'Expand')
        xRe = zeros(1, xRe_len);
        PQ_steady = calcPower(x);
        bias = 0;
        for ii = 1:nNet
            if strcmp(type{ii}, "Gen")
                xRe(bias+1:bias+3) = [x(2*ii-1); 0; x(2*ii)];
                bias = bias + 3;
            elseif strcmp(type{ii}, "VSG")
                xRe(bias+1:bias+3) = [x(2*ii-1); 0; x(2*ii)];
                bias = bias + 3;
            elseif strcmp(type{ii}, "CDInv")
                xRe(bias+1:bias+2) = [x(2*ii-1); x(2*ii)];
                bias = bias + 2;
            elseif strcmp(type{ii}, "QDInv")
                xRe(bias+1:bias+2) = [x(2*ii-1); x(2*ii)];
                bias = bias + 2;
            elseif strcmp(type{ii}, "PLLInv")
                xRe(bias+1:bias+6) = [0; 0; real(PQ_steady(ii)); imag(PQ_steady(ii)); x(2*ii-1); x(2*ii)];
                bias = bias + 6;
            elseif strcmp(type{ii}, "Load")
                xRe(bias+1:bias+2) = [x(2*ii-1); x(2*ii)];
                bias = bias + 2;
            elseif strcmp(type{ii}, "Cnct")
                xRe(bias+1:bias+2) = [x(2*ii-1); x(2*ii)];
                bias = bias + 2;
            else
                error('Initial error: settingElement error');
            end
        end
    end
end

