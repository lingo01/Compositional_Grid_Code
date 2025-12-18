function Hnet = func_Hnet_generator(casename, saveflag, loadscaling)

% func_Hnet_generator("case118", 1, 1)

% 
if nargin == 0
    casename = "case118";
    saveflag = 0;
    loadscaling = 1;
elseif nargin == 1
    saveflag = 0;
    loadscaling = 1;
elseif nargin == 2
    loadscaling = 1;
end

mpc = loadcase(casename);

% case母线重新编号
bus_old = mpc.bus(:,1);
bus_new = (1:size(mpc.bus, 1))';

mpc.bus(:,1) = bus_new;
for ii = 1:size(mpc.branch, 1)
    mpc.branch(ii, 1) = bus_new( find(bus_old == mpc.branch(ii, 1)) );
    mpc.branch(ii, 2) = bus_new( find(bus_old == mpc.branch(ii, 2)) );
end
for ii = 1:size(mpc.gen, 1)
    mpc.gen(ii, 1) = bus_new( find(bus_old == mpc.gen(ii, 1)) );
end

% 负荷放缩
mpc.bus(:,[3,4]) = loadscaling * mpc.bus(:,[3,4]);

% 实际潮流值
mpc = runpf(mpc);
bus_Vs = mpc.bus(:, 8);
bus_As = mpc.bus(:, 9)*pi/180;

% 约化前网络参数
netY = full(makeYbus(mpc));
nNet = size(netY, 1);

% 净功率估计
P_pure = zeros(nNet, 1);
Q_pure = zeros(nNet, 1);

for ii = 1:size(mpc.branch, 1)
    P_pure(mpc.branch(ii,1), 1) = P_pure(mpc.branch(ii,1), 1) + mpc.branch(ii, 14)/mpc.baseMVA;
    Q_pure(mpc.branch(ii,1), 1) = Q_pure(mpc.branch(ii,1), 1) + mpc.branch(ii, 15)/mpc.baseMVA;
    P_pure(mpc.branch(ii,2), 1) = P_pure(mpc.branch(ii,2), 1) + mpc.branch(ii, 16)/mpc.baseMVA;
    Q_pure(mpc.branch(ii,2), 1) = Q_pure(mpc.branch(ii,2), 1) + mpc.branch(ii, 17)/mpc.baseMVA;
end

%% 节点类型
dev.ID = [];
load.ID = [];
cnct.ID = [];

gen.ID = mpc.gen(:,1);
gen.ID = unique(gen.ID);

for ii = 1:nNet
    if (abs(P_pure(ii))>=1e-7) || (abs(Q_pure(ii))>=1e-7)
        dev.ID = [dev.ID, ii];
        if isempty(find(ii==gen.ID))
            load.ID = [load.ID, ii];
        end
    else
        cnct.ID = [cnct.ID, ii];
    end
end
dev.num = length(dev.ID);

%% 网络约化
netY_re = netY(dev.ID, dev.ID) - netY(dev.ID, cnct.ID) * inv(netY(cnct.ID, cnct.ID)) * netY(cnct.ID, dev.ID);
netG_re = real(netY_re);
netB_re = imag(netY_re);

%% 生成网络侧传递函数
syms As_sym [dev.num 1] real
syms Vs_sym [dev.num 1] real

% power flow equation
power_flow = sym('power_flow', [2*dev.num, 1]);
for ii = 1:dev.num
    tmpP = 0;    tmpQ = 0;
    for jj = 1:dev.num
        tmpP = tmpP + Vs_sym(jj) * ( netG_re(ii,jj)*cos(As_sym(ii)-As_sym(jj)) + netB_re(ii,jj)*sin(As_sym(ii)-As_sym(jj)) );
        tmpQ = tmpQ + Vs_sym(jj) * ( netB_re(ii,jj)*cos(As_sym(ii)-As_sym(jj)) - netG_re(ii,jj)*sin(As_sym(ii)-As_sym(jj)) );
    end
    power_flow(ii) =  tmpP * Vs_sym(ii);
    power_flow(dev.num+ii) = -tmpQ * Vs_sym(ii);
end

% 计算雅可比矩阵
Hnet_sym = jacobian(power_flow, [As_sym; Vs_sym]);

dev_As = bus_As(dev.ID);
dev_Vs = bus_Vs(dev.ID);

% 替换符号变量为具体值并计算数值矩阵
Hnet = subs(Hnet_sym, [As_sym; Vs_sym], [dev_As; dev_Vs]);
Hnet = double(Hnet);

dev_info.dev = dev;
dev_info.gen = gen;
dev_info.load = load;
dev_info.As = dev_As;
dev_info.Vs = dev_Vs;
dev_info.mpc = mpc;

Hnet_info.Hnet = Hnet;
Hnet_info.Hnet_sym = Hnet_sym;

Hnet_info.netY_re = netY_re;

Hnet_info.dev_info = dev_info;

if saveflag == 1
    save(strcat('./data&figure/Hnet_info_', casename,'_loadscaling', num2str(loadscaling) ,'.mat'), 'Hnet_info');
end

end