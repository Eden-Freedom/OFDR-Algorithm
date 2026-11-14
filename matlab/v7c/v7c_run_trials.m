function out=v7c_run_trials(cfg,repeats,dataset,group_idx)
%V7C_RUN_TRIALS 配对的独立散射/辅助噪声试次；失败按分母保留。
    if nargin<4,group_idx=0;end
    v7c_assert_protocol(cfg);
    if ~isscalar(repeats)||repeats<1||repeats~=floor(repeats)
        error('V7c:Trials','trial 次数必须为正整数');
    end
    local=cfg;
    if strcmp(dataset,'development')
        seeds=cfg.v7c.dev_seed_base;
    elseif strcmp(dataset,'frozen_test')
        seeds=cfg.v7c.test_seed_base;
    else
        error('V7c:Dataset','未知试次集: %s',dataset);
    end
    seeds=seeds+group_idx*cfg.v7c.group_seed_stride;
    local.v6.scatter_seed=seeds(1);
    local.v6.aux_seed_ref=seeds(2);local.v6.aux_seed_meas=seeds(3);
    truth=simulate_laser_sweep(local);
    M=6;
    out.dataset=dataset;out.group_idx=group_idx;out.n_trials=repeats;
    out.labels={'oracle','independent_sswt','smoothed_sswt','static_affine','SAPC','CV_SAPC'};
    out.success=false(repeats,1);out.failure_reason=cell(repeats,1);out.failure_id=cell(repeats,1);
    out.seed_scatter=nan(repeats,1);out.seed_ref=nan(repeats,1);out.seed_meas=nan(repeats,1);
    out.core_rmse=nan(repeats,M);out.holdout_rmse=nan(repeats,M);
    out.valid_fraction=nan(repeats,M);out.core_bias=nan(repeats,M);
    out.chosen_alpha=nan(repeats,1);out.fallback=false(repeats,1);
    out.fallback_reason=cell(repeats,1);
    out.cv_affine_rad=nan(repeats,1);out.cv_best_rad=nan(repeats,1);
    out.cv_gain_rad=nan(repeats,1);out.cv_gain_fraction=nan(repeats,1);
    out.data_hessian_rcond=nan(repeats,1);out.jacobian_rank=nan(repeats,1);
    out.train_count=nan(repeats,1);out.extra_peak_MHz=nan(repeats,1);
    out.diff_q_rmse_MHz=nan(repeats,1);out.train_phase_gain_rad=nan(repeats,1);
    out.common_core_count=nan(repeats,1);out.common_holdout_count=nan(repeats,1);
    out.cv_folds_ok=false(repeats,1);
    start=tic;
    for t=1:repeats
        out.seed_scatter(t)=seeds(1)+(t-1)*cfg.v7c.scatter_stride;
        out.seed_ref(t)=seeds(2)+(t-1)*cfg.v7c.aux_stride;
        out.seed_meas(t)=seeds(3)+(t-1)*cfg.v7c.aux_stride;
        try
            trial=v7c_run_trial(local,truth,t);
            if ~trial.valid,error('V7c:InvalidTrial','Trial returned invalid');end
            out.success(t)=true;
            out.core_rmse(t,:)=trial.core_rmse;
            out.holdout_rmse(t,:)=trial.holdout_rmse;
            out.valid_fraction(t,:)=trial.valid_fraction;
            out.core_bias(t,:)=trial.core_bias;
            out.chosen_alpha(t)=trial.gate.alpha;
            out.fallback(t)=trial.gate.fallback;
            out.fallback_reason{t}=trial.gate.reason;
            out.cv_affine_rad(t)=trial.gate.cv_affine_rad;
            out.cv_best_rad(t)=trial.gate.cv_best_rad;
            out.cv_gain_rad(t)=trial.gate.cv_improvement_rad;
            out.cv_gain_fraction(t)=trial.gate.cv_improvement_fraction;
            out.cv_folds_ok(t)=trial.gate.cv_folds_ok;
            out.data_hessian_rcond(t)=trial.data_hessian_rcond;
            out.jacobian_rank(t)=trial.jacobian_rank;
            out.train_count(t)=trial.train_count;
            out.extra_peak_MHz(t)=trial.extra_correction_peak_MHz;
            out.diff_q_rmse_MHz(t)=trial.diff_q_rmse_MHz;
            out.train_phase_gain_rad(t)=trial.train_phase_affine-trial.train_phase_sapc;
            out.common_core_count(t)=trial.common_core_count;
            out.common_holdout_count(t)=trial.common_holdout_count;
            if t==1,out.example=trial.example;end
        catch ME
            out.failure_id{t}=ME.identifier;out.failure_reason{t}=ME.message;
            if cfg.v7c.verbose
                fprintf(2,'[V7c %s] trial %d failed | %s | %s\n', ...
                    dataset,t,ME.identifier,ME.message);
                fprintf(2,'%s\n',getReport(ME,'extended','hyperlinks','off'));
            end
        end
        if cfg.v7c.verbose && (mod(t,10)==0||t==repeats)
            fprintf('[V7c %s] %d/%d complete, valid=%d\n',dataset,t,repeats,nnz(out.success));
        end
    end
    out.elapsed_s=toc(start);
    out.summary=v7c_summarize(out,cfg.v7c.bootstrap_reps,cfg.v7c.bootstrap_seed+group_idx*13);
end
