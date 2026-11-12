function [cfg,truth,signals,results,metrics] = main_v3(cfg)
%MAIN_V3 V3 教学入口：真值光频坐标 + NUFFT 空间重构。
% 从仓库根目录：
%   addpath('matlab/v3');
%   [cfg,truth,signals,results,metrics]=main_v3();
% NUFFT/NUDFT 使用真实扫描坐标，V3 **不** 使用 SSWT 估计光频。
% V4 才比较 SSWT+NUFFT，并研究校准误差向空间域的传递。
    here=fileparts(mfilename('fullpath'));
    v1=fullfile(fileparts(here),'v1');
    if exist('simulate_laser_sweep','file')~=2, addpath(v1); end
    if nargin<1 || isempty(cfg),cfg=config_v3();end

    truth=simulate_laser_sweep(cfg);
    signals=simulate_ofdr_signals(cfg,truth);
    validate_v1(cfg,truth,signals);

    N=truth.N;
    u=truth.u(:);  % [0,1)，数值上是 TLS 已知真实非均匀光频坐标
    weights=frequency_density_weights_v3(u,cfg.v3.density_mode);
    w=spectral_window_v3(u,cfg.v3.window);
    data=signals.main(:); % 电域采样值，无需额外重采样或解析信号
    data_apodized=data.*w;
    k=(0:floor(N/2)).';
    dz=cfg.const.c_m_s/(2*cfg.fut.group_index*truth.delta_nu_Hz);
    z=k*dz;

    t=tic;
    nufft=nufft_gaussian_type1_v3(u,data_apodized,weights,k,cfg.v3);
    elapsed_nufft=toc(t);

    t=tic;
    baselines=interp_fft_baselines_v3(u,data,cfg.v3.window);
    elapsed_interp=toc(t); %#ok<NASGU>
    % 故意错误的参考：将等时间采集当作等光频采集，且时间域加相同窗族。
    x_time=(0:N-1)'/N;
    uncal=fft(data.*spectral_window_v3(x_time,cfg.v3.window))/N;

    % 直接 NUDFT 只算 sparse probe；真值附近密集采样，不偷换误差基准。
    stride=cfg.v3.nudft_probe_stride;
    halfwidth=cfg.v3.nudft_peak_halfbins;
    if stride<1 || stride~=floor(stride) || halfwidth<0 || halfwidth~=floor(halfwidth)
        error('NUDFT probe_stride 必须为正整数、peak_halfbins 必须为非负整数。');
    end
    kprobe=(0:stride:floor(N/2)).';
    ktruth=round(signals.z_true_m/dz);
    for j=1:numel(ktruth)
        ext=(max(0,ktruth(j)-halfwidth):min(floor(N/2),ktruth(j)+halfwidth)).';
        kprobe=[kprobe;ext]; %#ok<AGROW>
    end
    kprobe=unique(kprobe);
    t=tic;
    direct_sparse=nudft_reference_v3(u,data_apodized,weights,kprobe);
    elapsed_direct=toc(t);

    results.k=k;
    results.distance_m=z;
    results.delta_z_m=dz;
    results.u=u;
    results.weights=weights;
    results.window=w;
    results.nufft=nufft;
    results.baselines=baselines;
    results.probe_k=kprobe;
    results.nudft_sparse=direct_sparse;
    results.direct_sparse_s=elapsed_direct;
    results.elapsed_nufft_s=elapsed_nufft;
    results.spectra.fft_uncalibrated=uncal(1:numel(k));
    results.spectra.linear_interp=baselines.linear(1:numel(k));
    results.spectra.pchip_interp=baselines.pchip(1:numel(k));
    results.spectra.nufft_truth=nufft.spectrum;

    metrics=evaluate_nufft_v3(results,truth,signals,cfg);
    if cfg.v3.show_benchmark
        results.benchmark=benchmark_nufft_v3(cfg);
    else
        results.benchmark=[];
    end

    fprintf('\n============ OFDR V3 | NUFFT spatial reconstruction ============\n');
    fprintf('N=%d, fs=%.2f kHz, optical bandwidth=%.4f GHz\n', ...
            N,truth.fs_Hz/1e3,truth.delta_nu_Hz/1e9);
    fprintf('Theoretical distance scale dz = %.4f mm (not measured FWHM)\n',dz*1e3);
    fprintf('NUFFT: alpha=%.3g (effective %.4g), J=%d, K=%d, sigma(grid)=%.4f\n', ...
            cfg.v3.alpha,nufft.alpha_effective,cfg.v3.kernel_width,nufft.K,sqrt(nufft.sigma2_bins));
    fprintf('Weighting: %s | window: %s\n',cfg.v3.density_mode,cfg.v3.window);
    fprintf('NUDFT matched probes: %d / %d output bins\n',numel(kprobe),numel(k));
    fprintf('NUFFT/NUDFT relative L2 error (probes): %.3e\n',metrics.nudft_relative_l2);
    fprintf('NUFFT/NUDFT normalized maximum abs error: %.3e\n',metrics.nudft_max_abs_relative);
    fprintf('NUFFT runtime: gridding %.4fs, FFT %.4fs, deconv %.4fs, total %.4fs\n', ...
            nufft.gridding_s,nufft.fft_s,nufft.deconvolution_s,elapsed_nufft);
    fprintf('Direct NUDFT %d sparse k positions took %.4fs (NOT full DFT).\n', ...
            numel(kprobe),elapsed_direct);
    fprintf('Interpolation points requiring tiny endpoint extrapolation: %d\n', ...
            baselines.extrapolated_points);
    fprintf('True reflectors (m): ');fprintf('%.4f ',signals.z_true_m);fprintf('\n');
    fprintf('Estimated NUFFT local peaks (m): ');fprintf('%.4f ',metrics.peaks.nufft_truth);fprintf('\n');
    if ~isempty(results.benchmark)
        fprintf('Benchmark: N, direct NUDFT (s), Gaussian NUFFT (s), relative error\n');
        for i=1:numel(results.benchmark.N)
            b=results.benchmark;
            fprintf('  %5d  %.5f  %.5f  %.3e\n', ...
                b.N(i),b.direct_s(i),b.nufft_s(i),b.relative_error(i));
        end
    end
    fprintf('Reminder: V3 uses TRUE optical-frequency coordinates; SSWT+NUFFT is V4.\n');
    if cfg.v3.plot_enabled
        plot_v3_results(cfg,truth,signals,results,metrics);
    end
end
