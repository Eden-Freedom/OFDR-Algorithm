function Q=v5_calibration_requirements(context,Bscale,Bresidual)
%V5_CALIBRATION_REQUIREMENTS 根据示例阈值提出“分项”标定精度目标。
% 这些是研究用初值，不能自动宣称满足真实设备指标或普适分辨率。
    cfg=context.cfg;
    far=2.4;
    Q.position_threshold_m=cfg.v5.position_limit_m;
    Q.fwhm_relative_limit=cfg.v5.fwhm_growth_limit;
    Q.phase_rms_limit_rad=cfg.v5.phase_limit_rad;
    Q.scale_limit_ppm=1e6*cfg.v5.position_limit_m/far;
    Q.nonlinear_error_rms_limit_MHz=cfg.v5.phase_limit_rad* ...
        cfg.const.c_m_s/(4*pi*cfg.fut.group_index*far)/1e6;
    Q.reference_distance_m=far;
    Q.scale_scan_valid=Bscale.valid;
    Q.scale_scan_pass=abs(Bscale.incremental_error_m)<=cfg.v5.position_limit_m & Bscale.valid;
    Q.residual_gamma=Bresidual.gamma;
    Q.gamma_valid=Bresidual.valid;
    Q.gamma_fwhm_pass=false(numel(Bresidual.gamma),1);
    for i=1:numel(Bresidual.gamma)
        if Bresidual.valid(i)
            Q.gamma_fwhm_pass(i)=Bresidual.metrics_full{i}.fwhm_growth<=cfg.v5.fwhm_growth_limit;
        end
    end
    Q.warning='根据模拟参数和示例阈值推导，非可直接用于实际系统的统一规范。';
end
