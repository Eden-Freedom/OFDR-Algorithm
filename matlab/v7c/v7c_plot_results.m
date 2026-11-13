function v7c_plot_results(cfg,results)
%V7C_PLOT_RESULTS 图内直写物理量、单位、比较对象、实验分母；论文判读见 docs。
    if isfield(results,'frozen_test'),r=results.frozen_test;label='FROZEN_TEST';
    elseif isfield(results,'development'),r=results.development;label='DEVELOPMENT';
    else,return;end
    s=r.summary;if s.n_success<1,return;end
    a=s.comparisons(2);b=s.comparisons(3);
    figure('Name',['V7c Fig 1 | ' label ' gated method and CI'],'Color','w');
    subplot(2,1,1);
    names={'Raw SSWT','Static affine','Full SAPC','CV-SAPC'};
    bar([s.mean_core(2),s.mean_core(4),s.mean_core(5),s.mean_core(6)]);set(gca,'XTickLabel',names);
    ylabel('Core strain RMSE (microstrain)');grid on;
    title(sprintf('%s | %d/%d valid trials | gated %.0f%%, fallback %.0f%%', ...
        label,s.n_success,s.total,100*s.gate_rate,100*s.fallback_rate));
    subplot(2,1,2);
    gains=[a.core_gain_mean,b.core_gain_mean,a.holdout_gain_mean,b.holdout_gain_mean];
    low=[a.core_gain_CI95(1),b.core_gain_CI95(1),a.holdout_gain_CI95(1),b.holdout_gain_CI95(1)];
    high=[a.core_gain_CI95(2),b.core_gain_CI95(2),a.holdout_gain_CI95(2),b.holdout_gain_CI95(2)];
    errorbar(1:4,gains,gains-low,high-gains,'o','LineWidth',1.2);hold on;
    plot([0.5 4.5],[0 0],'k--');hold off;
    set(gca,'XTick',1:4,'XTickLabel',{'Core vs affine','Core vs SAPC', ...
        'Holdout vs affine','Holdout vs SAPC'});
    ylabel('Paired RMS improvement (microstrain)');grid on;
    title('Trial-level bootstrap 95% CI; above zero = CV-SAPC better');

    figure('Name',['V7c Fig 2 | ' label ' paired wins and gate'],'Color','w');
    good=r.success;subplot(2,1,1);
    plot(r.core_rmse(good,4),r.core_rmse(good,6),'bo','MarkerSize',5);hold on;
    x=[min([r.core_rmse(good,4);r.core_rmse(good,6)]), ...
       max([r.core_rmse(good,4);r.core_rmse(good,6)])];
    plot(x,x,'k--');hold off;axis tight;grid on;
    xlabel('Static affine Core RMSE (microstrain)');
    ylabel('CV-SAPC Core RMSE (microstrain)');
    title(sprintf('%d wins, %d losses, %d ties; below diagonal = adaptive better', ...
        a.wins,a.losses,a.ties));
    subplot(2,1,2);
    scatter(r.cv_gain_fraction(good)*100,r.core_rmse(good,4)-r.core_rmse(good,6), ...
        20,r.chosen_alpha(good),'filled');hold on;plot(xlim,[0 0],'k--');hold off;grid on;
    xlabel('Upstream blocked-CV phase RMS reduction (%)');
    ylabel('Independent Core improvement (microstrain)');
    title('CV scores are only upstream; test Core NEVER used for gate');
    colorbar;

    figure('Name',['V7c Fig 3 | ' label ' identifiability and fallbacks'],'Color','w');
    subplot(2,1,1);
    scatter(r.data_hessian_rcond(good),r.core_rmse(good,4)-r.core_rmse(good,6), ...
        25,r.chosen_alpha(good),'filled');hold on;
    plot(xlim,[0 0],'k--');hold off;grid on;colorbar;
    xlabel('Unregularized data-Hessian rcond');ylabel('Core gain vs affine (microstrain)');
    title('Observational diagnostic only; condition number is not ground-truth error');
    subplot(2,1,2);
    counts=s.selection_alpha_counts;
    bar([0 .25 .5 .75 1],counts);grid on;
    xlabel('CV-chosen non-affine mixing alpha');ylabel('Number of trials');
    title('alpha=0 means affine fallback; no post-test parameter tuning');
end
