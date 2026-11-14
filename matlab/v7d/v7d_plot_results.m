function v7d_plot_results(r,cfg)
%V7D_PLOT_RESULTS 图一均值/配对CI，图二逐试次结果，图三门控与修正幅度。
% 横纵轴均写物理量及单位，逐图阅读见docs/V7D_FIGURE_READING_GUIDE.md。
    s=r.summary;
    if s.n_success==0,return;end
    good=r.success;
    figure('Color','w','Name','V7d Fig 1 | DEV-only mean and paired CI');
    subplot(2,1,1);
    cols=[2 4 5 6 7];
    names={'Raw SSWT','Affine','Full SAPC','V7c','V7d-PF'};
    bar(s.mean_core(cols));grid on;
    set(gca,'XTick',1:5,'XTickLabel',names);
    ylabel('Core strain RMSE (microstrain)');
    title(sprintf('DEV ONLY | %d/%d success, failure %d', ...
        s.n_success,s.total,s.failures));
    subplot(2,1,2);
    % 相对三强基线的配对Core与Holdout的全部试次CI
    ids=2:4;
    gain=[];lo=[];hi=[];
    for k=ids
        c=s.comparisons(k);
        gain=[gain,c.mean_core_gain,c.mean_holdout_gain]; %#ok<AGROW>
        lo=[lo,c.core_CI95(1),c.holdout_CI95(1)]; %#ok<AGROW>
        hi=[hi,c.core_CI95(2),c.holdout_CI95(2)]; %#ok<AGROW>
    end
    errorbar(1:6,gain,gain-lo,hi-gain,'o','LineWidth',1.2);hold on;
    plot([0.5 6.5],[0 0],'k--');hold off;grid on;
    set(gca,'XTick',1:6,'XTickLabel',{'C/A','H/A','C/Full','H/Full', ...
                                    'C/V7c','H/V7c'});
    ylabel('Paired RMSE improvement (microstrain)');
    title('Core (C), Holdout (H); 95% trial bootstrap CI; positive = V7d better');

    figure('Color','w','Name','V7d Fig 2 | DEV-only paired outcomes');
    subplot(2,1,1);
    plot(r.core_rmse(good,6),r.core_rmse(good,7),'o');hold on;
    xx=[min([r.core_rmse(good,6);r.core_rmse(good,7)]), ...
        max([r.core_rmse(good,6);r.core_rmse(good,7)])];
    if xx(1)==xx(2),xx=xx+[-0.01 0.01];end
    plot(xx,xx,'k--');hold off;grid on;
    xlabel('V7c Core RMSE (microstrain)');
    ylabel('V7d-PF Core RMSE (microstrain)');
    title('Below diagonal = new candidate gate better');
    subplot(2,1,2);
    stem(find(good),r.core_rmse(good,6)-r.core_rmse(good,7), ...
         'filled');hold on;
    plot([0.5 r.n_trials+0.5],[0 0],'k--');hold off;grid on;
    xlabel('Paired trial index');
    ylabel('Core gain vs V7c (microstrain)');
    title('All successful trials including no-CV / early-fallback trials');

    figure('Color','w','Name','V7d Fig 3 | DEV-only gate and feasibility');
    subplot(2,1,1);
    histC=s.alpha_counts_v7c;histD=s.alpha_counts_v7d;
    bar([histC(:),histD(:)]);grid on;
    set(gca,'XTick',1:5,'XTickLabel',{'0','.25','.5','.75','1'});
    legend('V7c','V7d-PF','Location','best');
    xlabel('Chosen alpha');ylabel('Number of successful trials');
    title('alpha=0 means affine; changes are NOT guaranteed improvements');
    subplot(2,1,2);
    scatter(r.full_extra_peak_MHz(good),r.alpha_v7d(good), ...
        25,r.core_rmse(good,6)-r.core_rmse(good,7),'filled');
    hold on;
    yl=[-0.05 1.05];
    plot([cfg.v7d.max_extra_correction_MHz ...
          cfg.v7d.max_extra_correction_MHz],yl,'k--');
    ylim(yl);hold off;grid on;colorbar;
    xlabel('Full SAPC extra peak E (MHz)');
    ylabel('Chosen V7d-PF alpha');
    title('Color: paired Core gain vs V7c (microstrain); size-only threshold');
end
