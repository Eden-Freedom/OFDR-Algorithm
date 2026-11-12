function v5_plot_results(results,cfg)
%V5_PLOT_RESULTS 研究图 A/B/D/E：所有曲线来自已保存 results 的同一数据。
    A=results.A;B=results.B_scale;R=results.B_residual;
    figure('Name','V5 Figure A | FWHM grid convergence','Color','w');
    z=A.step3.z_m*1e3;
    peak=max(abs(A.step3.truth));
    plot(z,abs(A.step3.truth)/peak,'k-','LineWidth',1.4);hold on;
    plot(z,abs(A.step3.sswt)/peak,'Color',[.1 .6 .25],'LineWidth',1.2);
    grid on;xlabel('Distance (mm)');ylabel('Amplitude / true peak');
    title(sprintf('Ideal vs SSWT peak | coarse %.3f mm, fine %.3f mm', ...
        A.coarse_metrics.fwhm_m*1e3,A.reference_fwhm_m*1e3));
    legend('True coordinates','SSWT coordinates','Location','best');
    figure('Name','V5 Figure D | proportional error versus distance','Color','w');
    epsilon=B.scale_ppm;
    for i=1:numel(B.distances_m)
        good=B.valid(i,:);
        plot(epsilon(good),B.incremental_error_m(i,good)*1e3,'o-');hold on;
        plot(epsilon(good),B.predicted_offset_m(i,good)*1e3,'k:');
    end
    grid on;xlabel('Scale error (ppm)');ylabel('Incremental peak displacement (mm)');
    title('Measured shift versus -epsilon z (dotted analytical predictions)');
    figure('Name','V5 Figure E | SSWT residual magnification','Color','w');
    g=R.gamma;mag=nan(size(g));phase=mag;fwhm=mag;
    for i=1:numel(g)
        if R.valid(i)
            m=R.metrics_full{i};
            mag(i)=m.full_magnitude_relative_l2;
            phase(i)=m.fixed_location_phase_delta_rad;
            fwhm(i)=m.fwhm_growth*100;
        end
    end
    subplot(3,1,1);plot(g,mag,'o-');ylabel('Magnitude relative L2');grid on;
    subplot(3,1,2);plot(g,phase,'o-');ylabel('Fixed-position phase (rad)');grid on;
    subplot(3,1,3);plot(g,fwhm,'o-');ylabel('FWHM growth (%)');
    xlabel('SSWT error multiplier');grid on;
    title('NaN / missing marker = failed validity gate, not silently corrected');
    if isfield(results,'D')
        D=results.D;
        figure('Name','V5 Figure B | SSWT error decomposition','Color','w');
        plot(D.baseline.time_s*1e3,D.baseline.q_error_Hz/1e6);hold on;
        plot(D.baseline.time_s*1e3,D.baseline.q_decomposition.fitted_Hz/1e6,'--');
        xlabel('Time (ms)');ylabel('Optical-frequency error (MHz)');
        legend('SSWT total error','Weighted affine component','Location','best');grid on;
    end
    if isfield(results,'B_families')
        F=results.B_families;
        figure('Name','V5 Figure C | equal-RMS error families','Color','w');
        rmsidx=find(abs(F.target_rms_MHz-1.71)<.01,1);
        if isempty(rmsidx),rmsidx=ceil(numel(F.target_rms_MHz)/2);end
        errors=nan(numel(F.types),1);
        for i=1:numel(F.types)
            if F.valid(i,rmsidx,1)
                errors(i)=F.full{i,rmsidx,1}.full_magnitude_relative_l2;
            end
        end
        bar(errors);set(gca,'XTick',1:numel(F.types),'XTickLabel',F.types);
        xtickangle(35);ylabel('Magnitude relative L2');grid on;
    end
    if isfield(results,'E')
        E=results.E;
        figure('Name','V5 Figure H | doublet discrimination','Color','w');
        plot(E.gaps_mm,E.truth_success_rate,'k--o');hold on;
        plot(E.gaps_mm,E.sswt_success_rate,'-o');ylim([0 1]);grid on;
        xlabel('Doublet gap (mm)');ylabel('Discrimination success fraction');
        legend('True coordinate','SSWT coordinate','Location','best');
    end
    figure('Name','V5 Figure F | spatial tolerance map','Color','w');
    mapped=abs(B.incremental_error_m)*1e3;
    imagesc(1:numel(B.scale_ppm),B.distances_m,mapped);axis xy;colorbar;
    set(gca,'XTick',1:numel(B.scale_ppm), ...
        'XTickLabel',arrayfun(@num2str,B.scale_ppm(:).','UniformOutput',false));
    xlabel('Injected scale error (ppm; categorical spacing)');ylabel('Reflector distance (m)');
    title('Incremental peak shift (mm); invalid cases shown blank');
    if isfield(results,'D_snr')
        Dsnr=results.D_snr;
        figure('Name','V5 Figure G | auxiliary SNR and reconstruction','Color','w');
        subplot(2,1,1);errorbar(Dsnr.snr_dB,Dsnr.mean(:,3),Dsnr.std(:,3),'o-');
        xlabel('Auxiliary SNR (dB)');ylabel('Optical-frequency RMSE (MHz)');grid on;
        subplot(2,1,2);plot(Dsnr.snr_dB,Dsnr.mean(:,6),'o-');hold on;
        plot(Dsnr.snr_dB,Dsnr.failure_rate,'x-');
        xlabel('Auxiliary SNR (dB)');ylabel('Magnitude rel.L2 / failure fraction');
        legend('Magnitude spectrum error','All-trial failure fraction');grid on;
    end
    if cfg.v5.save_results
        f=fullfile(cfg.v5.output_dir,'v5_figures');
        if ~exist(f,'dir'),mkdir(f);end
        figs=findall(0,'Type','figure');
        for i=1:numel(figs)
            nm=get(figs(i),'Name');
            if strncmp(nm,'V5 ',3)
                safe=regexprep(nm,'[^a-zA-Z0-9]','_');
                print(figs(i),fullfile(f,[safe '.png']),'-dpng','-r150');
            end
        end
    end
end
