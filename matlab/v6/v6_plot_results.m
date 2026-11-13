function v6_plot_results(cfg,r)
%V6_PLOT_RESULTS 每图对应一种可证伪假设，图例标注实验条件及物理单位。
% 阅读指南：docs/V6_FIGURE_READING_GUIDE.md。
    t=r.truth.t_s*1e3;
    refs={'common_sswt','independent_sswt','rho_000'};
    labels={'Common SSWT','Independent SSWT','Controlled rho=0'};
    co={[0.15 0.52 0.25],[0.86 0.39 0.12],[0.42 0.35 0.75]};
    %% Figure 1：两次扫描的坐标误差是否共模？
    f1=figure('Name','V6a Figure 1 | Paired calibration residuals','Color','w');
    subplot(2,1,1);
    c=r.cases.independent_sswt;
    plot(t,c.error_ref_Hz/1e6,'Color',[0.12 0.39 0.74]);hold on;
    plot(t,c.error_meas_Hz/1e6,'Color',[0.85 0.31 0.17]);
    grid on;xlabel('Sweep time (ms)');ylabel('Coordinate error (MHz)');
    legend('Reference SSWT','Measurement SSWT','Location','best');
    title('Same true optical-frequency sweep; auxiliary noise seeds differ');
    subplot(2,1,2);
    for i=1:numel(refs)
        c=r.cases.(refs{i});
        plot(t,c.diff_coordinate_Hz/1e6,'Color',co{i},'LineWidth',1.1);hold on;
    end
    grid on;xlabel('Sweep time (ms)');ylabel('Measurement - reference error (MHz)');
    legend(labels,'Location','best');
    title('Differential calibration error: common part cancels');
    saveplot(f1,'V6a_Figure1_paired_residuals.png');
    %% Figure 2：主输出：零应变下出现虚假 gauge 相位/等效应变吗？
    f2=figure('Name','V6a Figure 2 | False strain proxy','Color','w');
    subplot(3,1,1);
    z=r.oracle.z_m;
    p=abs(r.oracle.spectrum);ampdb=20*log10(max(p,realmin)/max(p));
    plot(z,ampdb,'Color',[0.22 0.38 0.66]);hold on;
    th=r.cases.oracle_oracle.metrics.threshold;
    yline(20*log10(th/max(p)),'k:','Gate threshold');
    xlim(cfg.v6.roi_m);grid on;
    ylabel('Oracle amplitude (dB)');
    title('Static simulated Rayleigh speckle and common amplitude gate');
    subplot(3,1,2);
    plot_family('gauge_phase_rad','Gauge phase (rad)');
    title('Gauge phase difference after two reconstructions (ZERO applied strain)');
    subplot(3,1,3);
    plot_family('equivalent_false_strain_microeps','False-strain proxy (microstrain)');
    title(sprintf('Equivalent strain proxy | gauge %.3f mm (actual)', ...
        r.cases.oracle_oracle.metrics.gauge_length_actual_m*1e3));
    xlabel('Gauge center position (m)');
    saveplot(f2,'V6a_Figure2_gauge_phase_and_strain.png');
    %% Figure 3：H1 等 RMSE 不同扫描间相关性
    rho=r.controlled.rho_target;
    phase=nan(size(rho));epsv=phase;diffr=phase;valid=phase;
    for j=1:numel(rho)
        name=sprintf('rho_%03d',round(100*rho(j)));c=r.cases.(name);
        phase(j)=c.metrics.gauge_phase_rmse_rad;
        epsv(j)=c.metrics.false_strain_rmse_microeps;
        diffr(j)=c.diff_coordinate_rmse_MHz;
        valid(j)=c.metrics.valid_fraction;
    end
    f3=figure('Name','V6a Figure 3 | Inter-scan correlation experiment','Color','w');
    subplot(3,1,1);
    plot(rho,diffr,'o-');ylabel('Difference RMSE (MHz)');grid on;
    title('Paired injected errors: equal single-scan RMSE, varying correlation');
    subplot(3,1,2);
    plot(rho,phase,'o-');ylabel('Gauge phase RMS (rad)');grid on;
    title('Mechanism metric: after gauge difference, not a single-scan phase');
    subplot(3,1,3);
    plot(rho,epsv,'o-');hold on;
    ylabel('False strain proxy RMS (microstrain)');xlabel('Inter-scan residual correlation rho');grid on;
    title(sprintf('Validity fraction %.0f%%–%.0f%% (amplitude-gated)', ...
        100*min(valid),100*max(valid)));
    saveplot(f3,'V6a_Figure3_correlation_vs_false_strain.png');

    function plot_family(field,yname)
        for ii=1:numel(refs)
            c=r.cases.(refs{ii});
            if ~c.valid,continue;end
            zmid=c.metrics.z_gauge_mid_m;
            plot(zmid,c.metrics.(field),'Color',co{ii},'LineWidth',0.85);hold on;
        end
        grid on;xlim(cfg.v6.roi_m);ylabel(yname);legend(labels,'Location','best');
    end
    function saveplot(fig,fname)
        if cfg.v6.save_results
            if ~exist(cfg.v6.output_dir,'dir'),mkdir(cfg.v6.output_dir);end
            print(fig,fullfile(cfg.v6.output_dir,fname),'-dpng','-r160');
        end
    end
end
