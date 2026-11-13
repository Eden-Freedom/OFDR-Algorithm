function out = v6_reconstruct_trace(cfg,truth,s,q_est_Hz)
%V6_RECONSTRUCT_TRACE 复用 V3 NUFFT，在统一物理距离网格求复空间迹线。
% 窗和 Voronoi 权重按估计光频坐标重新计算，属于完整处理模式。
    [u,meta]=prepare_frequency_coordinates_v4(q_est_Hz,cfg,'V6');
    n=truth.N;
    k=(0:floor(n/2)).';
    B=truth.delta_nu_Hz;
    dz=cfg.const.c_m_s/(2*cfg.fut.group_index*B);
    w=spectral_window_v3(u,cfg.v3.window);
    density=frequency_density_weights_v3(u,cfg.v3.density_mode);
    t0=tic;
    res=nufft_gaussian_type1_v3(u,s(:).*w,density,k,cfg.v3);
    out.spectrum=res.spectrum(:);
    out.z_m=k*dz;
    out.u=u;
    out.nu_offset_Hz=q_est_Hz(:);
    out.window=w;
    out.density=density;
    out.meta=meta;
    out.runtime_s=toc(t0);
end
