function v7_plot_results(cfg,r)
%V7_PLOT_RESULTS 面向论文假设的三幅诊断图；见 docs/V7_FIGURE_READING_GUIDE.md。
    labels={'Oracle','SSWT','Smoothed','Affine static','SAPC'};
    fig=figure('Name','V7 Figure 1 | Paired nonzero-strain error','Color','w');
    subplot(2,1,1);
    mu=r.summary.mean_core(:);ci=r.summary.core_CI95;
    errorbar(1:5,mu,max(0,mu-ci(:,1)),max(0,ci(:,2)-mu),'o-','LineWidth',1.2);
    set(gca,'XTick',1:5,'XTickLabel',labels);grid on;
    ylabel('Core strain RMSE (ue)');
    title('Core strain RMSE with independent-trial bootstrap (not pixel CI)');
    subplot(2,1,2);
    plot(1:5,r.summary.mean_holdout(:),'o-');hold on;
    yyaxis right;plot(1:5,100*r.summary.mean_valid(:),'s--');
    set(gca,'XTick',1:5,'XTickLabel',labels);grid on;
    ylabel('Valid gauges (%)');yyaxis left;ylabel('Held-out static false strain (ue)');
    title('Do not accept a method that only improves trained static segment');
    savefigpng(fig,cfg,'v7_fig1_method_comparison.png');
    fig=figure('Name','V7 Figure 2 | Paired trial scatter','Color','w');
    good=r.success;
    plot(r.core_rmse(good,2),r.core_rmse(good,5),'o');hold on;grid on;
    a=axis;lo=min(a([1,3]));hi=max(a([2,4]));plot([lo hi],[lo hi],'k--');
    xlabel('Raw SSWT core RMSE (ue)');ylabel('SAPC core RMSE (ue)');
    title('Each dot = one paired trial; below diagonal = SAPC better');
    savefigpng(fig,cfg,'v7_fig2_paired_scatter.png');
    if isfield(r.examples,'z_gauge_m')
        fig=figure('Name','V7 Figure 3 | Physical strain preserved?','Color','w');
        z=r.examples.z_gauge_m;
        plot(z,r.examples.true_microeps,'k--','LineWidth',1.3);hold on;
        plot(z,r.examples.traces{2});plot(z,r.examples.traces{4});
        plot(z,r.examples.traces{5});grid on;ylim([-1 7]);
        xlabel('Gauge midpoint (m)');ylabel('Measured strain (ue)');
        legend('Physical truth','Independent SSWT','Static affine','SAPC','Location','best');
        title('Fit ONLY upstream known static zone; never fit the strained zone');
        savefigpng(fig,cfg,'v7_fig3_strain_preservation.png');
    end
end
function savefigpng(fig,cfg,name)
    if ~cfg.v7.save_results,return;end
    folder=fullfile(cfg.v7.output_dir,'figures');if ~exist(folder,'dir'),mkdir(folder);end
    print(fig,fullfile(folder,name),'-dpng','-r140');
end
