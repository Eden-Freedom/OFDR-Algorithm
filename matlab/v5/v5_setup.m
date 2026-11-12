function context = v5_setup(cfg, with_sswt)
%V5_SETUP 建立共享信号和频率坐标。实验间复用同一主干涉信号。
    if nargin<2,with_sswt=true;end
    here=fileparts(mfilename('fullpath'));
    for version=1:4
        addpath(fullfile(fileparts(here),sprintf('v%d',version)));
    end
    cfg.plot.enabled=false;
    if with_sswt
        [~,truth,signals,v2,calibration_metrics]=main_v2(cfg);
        q_sswt=v2.calibration.sswt.nu_offset_Hz(:);
        f_sswt=v2.calibration.sswt.freq_Hz(:);
    else
        truth=simulate_laser_sweep(cfg);
        signals=simulate_ofdr_signals(cfg,truth);
        v2=[];calibration_metrics=[];q_sswt=[];f_sswt=[];
    end
    q=truth.nu_offset_Hz(:);
    [u,~]=prepare_frequency_coordinates_v4(q,cfg,'true');
    context.cfg=cfg;
    context.truth=truth;
    context.signals=signals;
    context.v2=v2;
    context.calibration_metrics=calibration_metrics;
    context.q_true_Hz=q;
    context.q_sswt_Hz=q_sswt;
    context.f_sswt_Hz=f_sswt;
    context.u_true=u;
    context.bandwidth_Hz=cfg.const.c_m_s* ...
        (1/cfg.laser.lambda_end_m-1/cfg.laser.lambda_start_m);
    context.dz_m=cfg.const.c_m_s/(2*cfg.fut.group_index*context.bandwidth_Hz);
    context.z_coarse_m=(0:floor(truth.N/2))'*context.dz_m;
    context.k=(0:floor(truth.N/2))';
    context.weights_true=frequency_density_weights_v3(u,cfg.v3.density_mode);
    context.window_true=spectral_window_v3(u,cfg.v3.window);
end
