function s=v7c_summarize(r,B,seed)
%V7C_SUMMARIZE 所有结论以 trial 作为独立单位，不能对空间像素 bootstrap。
    s.total=r.n_trials;s.n_success=nnz(r.success);s.failures=s.total-s.n_success;
    s.failure_rate=s.failures/max(1,s.total);
    s.labels=r.labels;
    s.mean_core=nan(1,6);s.mean_holdout=nan(1,6);s.mean_valid=nan(1,6);
    s.gate_rate=NaN;s.fallback_rate=NaN;s.comparisons=struct([]);
    if s.n_success==0,return;end
    good=r.success;
    s.mean_core=mean(r.core_rmse(good,:),1);
    s.mean_holdout=mean(r.holdout_rmse(good,:),1);
    s.mean_valid=mean(r.valid_fraction(good,:),1);
    s.gate_rate=mean(r.chosen_alpha(good)>0);
    s.fallback_rate=mean(r.fallback(good));
    s.cv_valid_rate=mean(r.cv_folds_ok(good));
    cols=[2 4 5];
    for k=1:numel(cols)
        idx=cols(k);
        co=struct();co.versus=r.labels{idx};
        core=r.core_rmse(good,idx)-r.core_rmse(good,6);
        hold=r.holdout_rmse(good,idx)-r.holdout_rmse(good,6);
        valid=r.valid_fraction(good,6)-r.valid_fraction(good,idx);
        co.core_gain_mean=mean(core);co.core_gain_CI95=boot(core,B,seed+10*k);
        co.holdout_gain_mean=mean(hold);co.holdout_gain_CI95=boot(hold,B,seed+10*k+1);
        co.valid_gain_mean=mean(valid);co.valid_gain_CI95=boot(valid,B,seed+10*k+2);
        co.wins=nnz(core>0);co.losses=nnz(core<0);co.ties=nnz(core==0);
        co.win_rate=co.wins/numel(core);
        co.worst_regression=max([0;-core(:)]);
        co.mean_regression_on_losses=NaN;
        if any(core<0),co.mean_regression_on_losses=mean(-core(core<0));end
        co.core_gain_trial=nan(r.n_trials,1);co.core_gain_trial(good)=core;
        s.comparisons(k)=co;
    end
    s.selection_alpha_counts=zeros(1,5);
    choices=[0 .25 .5 .75 1];
    for j=1:5,s.selection_alpha_counts(j)=nnz(abs(r.chosen_alpha(good)-choices(j))<1e-12);end
    % 事后分组只用于诊断，不能在同一批盲测上重新选择门控超参数。
    s.gated_trial_count=nnz(r.chosen_alpha(good)>0);
    s.fallback_trial_count=nnz(r.fallback(good));
    s.notes='Held-out downstream and strained core never used for alpha selection.';
end
function ci=boot(a,B,seed)
    [lo,hi]=v6b_bootstrap_ci(a,B,seed);
    ci=[lo hi];
end
