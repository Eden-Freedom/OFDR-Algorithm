function metrics = evaluate_nufft_v3(results, truth, signals, cfg)
%EVALUATE_NUFFT_V3 验证 NUFFT 数值误差和真实反射点附近的峰值位置。
% NUDFT 精度检验仅在 probe_k 上进行，不冒充完整空间谱基准。
% 弱反射和邻近峰的 FWHM 易受混叠影响，因此这里仅展示峰位偏差，
% 峰宽 / 分辨能力应结合图 8 对光谱逐点观察。
    probe=results.probe_k+1;
    e=results.nufft.spectrum(probe)-results.nudft_sparse;
    q=results.nudft_sparse;
    metrics.nudft_relative_l2=norm(e)/max(norm(q),realmin);
    metrics.nudft_max_abs_relative=max(abs(e))/max(max(abs(q)),realmin);
    names={'fft_uncalibrated','linear_interp','pchip_interp','nufft_truth'};
    for j=1:numel(names)
        name=names{j};
        signal=results.spectra.(name);
        peaks=nan(numel(signals.z_true_m),1);
        errors=nan(numel(signals.z_true_m),1);
        for qid=1:numel(signals.z_true_m)
            z0=signals.z_true_m(qid);
            range=max(3*results.delta_z_m,0.0025);
            % 近间距反射峰的局部搜索窗避免完全覆盖隔壁真值位置。
            separations=abs(signals.z_true_m-z0);
            separations(separations==0)=inf;
            closest=min(separations);
            range=min(range,0.42*closest);
            ids=find(abs(results.distance_m-z0)<=range);
            if isempty(ids), continue; end
            [~,where]=max(abs(signal(ids)));
            peaks(qid)=results.distance_m(ids(where));
            errors(qid)=peaks(qid)-z0;
        end
        metrics.peaks.(name)=peaks;
        metrics.peak_errors.(name)=errors;
    end
    metrics.theoretical_resolution_m=results.delta_z_m;
    metrics.nufft_gridding_s=results.nufft.gridding_s;
    metrics.nufft_fft_s=results.nufft.fft_s;
    metrics.nufft_deconv_s=results.nufft.deconvolution_s;
    metrics.nufft_total_s=results.nufft.total_s;
    metrics.direct_sparse_s=results.direct_sparse_s;
    metrics.interp_linear_s=results.baselines.time_linear_s;
    metrics.interp_pchip_s=results.baselines.time_pchip_s;
    metrics.weights_mean=mean(results.weights);
    metrics.density_mode=cfg.v3.density_mode;
    metrics.window=cfg.v3.window;
end
