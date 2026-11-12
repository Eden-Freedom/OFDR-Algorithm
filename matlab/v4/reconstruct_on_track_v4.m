function out = reconstruct_on_track_v4(u, samples, cfg, k, do_interp)
%RECONSTRUCT_ON_TRACK_V4 复用 V3 的窗函数、密度补偿与 NUFFT 实现。
% u：严格递增的归一化光频轨迹；samples：主 OFDR 的实值测量信号。
% 特别注意：不同方法应使用与其坐标相对应的光频窗函数、密度权重。
% 同时保证不同方法使用同一个标称光频扫描带宽和 k → z 的距离轴。
    if nargin<5,do_interp=true;end
    u=u(:);samples=samples(:); k=k(:);
    if numel(u)~=numel(samples)
        error('频率坐标与主干涉信号必须逐样本对应。');
    end
    weights=frequency_density_weights_v3(u,cfg.v3.density_mode);
    window=spectral_window_v3(u,cfg.v3.window);
    t=tic;
    nufft=nufft_gaussian_type1_v3(u,samples.*window,weights,k,cfg.v3);
    elapsed=toc(t);
    out.spectrum=nufft.spectrum;
    out.weights=weights;
    out.window=window;
    out.nufft=nufft;
    out.nufft_s=elapsed;
    if do_interp
        interp=interp_fft_baselines_v3(u,samples,cfg.v3.window);
        out.linear=interp.linear(k+1);
        out.pchip=interp.pchip(k+1);
        out.interp_time_s=interp.time_linear_s+interp.time_pchip_s;
        out.extrapolated_points=interp.extrapolated_points;
    else
        out.linear=[];
        out.pchip=[];
        out.interp_time_s=NaN;
        out.extrapolated_points=NaN;
    end
end
