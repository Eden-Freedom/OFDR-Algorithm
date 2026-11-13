function d=v7b_failure_diagnostics(r)
%V7B_FAILURE_DIAGNOSTICS 仅事后解释胜负，不回传优化器；避免盲测调参。
% 与 affine 比较，因为这才是非仿射新方法是否增益的严格对照。
    good=r.success(:);g=find(good);d=struct();
    d.n_success=numel(g);d.n_failed=nnz(~good);
    d.failed_trial_indices=find(~good);
    d.failed_reasons=r.failure_reason(~good);
    if isempty(g)
        d.n_sapc_better=0;d.n_sapc_worse=0;d.details=[];return;
    end
    gain=r.core_rmse(g,4)-r.core_rmse(g,5);
    d.n_sapc_better=nnz(gain>0);d.n_sapc_worse=nnz(gain<0);
    d.n_ties=nnz(gain==0);
    d.better_indices=g(gain>0);d.worse_indices=g(gain<0);
    d.trial_gain_microeps=nan(numel(good),1);d.trial_gain_microeps(g)=gain;
    d.holdout_gain_microeps=nan(numel(good),1);
    d.holdout_gain_microeps(g)=r.static_holdout(g,4)-r.static_holdout(g,5);
    d.train_improvement_rad=nan(numel(good),1);
    d.train_improvement_rad(g)=r.training_before(g)-r.training_after(g);
    % 各 predictor 的均值与对照：观察性结果，仅用于下一版本假设生成。
    predictors={'train_count','hessian_rcond','beta_l2_MHz', ...
                'max_correction_MHz','diff_rmse_MHz', ...
                'aux_ref_rmse_MHz','aux_meas_rmse_MHz'};
    d.predictors=predictors;
    d.better_mean=nan(numel(predictors),1);
    d.worse_mean=nan(numel(predictors),1);
    for k=1:numel(predictors)
        x=r.(predictors{k});
        if any(gain>0),d.better_mean(k)=mean(x(g(gain>0)));end
        if any(gain<0),d.worse_mean(k)=mean(x(g(gain<0)));end
    end
    d.worst_regression_trial=NaN;
    if any(gain<0)
        [~,i]=min(gain);d.worst_regression_trial=g(i);
    end
    d.warning='事后诊断不是因果识别；不能用该批盲测选择超参数后再次宣称独立盲测。';
end
