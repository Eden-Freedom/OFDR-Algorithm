function plot_v4_results(cfg,truth,signals,results,metrics)
%PLOT_V4_RESULTS V4 三组图：联合反射谱、轨迹误差、定量指标对比。
    z=results.z_m;
    spectra=results.spectra;
    refmag=max(abs(spectra.nufft_truth));
    full_max=max(signals.z_true_m)+0.2;
    colors.uncal=[0.22 0.45 0.80];
    colors.nufft=[0.06 0.55 0.24];
    colors.interp=[0.88 0.43 0.09];
    colors.true=[0.12 0.12 0.12];

    figure('Name','Figure 11: V4 | SSWT + NUFFT spatial reconstruction','Color','w');
    subplot(3,1,1);
    draw_comparison(z,spectra,refmag,colors);
    xlim([0 full_max]);ylim([-75 5]);title('OFDR full-FUT reconstruction: SSWT calibration followed by NUFFT');
    xlabel('Distance (m)');ylabel('Amplitude (dB)');
    legend('Raw FFT (uncalibrated)','True coordinate NUFFT','SSWT + NUFFT','SSWT + interpolation FFT', ...
           'Location','southwest');
    for j=1:numel(signals.z_true_m), xline(signals.z_true_m(j),'k:');end

    subplot(3,1,2);
    draw_comparison(z,spectra,refmag,colors);
    xlim(cfg.v4.zoom_range_m); ylim([-70 5]);
    title('Close reflectors: 0.450 m and 0.456 m');
    xlabel('Distance (m)');ylabel('Amplitude (dB)');
    for j=1:min(2,numel(signals.z_true_m)),xline(signals.z_true_m(j),'k:');end

    subplot(3,1,3);
    if ~isempty(results.isolated)
        iso=results.isolated;
        norm_peak=max(abs(iso.nufft_truth));
        plot(z,db(iso.fft_uncalibrated,norm_peak),'Color',colors.uncal);hold on;
        plot(z,db(iso.nufft_truth,norm_peak),'k--','LineWidth',1.3);
        plot(z,db(iso.nufft_sswt,norm_peak),'Color',colors.nufft,'LineWidth',1.0);
        plot(z,db(iso.interp_sswt,norm_peak),'Color',colors.interp);
        xlim(iso.z_true_m+[-0.10 0.10]);ylim([-75 5]);
        xline(iso.z_true_m,'k:');
        title(sprintf('Isolated reflector at %.3f m (power FWHM measured separately)',iso.z_true_m));
        xlabel('Distance (m)');ylabel('Amplitude (dB)');grid on;
    else
        text(0.1,0.5,'Isolated-reflector control disabled'); axis off;
    end
    save_if_requested(cfg,'v4_figure11_spatial_reconstruction.png');

    figure('Name','Figure 12: V4 | Calibration error propagation','Color','w');
    t=truth.t_s*1e3;
    subplot(2,1,1);
    plot(t,truth.nu_offset_Hz/1e9,'k--','LineWidth',1.5);hold on;
    plot(t,results.v2.calibration.sswt.nu_offset_Hz/1e9,'Color',colors.nufft);
    xlabel('Time (ms)');ylabel('Optical-frequency offset (GHz)');
    title('True TLS optical frequency vs SSWT-calibrated trajectory');
    legend('True','SSWT estimate','Location','best');grid on;
    subplot(2,1,2);
    plot(t,(results.estimated_u-results.true_u)*results.nominal_span_Hz/1e6, ...
         'Color',colors.nufft,'LineWidth',1.1);hold on;yline(0,'k:');
    title(sprintf('SSWT optical frequency calibration error: RMSE %.3f MHz', ...
                  metrics.scan_error_rmse_MHz));
    xlabel('Time (ms)');ylabel('Error (MHz)');grid on;
    save_if_requested(cfg,'v4_figure12_frequency_residual.png');

    figure('Name','Figure 13: V4 | Magnitude error and peak-location errors','Color','w');
    subplot(2,1,1);
    labels={'fft_uncalibrated','interp_truth','interp_sswt','nufft_sswt'};
    vals=zeros(numel(labels),1);
    for j=1:numel(labels),vals(j)=metrics.(labels{j}).magnitude_relative_l2;end
    bar(vals);set(gca,'XTick',1:numel(labels),'XTickLabel', ...
        {'Uncal FFT','True interp FFT','SSWT interp FFT','SSWT NUFFT'});
    ylabel('Relative L2 on magnitude');grid on;
    title('Magnitude-spectrum error relative to true-coordinate NUFFT');
    subplot(2,1,2);
    plot(signals.z_true_m(:),metrics.nufft_sswt.errors_m*1e3,'o-','Color',colors.nufft, ...
         'LineWidth',1.2);hold on;
    plot(signals.z_true_m(:),metrics.nufft_truth.errors_m*1e3,'k--o');
    yline(0,'k:');grid on;
    xlabel('True reflector position (m)');ylabel('Peak-location error (mm)');
    legend('SSWT + NUFFT','True + NUFFT','Location','best');
    title('Peak localization (position bin search; not FWHM)');
    save_if_requested(cfg,'v4_figure13_metrics.png');
end

function draw_comparison(z,s,peak,c)
    plot(z,db(s.fft_uncalibrated,peak),'Color',c.uncal);hold on;
    plot(z,db(s.nufft_truth,peak),'k--','LineWidth',1.2);
    plot(z,db(s.nufft_sswt,peak),'Color',c.nufft,'LineWidth',1.2);
    plot(z,db(s.interp_sswt,peak),'Color',c.interp);
    grid on;
end
function y=db(x,peak)
    y=20*log10(max(abs(x),realmin)/max(peak,realmin));
end
function save_if_requested(cfg,file)
    if cfg.v4.save_png
        if ~exist(cfg.v4.output_dir,'dir'), mkdir(cfg.v4.output_dir);end
        print(gcf,fullfile(cfg.v4.output_dir,file),'-dpng','-r150');
    end
end
