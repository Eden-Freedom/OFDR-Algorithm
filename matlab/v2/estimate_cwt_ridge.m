function estimate = estimate_cwt_ridge(cwt, opts)
%ESTIMATE_CWT_RIDGE 未同步压缩的 CWT 基线：尺度最大值 + 对数抛物线插值。
% CWT 对单一余弦幅值约随 sqrt(a) 变化，除以 sqrt(a) 后再比较尺度，
% 可以减少由小波归一化造成的固定频率偏差。

    [nscale, N] = size(cwt.W);
    if nscale<3
        error('CWT 至少需要三个尺度做抛物线插值。');
    end
    norm_amp = bsxfun(@rdivide, abs(cwt.W), sqrt(cwt.scales_s));
    [~, idx] = max(norm_amp, [], 1);
    logf = log(cwt.freq_center_Hz);
    track = zeros(N,1);
    for n=1:N
        k = idx(n);
        delta = 0;
        if k>1 && k<nscale
            y1 = log(max(norm_amp(k-1,n),realmin));
            y2 = log(max(norm_amp(k,n),realmin));
            y3 = log(max(norm_amp(k+1,n),realmin));
            den = y1-2*y2+y3;
            if abs(den)>1e-12
                delta = max(-0.8,min(0.8,0.5*(y1-y3)/den));
            end
        end
        step_log = mean(diff(logf));
        track(n) = exp(logf(k)+delta*step_log);
    end
    if opts.smooth_points>1
        track = movmean(track,opts.smooth_points);
    end
    estimate.freq_before_edge_correction_Hz=track;
    if opts.edge_extrapolate
        edge_count=ceil(opts.edge_sigma*max(cwt.scales_s)*cwt.fs_Hz);
        fit_count=ceil(opts.edge_fit_s*cwt.fs_Hz);
        track=ridge_edge_extrapolate(track,cwt.fs_Hz,edge_count,fit_count);
    end
    estimate.freq_Hz=track;
    estimate.time_s=cwt.time_s;
end
