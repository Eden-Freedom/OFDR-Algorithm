function m = v6_demodulate_zero_strain(cfg,reference,measurement,oracle)
%V6_DEMODULATE_ZERO_STRAIN 两次复迹线的相位差及空间 gauge 相位差。
%   C(z)=R_meas(z)*conj(R_ref(z))，phase=arg(C)。
%   gauge_phase=arg(C(z+L_g)*conj(C(z)))；仅适用于 gauge 相位不跨 pi
%   的零应变/小扰动验证，不将全局 unwrap 穿过低信号相干衰落区域。
%   eps_equiv=phase_g*lambda0/[4*pi*n_eff*(1-p_e)*L_g]。
% 注意此 eps_equiv 是零应变下的*等效假应变代理量*；未经过非零应变
% 正演模型校验相位灵敏度、符号或弹光参数，不能声称已验证应变精度。
    z=oracle.z_m(:);
    Rr=reference.spectrum(:);Rm=measurement.spectrum(:);Ro=oracle.spectrum(:);
    if numel(z)~=numel(Rr)||numel(z)~=numel(Rm)||numel(z)~=numel(Ro)
        error('V6 复空间迹线长度或距离坐标不一致。');
    end
    dz=z(2)-z(1);
    lag=round(cfg.v6.gauge_length_m/dz);
    if lag<1||lag>=numel(z),error('gauge 长度不合理。');end
    L=lag*dz;
    roi=z>=cfg.v6.roi_m(1) & z<=cfg.v6.roi_m(2);
    baseline=median(abs(Ro(roi)));
    threshold=cfg.v6.amplitude_gate_fraction*baseline;
    % 三条迹线必须同时超过相同绝对阈值；没有逐条归一化或相位配准。
    site_good=roi & abs(Ro)>threshold & abs(Rr)>threshold & abs(Rm)>threshold;
    I=(1:(numel(z)-lag)).';
    J=I+lag;
    valid=site_good(I)&site_good(J);
    eligible=roi(I)&roi(J);
    C=Rm.*conj(Rr);
    raw_phase=angle(C);
    gphase=angle(C(J).*conj(C(I)));
    scale=cfg.v6.lambda_ref_m/(4*pi*cfg.v6.phase_index* ...
               (1-cfg.v6.photoelastic_p)*L)*1e6;
    pseudo=gphase*scale;
    raw_phase(~site_good)=NaN;
    gphase(~valid)=NaN;
    pseudo(~valid)=NaN;
    m.z_m=z;
    m.z_gauge_mid_m=(z(I)+z(J))/2;
    m.raw_phase_rad=raw_phase;
    m.gauge_phase_rad=gphase;
    m.equivalent_false_strain_microeps=pseudo;
    m.valid_gauge=valid;
    m.valid_sites=site_good;
    m.valid_fraction=nnz(valid)/max(1,nnz(eligible));
    m.threshold=threshold;
    m.gauge_lag_bins=lag;
    m.gauge_length_actual_m=L;
    m.gauge_scale_microeps_per_rad=scale;
    m.near_wrap_count=nnz(abs(gphase(valid))>0.90*pi);
    m.failure_reason='';
    if m.valid_fraction<cfg.v6.minimum_valid_fraction
        m.failure_reason='低幅度门控后有效 gauge 位置太少';
        m.valid=false;
    else
        m.valid=true;
    end
    if nnz(site_good)>0
        m.single_phase_rmse_rad=sqrt(mean(raw_phase(site_good).^2));
    else
        m.single_phase_rmse_rad=NaN;
    end
    if any(valid)
        gp=gphase(valid);pv=pseudo(valid);
        m.gauge_phase_rmse_rad=sqrt(mean(gp.^2));
        m.false_strain_rmse_microeps=sqrt(mean(pv.^2));
        m.false_strain_bias_microeps=mean(pv);
        sorted=sort(abs(pv));
        m.false_strain_p95_abs_microeps=sorted(max(1,ceil(0.95*numel(sorted))));
    else
        m.gauge_phase_rmse_rad=NaN;
        m.false_strain_rmse_microeps=NaN;
        m.false_strain_bias_microeps=NaN;
        m.false_strain_p95_abs_microeps=NaN;
    end
end
