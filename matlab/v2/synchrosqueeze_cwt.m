function sswt = synchrosqueeze_cwt(cwt, opts)
%SYNCHROSQUEEZE_CWT 自实现同步压缩小波变换 (SSWT)。
% 输入是复 CWT 系数 W(a,t)。输出是按瞬时频率重新分配的 T(f,t)。
%
% 1) 计算 W 对时间的复相位变化：
%      f(a,t) ~= angle(W(a,t+dt)*conj(W(a,t-dt))) / (4*pi*dt)
% 2) 在 |W| 大于阈值的系数处，将 W(a,t)*a^(-3/2)*da 加到对应的 f 网格。
% 3) 重分配频率是估计量；freq_bin_Hz 只是显示/存储网格，不等于
%    SSWT 理论精度，也不会凭空产生额外的物理信息。
%
% 注意两点：
%   - 中心相位差跨越两个采样间隔，为避免相位折叠，分析频段上界限制
%     在 fs/4 以下；可用更通用的 unwrap(phase) 导数法扩展此限制。
%   - 脊线近似为正频率单分量；多反射干涉多脊线需要后续专门追踪。

    W = cwt.W;
    [nscale, N] = size(W);
    fs = cwt.fs_Hz;
    dt = 1/fs;
    if opts.f_max_Hz >= fs/4
        error('中心两点相位差法要求 SSWT 分析频段上限 < fs/4。');
    end
    if ~(opts.threshold_rel >= 0 && opts.threshold_rel < 1)
        error('SSWT 系数幅值阈值必须位于 [0,1)。');
    end
    if ~(opts.freq_bin_Hz > 0 && isfinite(opts.freq_bin_Hz))
        error('SSWT 重分配频率间隔必须是正数。');
    end

    instf = nan(nscale, N);
    instf(:,2:N-1) = angle(W(:,3:N).*conj(W(:,1:N-2)))/(4*pi*dt);
    instf(:,1) = angle(W(:,2).*conj(W(:,1)))/(2*pi*dt);
    instf(:,N) = angle(W(:,N).*conj(W(:,N-1)))/(2*pi*dt);

    axis_Hz = (opts.f_min_Hz:opts.freq_bin_Hz:opts.f_max_Hz).';
    nbins = numel(axis_Hz);
    magnitude = abs(W);
    threshold = opts.threshold_rel * max(magnitude, [], 1);
    keep = bsxfun(@gt, magnitude, threshold) & isfinite(instf) & ...
           (instf >= axis_Hz(1)) & (instf <= axis_Hz(end));

    % W*a^(-3/2)*da：da 由相邻尺度中点确定，不能忘记尺度积分权重。
    scales = cwt.scales_s;
    edges = [scales(1) - 0.5*(scales(2)-scales(1)); ...
             0.5*(scales(1:end-1)+scales(2:end)); ...
             scales(end) + 0.5*(scales(end)-scales(end-1))];
    da = diff(edges);
    scale_weights = da./(scales.^(3/2));
    weighted = bsxfun(@times, W, scale_weights);

    bins = round((instf - axis_Hz(1))/opts.freq_bin_Hz)+1;
    keep = keep & (bins >= 1) & (bins <= nbins);
    [scale_indices, time_indices] = find(keep); %#ok<ASGLU>
    lin_cwt = find(keep);
    chosen_bins = bins(lin_cwt);
    lin_sswt = (time_indices-1)*nbins + chosen_bins;
    coeff = weighted(lin_cwt);

    % 稀疏散射 (scatter-add) 到固定的频率-时间网格；这里先分别累加
    % 实部和虚部，规避不同 MATLAB 版本对于复数 accumarray 的差异。
    total_count = nbins*N;
    sum_real = accumarray(lin_sswt, real(coeff), [total_count,1], @sum, 0);
    sum_imag = accumarray(lin_sswt, imag(coeff), [total_count,1], @sum, 0);
    T = reshape(complex(sum_real, sum_imag), nbins, N);

    sswt.T = T;
    sswt.freq_axis_Hz = axis_Hz;
    sswt.inst_freq_Hz = instf;
    sswt.keep = keep;
    sswt.scale_weights = scale_weights;
    sswt.valid_fraction = nnz(keep)/numel(keep);
    sswt.time_s = cwt.time_s;
end
