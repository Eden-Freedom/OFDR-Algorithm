function pairs = v6_controlled_residuals(cfg,N,fs)
%V6_CONTROLLED_RESIDUALS 生成锚定 e(1)=0、同一采样 RMS 的相关平滑误差。
% 使用无工具箱 movmean 平滑后，对去均值随机分量正交化，精确控制
% 经验 Pearson 相关系数 rho。每条轨迹在首点锚定并单独归一化 RMS。
    w=max(5,round(cfg.v6.error_corr_window_ms*1e-3*fs));
    rng(cfg.v6.inject_seed_ref,'twister');
    a=movmean(randn(N,1),w);
    rng(cfg.v6.inject_seed_independent,'twister');
    b=movmean(randn(N,1),w);
    a=a-mean(a);b=b-mean(b);
    a=a/sqrt(mean(a.^2));
    b=b-mean(a.*b)*a;
    b=b/sqrt(mean(b.^2));
    rho=cfg.v6.rho_values(:);
    if any(abs(rho)>1),error('误差相关系数 rho 必须位于 [-1,1]。');end
    scale=cfg.v6.inject_rms_MHz*1e6;
    e1=a-a(1);e1=scale*e1/sqrt(mean(e1.^2));
    pairs.e_ref_Hz=e1;
    pairs.e_meas_Hz=cell(numel(rho),1);
    pairs.rho_target=rho;
    pairs.rho_empirical=zeros(numel(rho),1);
    pairs.rmse_ref_MHz=sqrt(mean(e1.^2))/1e6;
    pairs.rmse_meas_MHz=zeros(numel(rho),1);
    for i=1:numel(rho)
        x=rho(i)*a+sqrt(max(0,1-rho(i)^2))*b;
        e=x-x(1);
        e=scale*e/sqrt(mean(e.^2));
        pairs.e_meas_Hz{i}=e;
        cc=(e1-mean(e1)).*(e-mean(e));
        pairs.rho_empirical(i)=mean(cc)/sqrt(mean((e1-mean(e1)).^2)*mean((e-mean(e)).^2));
        pairs.rmse_meas_MHz(i)=sqrt(mean(e.^2))/1e6;
    end
end
