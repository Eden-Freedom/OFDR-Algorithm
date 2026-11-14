function r=p2b_run_trials(cfg,truth)
%P2B_RUN_TRIALS 12组新开发种子；2次smoke是正式开发集的前两次。
% 无论trial失败原因如何，都保留在全部预设trial分母中。
    p2b_assert_protocol(cfg);
    n=cfg.p2b.development_repeats;
    strains=cfg.p2b.strain_microeps;
    alpha=cfg.p2b.test_alpha;
    K=numel(strains);A=numel(alpha);
    r=struct;
    r.dataset='development';
    r.protocol=cfg.p2b.protocol_id;
    r.n_trials=n;
    r.strains_microeps=strains;
    r.test_alpha=alpha;
    r.success=false(n,1);
    r.failure_id=repmat({''},n,1);
    r.failure_reason=repmat({''},n,1);
    r.scatter_seed=nan(n,1);
    r.aux_ref_seed=nan(n,1);
    r.aux_meas_seed=nan(n,1);
    r.ec_rms_MHz=nan(n,1);
    r.common_core_count=nan(n,1);
    r.common_static_count=nan(n,1);
    r.common_valid_fraction=nan(n,1);
    r.common_roi_denominator=nan(n,1);
    r.C_actual=nan(n,K,A);
    r.C_pred=nan(n,K,A);
    r.prediction_residual=nan(n,K,A);
    r.pred_linear=nan(n,K,A);
    r.pred_quadratic=nan(n,K,A);
    r.gradient_rms=nan(n,K);
    r.gradient_h_difference=nan(n,K);
    r.baseline_MSE=nan(n,K);
    r.zero_max_abs_strain_ue=nan(n,1);
    started=tic;
    for t=1:n
        r.scatter_seed(t)=cfg.p2b.scatter_seed_base+(t-1)*cfg.p2b.scatter_stride;
        r.aux_ref_seed(t)=cfg.p2b.aux_ref_seed_base+(t-1)*cfg.p2b.aux_stride;
        r.aux_meas_seed(t)=cfg.p2b.aux_meas_seed_base+(t-1)*cfg.p2b.aux_stride;
        try
            trial=p2b_run_trial(cfg,truth,t);
            r.success(t)=true;
            r.ec_rms_MHz(t)=trial.ec_rms_MHz;
            r.common_core_count(t)=trial.common_core_count;
            r.common_static_count(t)=trial.common_static_count;
            r.common_valid_fraction(t)=trial.common_valid_fraction;
            r.common_roi_denominator(t)=trial.common_roi_denominator;
            r.C_actual(t,:,:)=reshape(trial.C_actual,1,K,A);
            r.C_pred(t,:,:)=reshape(trial.C_pred,1,K,A);
            r.prediction_residual(t,:,:)=reshape(trial.prediction_residual,1,K,A);
            r.pred_linear(t,:,:)=reshape(trial.pred_linear,1,K,A);
            r.pred_quadratic(t,:,:)=reshape(trial.pred_quadratic,1,K,A);
            r.gradient_rms(t,:)=trial.local_gradient_rms;
            r.gradient_h_difference(t,:)=trial.gradient_h_rms_difference;
            r.baseline_MSE(t,:)=trial.mean_baseline_MSE;
            r.zero_max_abs_strain_ue(t)=trial.zero_max_abs_strain_ue;
            if t==1 && isfield(trial,'example')
                r.example=trial.example;
            end
        catch ME
            r.failure_id{t}=ME.identifier;
            r.failure_reason{t}=ME.message;
            if cfg.p2b.verbose
                fprintf(2,'[P2b] trial %d failure | %s | %s\n', ...
                        t,ME.identifier,ME.message);
                fprintf(2,'%s\n',getReport(ME,'extended','hyperlinks','off'));
            end
        end
        if cfg.p2b.verbose
            fprintf('[P2b DEV] %d/%d completed; successful %d\n', ...
                    t,n,nnz(r.success));
        end
    end
    r.elapsed_s=toc(started);
    r.summary=p2b_summarize(r,cfg);
end