function out = funcSearch(state, namecell)
    global type;
    global nNet;

    if size(state, 2) == 1
        state = state';
    end
    
    out = [];
    for rr = 1:length(namecell)
        % output angle
        if strcmp(namecell{rr}, 'Angle')
            pos = [];
            bias = 0;
            for ii = 1:nNet 
                if strcmp(type{ii}, "Gen")
                    pos = [pos, bias+1];  bias = bias+3;
                elseif strcmp(type{ii}, "VSG")
                    pos = [pos, bias+1];  bias = bias+3;
                elseif strcmp(type{ii}, "CDInv")
                    pos = [pos, bias+1];  bias = bias+2;
                elseif strcmp(type{ii}, "QDInv")
                    pos = [pos, bias+1];  bias = bias+2;
                elseif strcmp(type{ii}, "PLLInv")
                    pos = [pos, bias+5];  bias = bias+6;
                elseif strcmp(type{ii}, "Load")
                    pos = [pos, bias+1];  bias = bias+2;
                elseif strcmp(type{ii}, "Cnct")
                    pos = [pos, bias+1];  bias = bias+2;
                else
                    error('Initial error: settingElement error');
                end
            end
            out = [out, state(:, pos)];
        % output frequency
        elseif strcmp(namecell{rr}, 'Frequency')
            pos = [];
            bias = 0;
            for ii = 1:nNet 
                if strcmp(type{ii}, "Gen")
                    pos = [pos, bias+2];  bias = bias+3;
                elseif strcmp(type{ii}, "VSG")
                    pos = [pos, bias+2];  bias = bias+3;
                elseif strcmp(type{ii}, "PLLInv")
                    pos = [pos, bias+2];  bias = bias+6;
                else
                    error('Initial error: settingElement error');
                end
            end
            out = [out, state(:, pos)];
        % output voltage
        elseif strcmp(namecell{rr}, 'Voltage')
            pos = [];
            bias = 0;
            for ii = 1:nNet 
                if strcmp(type{ii}, "Gen")
                    pos = [pos, bias+3];  bias = bias+3;
                elseif strcmp(type{ii}, "VSG")
                    pos = [pos, bias+3];  bias = bias+3;
                elseif strcmp(type{ii}, "CDInv")
                    pos = [pos, bias+2];  bias = bias+2;
                elseif strcmp(type{ii}, "QDInv")
                    pos = [pos, bias+2];  bias = bias+2;
                elseif strcmp(type{ii}, "PLLInv")
                    pos = [pos, bias+6];  bias = bias+6;
                elseif strcmp(type{ii}, "Load")
                    pos = [pos, bias+2];  bias = bias+2;
                elseif strcmp(type{ii}, "Cnct")
                    pos = [pos, bias+2];  bias = bias+2;
                else
                    error('Initial error: settingElement error');
                end
            end
            out = [out, state(:, pos)];
        elseif strcmp(namecell{rr}, 'P')
            AV_array = zeros(size(state,1), 2*nNet);
            AV_array(:, 1:2:end) = funcSearch(state, "Angle");
            AV_array(:, 2:2:end) = funcSearch(state, "Voltage");
            PQ_array = calcPower(AV_array);
            Pout = real(PQ_array);
            out = [out, Pout];
        elseif strcmp(namecell{rr}, 'Q')
            AV_array = zeros(size(state,1), 2*nNet);
            AV_array(:, 1:2:end) = funcSearch(state, "Angle");
            AV_array(:, 2:2:end) = funcSearch(state, "Voltage");
            PQ_array = calcPower(AV_array);
            Qout = imag(PQ_array);
            out = [out, Qout];
        end
        % 
        
    end
end