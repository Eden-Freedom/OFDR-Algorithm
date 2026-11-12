function spec=v5_spectrum(context, q_hat_Hz, samples, mode, fine_z_m, do_coarse)
%V5_SPECTRUM 相位与权重隔离实验。固定权重仅用于诊断，不可部署。
% 'fixed'：真值的窗/密度权重固定，估计坐标仅进入核指数。
% 'full' ：按估计坐标重算窗/密度权重，模拟 V4 实际处理流程。
    if nargin<6,do_coarse=true;end
    cfg=context.cfg;
    [u,~]=prepare_frequency_coordinates_v4(q_hat_Hz,cfg,'V5 estimate');
    switch lower(mode)
        case 'fixed'
            weights=context.weights_true; win=context.window_true;
        case 'full'
            weights=frequency_density_weights_v3(u,cfg.v3.density_mode);
            win=spectral_window_v3(u,cfg.v3.window);
        otherwise
            error('权重分支必须为 fixed 或 full');
    end
    spec.mode=mode;spec.q_hat_Hz=q_hat_Hz(:);spec.u_hat=u;
    spec.weights=weights;spec.window=win;
    if do_coarse
        a=nufft_gaussian_type1_v3(u,samples(:).*win,weights,context.k,cfg.v3);
        spec.coarse=a.spectrum;
        spec.nufft_info=a;
    else
        spec.coarse=[];
        spec.nufft_info=[];
    end
    if ~isempty(fine_z_m)
        spec.z_fine_m=fine_z_m(:);
        spec.fine=v5_direct_z(q_hat_Hz,samples,fine_z_m,weights,win,cfg);
    else
        spec.z_fine_m=[];spec.fine=[];
    end
end
