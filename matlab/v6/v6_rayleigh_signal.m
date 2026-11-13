function [s,scatter] = v6_rayleigh_signal(cfg,truth)
%V6_RAYLEIGH_SIGNAL 固定复散射点 => 真实扫频下的实值主干涉信号。
% s(t)=Re{sum_j a_j exp(i*2*pi*(2*n_g*z_j/c)*q_true(t))}。
% 散射系数固定且配对复用，不在第二次扫描时重新生成。
% 这是离散随机复散射体的冻结频率教学模型，并非完整瑞利光场模型。
    if cfg.v6.scatter_z_min_m>=cfg.v6.scatter_z_max_m || cfg.v6.scatter_step_m<=0
        error('V6 散射体空间范围/间隔无效。');
    end
    z=(cfg.v6.scatter_z_min_m:cfg.v6.scatter_step_m:cfg.v6.scatter_z_max_m).';
    if numel(z)<20, error('V6 需要足够多的静态散射体。');end
    tau=2*cfg.fut.group_index*z/cfg.const.c_m_s;
    maxbeat=max(truth.tuning_rate_Hz_s)*max(tau);
    if maxbeat >= truth.fs_Hz/2
        error('V6 最远散射体混叠：最大拍频 %.1f Hz >= Nyquist %.1f Hz。',maxbeat,truth.fs_Hz/2);
    end
    rng(cfg.v6.scatter_seed,'twister');
    a=(randn(numel(z),1)+1i*randn(numel(z),1))/sqrt(2*numel(z));
    q=truth.nu_offset_Hz(:); s=zeros(truth.N,1);
    bs=cfg.v6.scatter_block_size;
    if bs<1 || bs~=floor(bs),error('scatter_block_size 必须为正整数。');end
    for j=1:bs:numel(z)
        ii=j:min(numel(z),j+bs-1);
        phase=2*pi*(q*tau(ii).');
        s=s+real(exp(1i*phase)*a(ii));
    end
    scatter.z_m=z;
    scatter.coeff=a;
    scatter.delay_s=tau;
    scatter.seed=cfg.v6.scatter_seed;
    scatter.signal_model='real multi-scatterer interference; frozen-frequency approximation';
    scatter.maximum_beat_Hz=maxbeat;
end
