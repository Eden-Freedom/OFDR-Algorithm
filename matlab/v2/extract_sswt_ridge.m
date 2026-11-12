function ridge = extract_sswt_ridge(sswt, cwt, opts)
%EXTRACT_SSWT_RIDGE 为单分量辅助 MZI 追踪 SSWT 拍频脊线。
%   先在 |T(f,t)| 中寻峰，后用邻近该峰的 CWT 相位导数细化频率。
%   后者缓解离散 bin 对连续瞬时频率的量化误差。
%   追踪约束只适用于频率平滑变化且始终在给定频带内的单脊线。

    energy = abs(sswt.T);
    freq = sswt.freq_axis_Hz(:);
    [nb, N] = size(energy);
    raw_Hz = nan(N, 1);
    peakbin_Hz = nan(N, 1);
    confidence = zeros(N, 1);
    prev = nan;
    for n = 1:N
        candidates = 1:nb;
        if n>1 && isfinite(prev)
            local = find(abs(freq-prev) <= opts.track_search_Hz);
            if ~isempty(local)
                candidates = local;
            end
        end
        [maxamp, ix] = max(energy(candidates,n));
        if maxamp <= 0
            [maxamp, ix] = max(energy(:,n));
            candidates = 1:nb;
        end
        bi = candidates(ix);
        peakbin = freq(bi);
        peakbin_Hz(n) = peakbin;

        % 脊线所在的 SSWT bin 用于定位，再利用附近尺度的连续相位
        % 导数及 |W|^2 加权平均，得到比 100 Hz 网格更细的估计。
        finst = sswt.inst_freq_Hz(:,n);
        local_keep = sswt.keep(:,n) & ...
                     abs(finst-peakbin)<=opts.refine_band_Hz;
        if any(local_keep)
            weights = abs(cwt.W(local_keep,n)).^2;
            raw_Hz(n) = sum(weights.*finst(local_keep))/sum(weights);
        else
            raw_Hz(n) = peakbin;
        end
        prev = raw_Hz(n);
        confidence(n) = maxamp/max(max(energy(:,n)), realmin);
    end

    smooth_points = opts.smooth_points;
    if ~(smooth_points >= 1 && smooth_points == floor(smooth_points))
        error('smooth_points 必须为正整数。');
    end
    if smooth_points > 1
        % movmean 属于基础 MATLAB；不使用 Signal Processing Toolbox。
        estimated_Hz = movmean(raw_Hz, smooth_points);
    else
        estimated_Hz = raw_Hz;
    end
    ridge.freq_before_edge_correction_Hz = estimated_Hz;
    if opts.edge_extrapolate
        edge_count=ceil(opts.edge_sigma*max(cwt.scales_s)*cwt.fs_Hz);
        fit_count=ceil(opts.edge_fit_s*cwt.fs_Hz);
        estimated_Hz=ridge_edge_extrapolate(estimated_Hz,cwt.fs_Hz,edge_count,fit_count);
    end
    ridge.freq_Hz = estimated_Hz;
    ridge.freq_raw_Hz = raw_Hz;
    ridge.peakbin_Hz = peakbin_Hz;
    ridge.confidence = confidence;
    ridge.time_s = sswt.time_s;
end
