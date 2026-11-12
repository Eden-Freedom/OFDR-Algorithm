function plot_v2_results(cfg,truth,signals,results,metrics)
%PLOT_V2_RESULTS 三组方法的时频图、脊线与光频/波长残差。
% 所有图为 MATLAB 基础函数绘制，可直接保存 PNG 或在本地交互缩放。
    t_ms=truth.t_s*1e3;
    ftrue=signals.aux_beat_Hz/1e3;
    stft=results.stft;
    cwt=results.cwt;
    sswt=results.sswt;
    cal=results.calibration;
    band=[cfg.sswt.f_min_Hz,cfg.sswt.f_max_Hz]/1e3;

    figure('Name','Figure 4: V2 | STFT, CWT, SSWT','Color','w');
    subplot(3,1,1);
    stft_dB=normalised_db(stft.S);
    imagesc(stft.time_s*1e3,stft.freq_axis_Hz/1e3,stft_dB);
    axis xy; ylim(band); caxis([-55,0]); colorbar;
    hold on; plot(t_ms,ftrue,'w--','LineWidth',1.2);
    plot(t_ms,stft.freq_Hz/1e3,'r-','LineWidth',0.8);
    title('STFT (hand-coded Hann window + FFT): white = truth, red = ridge');
    xlabel('Time (ms)'); ylabel('Beat frequency (kHz)');

    subplot(3,1,2);
    imagesc(t_ms,cwt.freq_center_Hz/1e3,normalised_db(cwt.W));
    axis xy; ylim(band); caxis([-55,0]); colorbar;
    hold on; plot(t_ms,ftrue,'w--','LineWidth',1.2);
    plot(t_ms,results.cwt_ridge.freq_Hz/1e3,'r-','LineWidth',0.8);
    title('Complex Morlet CWT: white = truth, red = scale ridge');
    xlabel('Time (ms)'); ylabel('Beat frequency (kHz)');

    subplot(3,1,3);
    imagesc(t_ms,sswt.freq_axis_Hz/1e3,normalised_db(sswt.T));
    axis xy; ylim(band); caxis([-55,0]); colorbar;
    hold on; plot(t_ms,ftrue,'w--','LineWidth',1.2);
    plot(t_ms,results.sswt_ridge.freq_Hz/1e3,'r-','LineWidth',0.8);
    title('SSWT synchrosqueezing: white = truth, red = refined ridge');
    xlabel('Time (ms)'); ylabel('Beat frequency (kHz)');
    maybe_save(cfg,'v2_figure4_time_frequency.png');

    figure('Name','Figure 5: V2 | Beat calibration error','Color','w');
    subplot(2,1,1);
    plot(t_ms,ftrue,'k--','LineWidth',1.6); hold on;
    plot(t_ms,stft.freq_Hz/1e3,'Color',[0.3 0.5 0.75]);
    plot(t_ms,results.cwt_ridge.freq_Hz/1e3,'Color',[0.9 0.5 0.1]);
    plot(t_ms,results.sswt_ridge.freq_Hz/1e3,'Color',[0.2 0.65 0.25]);
    title('Auxiliary MZI instantaneous beat frequency');
    ylabel('Beat frequency (kHz)'); xlabel('Time (ms)'); grid on;
    legend('True','STFT','CWT','SSWT','Location','best');

    subplot(2,1,2);
    plot(t_ms,stft.freq_Hz-signals.aux_beat_Hz,'Color',[0.3 0.5 0.75]); hold on;
    plot(t_ms,results.cwt_ridge.freq_Hz-signals.aux_beat_Hz,'Color',[0.9 0.5 0.1]);
    plot(t_ms,results.sswt_ridge.freq_Hz-signals.aux_beat_Hz,'Color',[0.2 0.65 0.25]);
    yline(0,'k--'); grid on;
    title('Beat-frequency estimation residual (true value subtracted)');
    ylabel('Error (Hz)'); xlabel('Time (ms)');
    legend('STFT','CWT','SSWT','Zero','Location','best');
    maybe_save(cfg,'v2_figure5_beat_error.png');

    figure('Name','Figure 6: V2 | Optical-frequency/wavelength recovery','Color','w');
    subplot(2,2,1);
    plot(t_ms,truth.nu_offset_Hz/1e9,'k--','LineWidth',1.4); hold on;
    plot(t_ms,cal.sswt.nu_offset_Hz/1e9,'Color',[0.1 0.65 0.2]);
    grid on; title('SSWT integrated optical-frequency trajectory');
    xlabel('Time (ms)'); ylabel('Optical-frequency offset (GHz)');
    legend('True','SSWT estimation','Location','best');

    subplot(2,2,2);
    plot(t_ms,(cal.stft.nu_offset_Hz-truth.nu_offset_Hz)/1e6); hold on;
    plot(t_ms,(cal.cwt.nu_offset_Hz-truth.nu_offset_Hz)/1e6);
    plot(t_ms,(cal.sswt.nu_offset_Hz-truth.nu_offset_Hz)/1e6,'LineWidth',1.2);
    grid on; title('Integrated optical-frequency residual');
    xlabel('Time (ms)'); ylabel('Error (MHz)');
    legend('STFT','CWT','SSWT','Location','best');

    subplot(2,2,3);
    plot(t_ms,truth.lambda_m*1e9,'k--','LineWidth',1.4); hold on;
    plot(t_ms,cal.sswt.lambda_m*1e9,'Color',[0.1 0.65 0.2]);
    grid on; title('Recovered instantaneous wavelength');
    xlabel('Time (ms)'); ylabel('Wavelength (nm)');
    legend('True','SSWT estimation','Location','best');

    subplot(2,2,4);
    plot(t_ms,(cal.stft.lambda_m-truth.lambda_m)*1e15); hold on;
    plot(t_ms,(cal.cwt.lambda_m-truth.lambda_m)*1e15);
    plot(t_ms,(cal.sswt.lambda_m-truth.lambda_m)*1e15,'LineWidth',1.2);
    grid on; title('Wavelength calibration residual');
    xlabel('Time (ms)'); ylabel('Error (fm)');
    legend('STFT','CWT','SSWT','Location','best');
    maybe_save(cfg,'v2_figure6_wavelength_error.png');

    fprintf('SSWT wavelength RMSE = %.3f fm (simulation only).\n', ...
             metrics.sswt.wavelength_rmse_fm);
end

function out = normalised_db(A)
    mag=abs(A);
    peak=max(mag(:));
    out=20*log10(mag/max(peak,realmin)+1e-12);
end

function maybe_save(cfg,name)
    if cfg.plot.save_png
        directory=cfg.plot.v2_output_dir;
        if ~exist(directory,'dir'), mkdir(directory); end
        f=fullfile(directory,name);
        print(gcf,f,'-dpng','-r150');
        fprintf('Saved: %s\n',f);
    end
end
