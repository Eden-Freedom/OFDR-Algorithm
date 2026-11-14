function s=v7d_summarize(r,B,seed)
%V7D_SUMMARIZE 7方法共同掩码下，以试次为单位作配对bootstrap。
% 对失败试次保留分母；均值只针对成功试次，需要连同失败率报告。
    s.total=r.n_trials;s.n_success=nnz(r.success);
    s.failures=s.total-s.n_success;
    s.failure_rate=s.failures/max(s.total,1);
    s.labels=r.labels;
    s.mean_core=nan(1,7);
    s.mean_holdout=nan(1,7);
    s.mean_valid=nan(1,7);
    s.mean_common_valid=NaN;
    s.gate_rate_v7c=NaN;s.gate_rate_v7d=NaN;
    s.alpha_counts_v7c=zeros(1,5);
    s.alpha_counts_v7d=zeros(1,5);
    s.comparisons=struct([]);
    if s.n_success==0,return;end
    good=r.success;
    s.mean_core=mean(r.core_rmse(good,:),1);
    s.mean_holdout=mean(r.holdout_rmse(good,:),1);
    s.mean_valid=mean(r.valid_fraction(good,:),1);
    s.mean_common_valid=mean(r.common_valid_fraction(good));
    s.gate_rate_v7c=mean(r.alpha_v7c(good)>0);
    s.gate_rate_v7d=mean(r.alpha_v7d(good)>0);
    choices=[0 .25 .5 .75 1];
    for j=1:5
        s.alpha_counts_v7c(j)=nnz(abs(r.alpha_v7c(good)-choices(j))<1e-12);
        s.alpha_counts_v7d(j)=nnz(abs(r.alpha_v7d(good)-choices(j))<1e-12);
    end
    % 包括原始SSWT/仿射/Full SAPC/未改动的V7c：第7列是V7d。
    columns=[2 4 5 6];
    for j=1:numel(columns)
        c=columns(j);
        gainCore=r.core_rmse(good,c)-r.core_rmse(good,7);
        gainHold=r.holdout_rmse(good,c)-r.holdout_rmse(good,7);
        gainValid=r.valid_fraction(good,7)-r.valid_fraction(good,c);
        co=struct();
        co.versus=r.labels{c};
        co.mean_core_gain=mean(gainCore);
        co.core_CI95=bootstrap(gainCore,B,seed+10*j);
        co.mean_holdout_gain=mean(gainHold);
        co.holdout_CI95=bootstrap(gainHold,B,seed+10*j+1);
        co.mean_valid_gain=mean(gainValid);
        co.valid_CI95=bootstrap(gainValid,B,seed+10*j+2);
        co.wins=nnz(gainCore>0);co.losses=nnz(gainCore<0);
        co.ties=nnz(gainCore==0);
        co.worst_regression=max([0;-gainCore(:)]);
        co.mean_loss=NaN;
        if any(gainCore<0),co.mean_loss=mean(-gainCore(gainCore<0));end
        co.core_gain_trial=nan(r.n_trials,1);
        co.core_gain_trial(good)=gainCore;
        if j==1
            s.comparisons=co; % 先建字段，再追加，避免MATLAB异构结构体错误
        else
            s.comparisons(j)=co;
        end
    end
    s.cv_folds_rate_v7c=mean(r.cv_folds_v7c(good));
    s.cv_folds_rate_v7d=mean(r.cv_folds_v7d(good));
    s.changed_decision_count=nnz(abs(r.alpha_v7c(good)-r.alpha_v7d(good))>1e-12);
    s.full_extra_over_limit_count=nnz(r.full_extra_peak_MHz(good)>0.8);
end

function ci=bootstrap(a,B,seed)
% 单位：trial。n<2时的CI设为NaN，smoke不承担显著性检验任务。
    if numel(a)<2,ci=[NaN NaN];return;end
    [low,high]=v6b_bootstrap_ci(a,B,seed);
    ci=[low high];
end
