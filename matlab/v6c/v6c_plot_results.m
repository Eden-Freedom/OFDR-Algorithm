function v6c_plot_results(cfg,results)
%V6C_PLOT_RESULTS 每幅图对应可证伪问题；见 docs/V6C_FIGURE_READING_GUIDE.md。
    tests=results.strain_tests;
    eps=results.strain_sweep_microeps(:);
    ix=find(abs(eps-cfg.v6c.strain_microeps)<1e-9,1);
    if isempty(ix),error('V6c:Plot','未找到主应变幅值');end
    t=tests{ix};trial=t.trial;
    names=trial.order;colors=lines(numel(names));
    fig=figure('Name','V6c Figure 1 | known physical strain recovery','Color','w');
    subplot(2,1,1);hold on;
    base=trial.cases.oracle;
    if ~isempty(base.metrics)
        z=base.metrics.z_gauge_mid_m;
        plot(z,base.metrics.true_gauge_strain_microeps,'k-','LineWidth',1.7);
    end
    for i=1:numel(names)
        c=trial.cases.(names{i});if isempty(c.metrics),continue;end
        m=c.metrics;v=m.measured_gauge_strain_microeps;v(~m.valid_gauge)=NaN;
        plot(m.z_gauge_mid_m,v,'Color',colors(i,:),'LineWidth',.8);
    end
    xlim(cfg.v6.roi_m);grid on;
    xlabel('Gauge center position (m)');ylabel('Recovered gauge strain (microstrain)');
    legend([{'Known strain, gauge averaged'},names],'Location','best');
    title(sprintf('Applied %.2f ue | physical Rayleigh phase + delay shift, main noise OFF',eps(ix)));
    subplot(2,1,2);hold on;
    for i=1:numel(names)
        c=trial.cases.(names{i});if isempty(c.metrics),continue;end
        m=c.metrics;e=m.strain_error_microeps;e(~m.valid_gauge)=NaN;
        plot(m.z_gauge_mid_m,e,'Color',colors(i,:));
    end
    plot(cfg.v6.roi_m,[0 0],'k:');xlim(cfg.v6.roi_m);grid on;
    xlabel('Gauge center position (m)');ylabel('Strain error (microstrain)');
    title('Error relative to known gauge-averaged strain; NaN = gated or invalid');
    local_save(fig,cfg,'v6c_fig1_known_strain_recovery.png');

    fig=figure('Name','V6c Figure 2 | strain calibration versus input','Color','w');
    means=nan(numel(eps),numel(names));errs=means;fractions=means;
    for k=1:numel(eps)
        for i=1:numel(names)
            c=tests{k}.trial.cases.(names{i});
            if c.valid
                means(k,i)=c.metrics.core_measured_mean_microeps;
                errs(k,i)=c.metrics.core_strain_rmse_microeps;
                fractions(k,i)=c.metrics.core_valid_fraction;
            end
        end
    end
    subplot(2,1,1);hold on;
    plot(eps,eps,'k--','LineWidth',1.4);
    for i=1:numel(names)
        plot(eps,means(:,i),'o-','Color',colors(i,:),'LineWidth',1.2);
    end
    grid on;xlabel('Applied plateau strain (microstrain)');
    ylabel('Recovered core mean strain (microstrain)');
    legend([{'Ideal y=x'},names],'Location','best');
    title('Nonzero strain sensitivity/linearity; start with ORACLE before judging SSWT');
    subplot(2,1,2);hold on;
    for i=1:numel(names)
        plot(eps,errs(:,i),'o-','Color',colors(i,:),'LineWidth',1.2);
    end
    grid on;xlabel('Applied plateau strain (microstrain)');
    ylabel('Core strain RMSE (microstrain)');
    title('RMSE vs known physical truth (same paired scattering realization)');
    local_save(fig,cfg,'v6c_fig2_strain_sensitivity_rmse.png');

    fig=figure('Name','V6c Figure 3 | static false strain and validity','Color','w');
    stat=nan(numel(eps),numel(names));valid=stat;
    for k=1:numel(eps)
        for i=1:numel(names)
            c=tests{k}.trial.cases.(names{i});
            if c.valid
                stat(k,i)=c.metrics.static_false_strain_rmse_microeps;
                valid(k,i)=100*c.metrics.valid_fraction;
            end
        end
    end
    subplot(2,1,1);bar(eps,stat,'grouped');grid on;
    xlabel('Applied plateau strain (microstrain)');ylabel('Static-zone false strain RMS (microstrain)');
    legend(names,'Location','best');
    title('Do NOT evaluate only strained region: check unstrained fiber for spurious response');
    subplot(2,1,2);plot(eps,valid,'o-');grid on;
    xlabel('Applied plateau strain (microstrain)');ylabel('Valid gauge fraction (%)');
    legend(names,'Location','best');
    title('Amplitude fading / gate dropout must accompany the RMSE');
    local_save(fig,cfg,'v6c_fig3_static_and_validity.png');

    if isfield(results,'mc')
        fig=figure('Name','V6c Figure 4 | independent strain trials','Color','w');
        m=results.mc;subplot(2,1,1);hold on;
        plot(m.oracle_core_rmse,'o-');plot(m.sswt_core_rmse,'o-');grid on;
        xlabel('Independent fiber and auxiliary-noise trial');ylabel('Strain core RMSE (microstrain)');
        legend('Oracle','Independent SSWT','Location','best');
        title(sprintf('%d/%d trials valid; no bootstrap of individual pixels',m.valid_count,numel(m.valid)));
        subplot(2,1,2);plot(100*m.valid_fraction,'o-');grid on;
        xlabel('Independent trial');ylabel('Valid gauge fraction (%)');
        local_save(fig,cfg,'v6c_fig4_independent_strain_trials.png');
    end
end
function local_save(fig,cfg,name)
    if ~cfg.v6c.save_results,return;end
    out=fullfile(cfg.v6c.output_dir,'figures');
    if ~exist(out,'dir'),mkdir(out);end
    print(fig,fullfile(out,name),'-dpng','-r150');
end
