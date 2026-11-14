function r=v7d_run_trials(cfg,repeats)
%V7D_RUN_TRIALS 仅新开发种子的逐trial配对实验，全部失败保留分母。
    v7d_assert_protocol(cfg);
    if ~isscalar(repeats)||repeats<1||repeats~=floor(repeats)
        error('V7d:Repeats','试次数必须为正整数。');
    end
    local=cfg;
    seeds=cfg.v7d.dev_seed_base;
    local.v6.scatter_seed=seeds(1);
    local.v6.aux_seed_ref=seeds(2);
    local.v6.aux_seed_meas=seeds(3);
    truth=simulate_laser_sweep(local); % 同一已配置TLS扫频模型
    r.dataset='development';
    r.n_trials=repeats;
    r.labels={'oracle','independent_sswt','smoothed_sswt', ...
       'static_affine','SAPC','CV_SAPC_V7c','PF_SAPC_V7d'};
    r.success=false(repeats,1);
    r.failure_id=cell(repeats,1);
    r.failure_reason=cell(repeats,1);
    r.seed_scatter=nan(repeats,1);
    r.seed_ref=nan(repeats,1);r.seed_meas=nan(repeats,1);
    r.core_rmse=nan(repeats,7);r.holdout_rmse=nan(repeats,7);
    r.core_bias=nan(repeats,7);r.valid_fraction=nan(repeats,7);
    r.alpha_v7c=nan(repeats,1);r.alpha_v7d=nan(repeats,1);
    r.reason_v7c=cell(repeats,1);r.reason_v7d=cell(repeats,1);
    r.cv_folds_v7c=false(repeats,1);r.cv_folds_v7d=false(repeats,1);
    r.cv_gain_v7c=nan(repeats,1);r.cv_gain_v7d=nan(repeats,1);
    r.full_extra_peak_MHz=nan(repeats,1);
    r.final_extra_peak_MHz=nan(repeats,1);
    r.final_total_peak_MHz=nan(repeats,1);
    r.full_candidate_ok=false(repeats,5);
    r.fold_candidate_ok=false(repeats,5);
    r.common_core_count=nan(repeats,1);
    r.common_holdout_count=nan(repeats,1);
    r.common_valid_fraction=nan(repeats,1);
    t0=tic;
    for t=1:repeats
        r.seed_scatter(t)=seeds(1)+(t-1)*cfg.v7d.scatter_stride;
        r.seed_ref(t)=seeds(2)+(t-1)*cfg.v7d.aux_stride;
        r.seed_meas(t)=seeds(3)+(t-1)*cfg.v7d.aux_stride;
        try
            trial=v7d_run_trial(local,truth,t);
            if ~trial.valid,error('V7d:InvalidTrial','试次无效。');end
            r.success(t)=true;
            r.core_rmse(t,:)=trial.core_rmse;
            r.holdout_rmse(t,:)=trial.holdout_rmse;
            r.core_bias(t,:)=trial.core_bias;
            r.valid_fraction(t,:)=trial.valid_fraction;
            r.alpha_v7c(t)=trial.gate_v7c.alpha;
            r.alpha_v7d(t)=trial.gate_v7d.alpha;
            r.reason_v7c{t}=trial.gate_v7c.reason;
            r.reason_v7d{t}=trial.gate_v7d.reason;
            r.cv_folds_v7c(t)=trial.gate_v7c.cv_folds_ok;
            r.cv_folds_v7d(t)=trial.gate_v7d.cv_folds_ok;
            r.cv_gain_v7c(t)=trial.gate_v7c.cv_improvement_fraction;
            r.cv_gain_v7d(t)=trial.gate_v7d.cv_improvement_fraction;
            r.full_extra_peak_MHz(t)=trial.full_extra_peak_MHz;
            r.final_extra_peak_MHz(t)=trial.final_extra_peak_MHz;
            r.final_total_peak_MHz(t)=trial.final_total_peak_MHz;
            r.full_candidate_ok(t,:)=trial.gate_v7d.candidate_full_ok;
            r.fold_candidate_ok(t,:)=all(trial.gate_v7d.candidate_fold_ok,1);
            r.common_core_count(t)=trial.common_core_count;
            r.common_holdout_count(t)=trial.common_holdout_count;
            r.common_valid_fraction(t)=trial.common_valid_fraction;
            if t==1,r.example=trial.example;end
        catch ME
            r.failure_id{t}=ME.identifier;
            r.failure_reason{t}=ME.message;
            if cfg.v7d.verbose
                fprintf(2,'[V7d dev] trial %d failed: %s | %s\n', ...
                    t,ME.identifier,ME.message);
                fprintf(2,'%s\n',getReport(ME,'extended','hyperlinks','off'));
            end
        end
        if cfg.v7d.verbose && (mod(t,10)==0 || t==repeats)
            fprintf('[V7d dev] %d/%d completed; successful %d\n', ...
                t,repeats,nnz(r.success));
        end
    end
    r.elapsed_s=toc(t0);
    r.summary=v7d_summarize(r,cfg.v7d.bootstrap_reps,cfg.v7d.bootstrap_seed);
end
