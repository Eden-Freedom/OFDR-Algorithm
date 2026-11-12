function baselines = interp_fft_baselines_v3(u, original, window_mode)
%INTERP_FFT_BASELINES_V3 非均匀光频线性/三次样条重采样再做 FFT。
% 使用目标光频网格 u_grid=n/N，确保和 NUFFT 空间坐标 z_k 一致。
% 注意扫频端点 t=T 未采集；非线性扫频的最后一个已观测点可能略
% 早于 u_grid(end)，此时 interp1 使用极小范围的端点外推。
    u=u(:);original=original(:);N=numel(u);
    if numel(original)~=N || any(diff(u)<=0) || u(1)<0 || u(end)>=1
        error('插值输入的光频坐标应严格递增，范围为 [0,1)。');
    end
    u_grid=(0:N-1)'/N;
    w=spectral_window_v3(u_grid,window_mode);
    t=tic;
    linear=interp1(u,original,u_grid,'linear','extrap');
    baselines.linear=(fft(linear.*w)/N);
    baselines.time_linear_s=toc(t);
    t=tic;
    cubic=interp1(u,original,u_grid,'pchip','extrap');
    baselines.pchip=(fft(cubic.*w)/N);
    baselines.time_pchip_s=toc(t);
    baselines.u_grid=u_grid;
    baselines.extrapolated_points=sum((u_grid<u(1)) | (u_grid>u(end)));
end
