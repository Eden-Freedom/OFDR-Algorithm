function s=v7b_summarize(r,B,seed)
%V7B_SUMMARIZE 预注册的配对试次统计与失效分母。
% 只有同时成功的 trial 参与数值差值统计；所有失败另行报告。
    good=r.success(:);N=numel(good);idx=find(good);
    s.total=N;s.n_success=nnz(good);s.failures=N-s.n_success;
    s.failure_rate=s.failures/max(1,N);
    s.mean_core=nan(1,5);s.mean_holdout=nan(1,5);
    s.mean_valid=nan(1,5);
    labels={'SSWT','Affine'};comparators=[2 4];
    s.comparisons=struct([]);
    if isempty(idx),return;end
    s.mean_core=mean(r.core_rmse(good,:),1);
    s.mean_holdout=mean(r.static_holdout(good,:),1);
    s.mean_valid=mean(r.valid_fraction(good,:),1);
    for k=1:2
        other=comparators(k);s.comparisons(k).versus=labels{k};
        s.comparisons(k).baseline_column=other;
        a=r.core_rmse(good,other)-r.core_rmse(good,5);
        h=r.static_holdout(good,other)-r.static_holdout(good,5);
        v=r.valid_fraction(good,5)-r.valid_fraction(good,other);
        s.comparisons(k).core_gain_mean=mean(a);
        s.comparisons(k).core_gain_CI95=bootstrap(a,B,seed+100+k);
        s.comparisons(k).holdout_gain_mean=mean(h);
        s.comparisons(k).holdout_gain_CI95=bootstrap(h,B,seed+200+k);
        s.comparisons(k).valid_gain_fraction_mean=mean(v);
        s.comparisons(k).valid_gain_CI95=bootstrap(v,B,seed+300+k);
        s.comparisons(k).wins=nnz(a>0);s.comparisons(k).losses=nnz(a<0);
        s.comparisons(k).ties=nnz(a==0);
        s.comparisons(k).win_rate=s.comparisons(k).wins/numel(a);
        s.comparisons(k).worst_regression=max(0,max(-a));
        s.comparisons(k).mean_regression_on_losses=NaN;
        if any(a<0),s.comparisons(k).mean_regression_on_losses=mean(-a(a<0));end
    end
    s.median_train_count=median(r.train_count(good));
    s.mean_train_rms_gain_rad=mean(r.training_before(good)-r.training_after(good));
end
function ci=bootstrap(x,B,seed)
    [lo,hi]=v6b_bootstrap_ci(x,B,seed);
    ci=[lo hi];
end
