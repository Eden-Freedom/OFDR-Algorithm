function [s,scatter]=p1_nested_scatter(cfg,truth,seed,level)
%P1_NESTED_SCATTER 在同一底层复高斯随机测度上构造嵌套离散散射场。
% level=0/1/2 对应基础1.5mm、0.75mm、0.375mm间隔；
% 每个最细小区间的随机复振幅方差为1/Nfine，粗区间振幅是其求和，
% 保证总强度归一化且各分辨率不是独立随机场。
% 注意每个离散中心点仍为近似；此设计用于数值收敛机制研究。
    D=cfg.v6.scatter_step_m;
    maxLevel=max(cfg.p1p2.p1_scat_levels);
    if ~ismember(level,cfg.p1p2.p1_scat_levels) || ...
        maxLevel~=floor(maxLevel) || maxLevel>8
        error('P1:Level','散射层级不合法。');
    end
    nBase=floor((cfg.v6.scatter_z_max_m-cfg.v6.scatter_z_min_m)/D);
    if nBase<20,error('P1:ScatterRange','基础散射单元过少。');end
    nFine=nBase*2^maxLevel;
    rng(seed,'twister');
    fine=(randn(nFine,1)+1i*randn(nFine,1))/sqrt(2*nFine);
    merge=2^(maxLevel-level);
    coeff=sum(reshape(fine,merge,[]),1).';
    delta=D/2^level;
    z=cfg.v6.scatter_z_min_m+((0:numel(coeff)-1).'+0.5)*delta;
    tau=2*cfg.fut.group_index*z/cfg.const.c_m_s;
    if max(tau)*max(truth.tuning_rate_Hz_s)>=truth.fs_Hz/2
        error('P1:Aliasing','精细散射模型最远端拍频混叠。');
    end
    q=truth.nu_offset_Hz(:);
    s=zeros(truth.N,1);
    bs=cfg.v6.scatter_block_size;
    for k=1:bs:numel(coeff)
        ii=k:min(numel(coeff),k+bs-1);
        s=s+real(exp(1i*2*pi*(q*tau(ii).'))*coeff(ii));
    end
    scatter.z_m=z;
    scatter.coeff=coeff;
    scatter.delay_s=tau;
    scatter.seed=seed;
    scatter.signal_model='nested complex Gaussian random measure / equal interval midpoint quadrature';
    scatter.maximum_beat_Hz=max(tau)*max(truth.tuning_rate_Hz_s);
    scatter.step_m=delta;
    scatter.level=level;
end