function v6d_plot_results(cfg,r)
%V6D_PLOT_RESULTS 每张图都应配合 docs/V6D_FIGURE_READING_GUIDE.md。
    labels={'no diff','ramp','nonlinear','full'};
    mu=r.summary.mean_core_rmse(:);ci=r.summary.ci_core;
    fig=figure('Name','V6d Figure 1 | Paired nonzero-strain ablation','Color','w');
    subplot(2,1,1);hold on;
    errorbar(1:4,mu,max(0,mu-ci(:,1)),max(0,ci(:,2)-mu),'o-','LineWidth',1.3);
    set(gca,'XTick',1:4,'XTickLabel',labels);ylabel('Core strain RMSE (microstrain)');grid on;
    title(sprintf('Truth-based decomposition ONLY | %d/%d matched trials', ...
          r.summary.n_success,cfg.v6d.repeats));
    subplot(2,1,2);hold on;
    bar([r.summary.mean_static_rmse(:),r.summary.mean_phase_rmse(:)]);
    set(gca,'XTick',1:4,'XTickLabel',labels);grid on;
    ylabel('Values in own units (see legend)');
    legend('Static false RMS (ue)','Gauge phase RMS (rad)','Location','best');
    title('Do NOT compare the two units by bar height');saveplot(fig,cfg,'v6d_fig1_ablation.png');
    fig=figure('Name','V6d Figure 2 | Trial-level paired comparison','Color','w');
    good=r.trial_success;subplot(2,1,1);
    plot(r.core_rmse(good,4),r.core_rmse(good,3),'o');hold on;grid on;
    ax=axis;low=min(ax([1,3]));high=max(ax([2,4]));plot([low high],[low high],'k--');
    xlabel('Full difference core RMSE (ue)');ylabel('Non-affine only core RMSE (ue)');
    title('Each dot is an independent trial; diagonal = same impact');
    subplot(2,1,2);plot(r.slope_ppm(good),r.nonaffine_weighted_MHz(good),'o');grid on;
    xlabel('Differential anchored slope (ppm)');ylabel('Non-affine weighted RMS (MHz)');
    title('SSWT error structure varies from trial to trial');
    saveplot(fig,cfg,'v6d_fig2_paired_scatter.png');
end
function saveplot(fig,cfg,filename)
    if ~cfg.v6d.save_results,return;end
    f=fullfile(cfg.v6d.output_dir,'figures');if ~exist(f,'dir'),mkdir(f);end
    print(fig,fullfile(f,filename),'-dpng','-r140');
end
