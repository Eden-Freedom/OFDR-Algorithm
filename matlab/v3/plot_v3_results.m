function plot_v3_results(cfg,truth,signals,results,metrics)
%PLOT_V3_RESULTS V3 三幅图：Gaussian 网格化、空间谱对照、精度耗时。
% 所有数据与坐标均为真值光频；图 8 无 SSWT 估计误差。
    u=truth.u(:);t_ms=truth.t_s*1e3;
    k=results.k;
    z=results.distance_m;
    dz=results.delta_z_m;
    ref=max(abs(results.spectra.nufft_truth));
    normalised_db=@(v) 20*log10(max(abs(v),1e-12*max(ref,realmin))/max(ref,realmin));

    figure('Name','Figure 7: V3 | Gaussian Gridding explanation','Color','w');
    subplot(2,2,1);
    plot(t_ms(1:end-1),diff(u)*truth.delta_nu_Hz/1e6,'LineWidth',1.1);grid on;
    xlabel('Time (ms)');ylabel('Optical frequency step (MHz)');
    title('Nonuniform frequency sampling (known truth)');
    subplot(2,2,2);
    % 使用 K*u 图示一个样本向邻近整数网格点传播的核函数。
    ix=round(numel(u)*0.47);
    p=results.nufft.K*u(ix);
    J=cfg.v3.kernel_width;
    near=floor(p)+((-floor((J-1)/2)):ceil((J-1)/2));
    g=exp(-((near-p).^2)/(2*results.nufft.sigma2_bins));
    stem(near-p,g,'filled');grid on;
    xlabel('Grid-node displacement from sample');ylabel('Gaussian kernel weight');
    title(sprintf('Local spreading: J = %d, alpha = %.2f',J,results.nufft.alpha_effective));
    subplot(2,2,3);
    plot(k,results.nufft.kernel_ft,'LineWidth',1.1);grid on;
    xlabel('Spatial Fourier index k');ylabel('G(k)');
    title('Kernel response before deconvolution');
    subplot(2,2,4);
    grid_magnitude=abs(results.nufft.grid_signal);
    center=floor(p)+1;
    local=mod(((center-10):(center+10))-1,results.nufft.K)+1;
    stem(-10:10,grid_magnitude(local),'filled');grid on;
    xlabel('Gridding index near one sample');ylabel('Accumulated grid magnitude');
    title('Actual convolution grid (sum of all samples)');
    maybe_save(cfg,'v3_figure7_gridding.png');

    figure('Name','Figure 8: V3 | OFDR spatial reconstruction','Color','w');
    subplot(3,1,1);
    plot(z,normalised_db(results.spectra.fft_uncalibrated),'Color',[0.16 0.47 0.8]);hold on;
    plot(z,normalised_db(results.spectra.linear_interp),'Color',[0.9 0.45 0.13]);
    plot(z,normalised_db(results.spectra.nufft_truth),'Color',[0.12 0.62 0.25],'LineWidth',1.0);
    add_truth_lines(signals.z_true_m);
    xlim([0,min(z(end),max(signals.z_true_m)+0.3)]);ylim([-75 5]);grid on;
    ylabel('Amplitude (dB)');title('Whole FUT: direct FFT (uncalibrated) vs interpolation vs NUFFT');
    legend('Uncalibrated FFT','Linear interpolation + FFT','True-coordinate NUFFT', ...
           'Location','southwest');
    subplot(3,1,2);
    plot(z,normalised_db(results.spectra.fft_uncalibrated),'Color',[0.16 0.47 0.8]);hold on;
    plot(z,normalised_db(results.spectra.linear_interp),'Color',[0.9 0.45 0.13]);
    plot(z,normalised_db(results.spectra.pchip_interp),'Color',[0.58 0.38 0.75]);
    plot(z,normalised_db(results.spectra.nufft_truth),'Color',[0.12 0.62 0.25],'LineWidth',1.1);
    add_truth_lines(signals.z_true_m(1:2));
    xlim([0.43,0.475]);ylim([-75 5]);grid on;
    xlabel('Distance (m)');ylabel('Amplitude (dB)');
    title('Zoomed reflection doublet: 0.450 m and 0.456 m');
    subplot(3,1,3);
    plot(z,normalised_db(results.spectra.fft_uncalibrated),'Color',[0.16 0.47 0.8]);hold on;
    plot(z,normalised_db(results.spectra.pchip_interp),'Color',[0.58 0.38 0.75]);
    plot(z,normalised_db(results.spectra.nufft_truth),'Color',[0.12 0.62 0.25],'LineWidth',1.1);
    add_truth_lines(signals.z_true_m(3));
    xlim([1.15,1.35]);ylim([-75 5]);grid on;
    xlabel('Distance (m)');ylabel('Amplitude (dB)');
    title('Isolated reflector: distortion vs correction');
    maybe_save(cfg,'v3_figure8_spatial.png');

    figure('Name','Figure 9: V3 | NUFFT numerical verification','Color','w');
    subplot(2,1,1);
    plot(z,normalised_db(results.spectra.nufft_truth),'Color',[0.12 0.62 0.25]); hold on;
    kp=results.probe_k+1;
    plot(z(kp),normalised_db(results.nudft_sparse),'k.','MarkerSize',7);
    xlim([0,min(z(end),max(signals.z_true_m)+0.3)]);ylim([-75 5]);grid on;
    xlabel('Distance (m)');ylabel('Amplitude (dB)');
    title('NUFFT full curve; direct NUDFT only on selected indices');
    legend('Gaussian NUFFT','Direct NUDFT (sparse probes)','Location','southwest');
    subplot(2,1,2);
    err=abs(results.nufft.spectrum(kp)-results.nudft_sparse)/ ...
        max(max(abs(results.nudft_sparse)),realmin);
    semilogy(z(kp),max(err,1e-14),'k.');grid on;
    xlabel('Distance (m)');ylabel('Absolute error / NUDFT max');
    title(sprintf('NUFFT approximation error: relative L2 = %.2e',metrics.nudft_relative_l2));
    maybe_save(cfg,'v3_figure9_nudft_error.png');

    if isfield(results,'benchmark') && ~isempty(results.benchmark)
        b=results.benchmark;
        figure('Name','Figure 10: V3 | NUFFT runtime scaling','Color','w');
        subplot(1,2,1);
        loglog(b.N,b.direct_s,'o-','LineWidth',1.2);hold on;
        loglog(b.N,b.nufft_s,'s-','LineWidth',1.2);grid on;
        xlabel('Number of samples');ylabel('MATLAB elapsed (s)');
        legend('Direct NUDFT','Gaussian NUFFT','Location','northwest');
        title('Computation time (small-N numerical benchmark)');
        subplot(1,2,2);
        semilogy(b.N,b.relative_error,'o-','LineWidth',1.2);grid on;
        xlabel('Number of samples');ylabel('Relative complex L2 error');
        title('Gaussian NUFFT vs matching direct NUDFT');
        maybe_save(cfg,'v3_figure10_benchmark.png');
    end
end

function add_truth_lines(z_true)
    for j=1:numel(z_true)
        xline(z_true(j),'k--','LineWidth',0.7,'HandleVisibility','off');
    end
end

function maybe_save(cfg,name)
    if cfg.v3.save_png
        directory=cfg.v3.output_dir;
        if ~exist(directory,'dir'),mkdir(directory);end
        print(gcf,fullfile(directory,name),'-dpng','-r150');
    end
end
