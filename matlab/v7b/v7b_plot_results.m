function v7b_plot_results(cfg,results)
%V7B_PLOT_RESULTS 每张图的含义详见 docs/V7B_FIGURE_READING_GUIDE.md。
    if ~isfield(results,'blind'),return;end
    r=results.blind;good=r.success;
    if ~any(good),return;end
    folder=fullfile(cfg.v7b.output_dir,'figures');
    if cfg.v7b.save_results && ~exist(folder,'dir'),mkdir(folder);end
    figure('Name','V7b Figure 1 | Frozen blind method comparison','Color','w');
    subplot(2,1,1);
    bar([r.summary.mean_core(2) r.summary.mean_core(4) r.summary.mean_core(5)]);
    set(gca,'XTickLabel',{'Raw SSWT','Affine','SAPC'});grid on;
    ylabel('Core RMSE (microstrain)');
    title(sprintf('Frozen hyperparameters | %d/%d successful independent trials',...
        nnz(good),r.n_trials));
    subplot(2,1,2);
    b=r.summary.comparisons(2);ss=r.summary.comparisons(1);
    y=[ss.core_gain_mean,b.core_gain_mean, ...
       ss.holdout_gain_mean,b.holdout_gain_mean];
    lo=[ss.core_gain_CI95(1),b.core_gain_CI95(1),...
        ss.holdout_gain_CI95(1),b.holdout_gain_CI95(1)];
    hi=[ss.core_gain_CI95(2),b.core_gain_CI95(2),...
        ss.holdout_gain_CI95(2),b.holdout_gain_CI95(2)];
    errorbar(1:4,y,max(0,y-lo),max(0,hi-y),'o','LineWidth',1.5);hold on;
    plot([.5 4.5],[0 0],'k--');grid on;
    set(gca,'XTick',1:4,'XTickLabel',{'Core vs raw','Core vs affine','Holdout vs raw','Holdout vs affine'});
    ylabel('Paired improvement (microstrain)');
    title('Trial-level bootstrap 95% CI; above zero = SAPC better');
    savefig(cfg,folder,'v7b_figure1_blind_comparison.png');

    figure('Name','V7b Figure 2 | Individual paired wins and regressions','Color','w');
    subplot(2,1,1);
    x=r.core_rmse(good,4);y=r.core_rmse(good,5);
    plot(x,y,'o');hold on;grid on;lims=[min([x;y]) max([x;y])];
    if lims(1)==lims(2),lims=lims+[-.001 .001];end
    plot(lims,lims,'k--');
    xlabel('Static affine Core RMSE (microstrain)');
    ylabel('SAPC Core RMSE (microstrain)');
    title(sprintf('%d improve, %d regress, %d tie | below y=x is better',...
        b.wins,b.losses,b.ties));
    subplot(2,1,2);
    plot(r.training_before(good)-r.training_after(good),...
         r.core_rmse(good,4)-r.core_rmse(good,5),'o');hold on;
    plot(xlim,[0 0],'k--');grid on;
    xlabel('Training-region phase RMS improvement (rad)');
    ylabel('Held-out Core gain vs affine (microstrain)');
    title('Training loss reduction DOES NOT guarantee generalized strain accuracy');
    savefig(cfg,folder,'v7b_figure2_paired_trials.png');

    figure('Name','V7b Figure 3 | Identifiability and failures','Color','w');
    subplot(2,1,1);
    rc=r.data_hessian_rcond(good);
    semilogx(max(rc,eps),r.core_rmse(good,4)-r.core_rmse(good,5),'o');hold on;
    plot(xlim,[0 0],'k--');grid on;
    xlabel('Unregularized data-Hessian rcond (higher = better identified)');
    ylabel('SAPC Core gain vs affine (microstrain)');
    title('Observational diagnostic; correlation is not causation');
    subplot(2,1,2);
    plot(r.max_correction_MHz(good),r.core_rmse(good,4)-r.core_rmse(good,5),'o');hold on;
    plot(xlim,[0 0],'k--');grid on;
    xlabel('Maximum fitted frequency correction (MHz)');
    ylabel('SAPC Core gain vs affine (microstrain)');
    title('Regressions and failures retained in CSV, not used to retune the blind set');
    savefig(cfg,folder,'v7b_figure3_diagnostics.png');

    if isfield(results,'conditions')
        s=results.conditions;
        figure('Name','V7b Figure 4 | Prespecified physical sweeps','Color','w');
        bar(s.summary_table(:,5));hold on;grid on;plot(xlim,[0 0],'k--');
        set(gca,'XTick',1:numel(s.conditions),'XTickLabel',{s.conditions.name});
        xtickangle(50);
        ylabel('SAPC Core gain vs affine (microstrain)');
        title(sprintf('Physical-parameter conditions; %d trials/condition, failure counts in CSV',...
                      s.requested_repeats));
        savefig(cfg,folder,'v7b_figure4_condition_sweep.png');
    end
end
function savefig(cfg,folder,name)
    if cfg.v7b.save_results,print(gcf,fullfile(folder,name),'-dpng','-r140');end
end
