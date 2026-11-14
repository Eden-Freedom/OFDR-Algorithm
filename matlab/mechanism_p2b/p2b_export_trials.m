function p2b_export_trials(cfg,r)
%P2B_EXPORT_TRIALS 每个trial×应变×heldout alpha一行，保留失败trial。
    n=r.n_trials;K=numel(r.strains_microeps);
    A=numel(r.test_alpha);rows=n*K*A;
    trial_idx=zeros(rows,1);
    strain=zeros(rows,1);
    alpha=zeros(rows,1);
    success=false(rows,1);
    scatter_seed=nan(rows,1);aux_ref_seed=scatter_seed;aux_meas_seed=scatter_seed;
    common_roi_fraction=nan(rows,1);common_core_count=nan(rows,1);
    ec_rms_MHz=nan(rows,1);
    C_actual=nan(rows,1);C_pred=C_actual;
    pred_linear=C_actual;pred_quadratic=C_actual;
    signed_error=C_actual;gradient_rms=C_actual;gradient_h_difference=C_actual;
    null_abs_error=C_actual;abs_gain_vs_zero=C_actual;
    failure_id=repmat({''},rows,1);
    failure_reason=repmat({''},rows,1);
    z=0;
    for t=1:n
        for j=1:K
            for a=1:A
                z=z+1;
                trial_idx(z)=t;strain(z)=r.strains_microeps(j);
                alpha(z)=r.test_alpha(a);
                success(z)=r.success(t);
                scatter_seed(z)=r.scatter_seed(t);
                aux_ref_seed(z)=r.aux_ref_seed(t);
                aux_meas_seed(z)=r.aux_meas_seed(t);
                common_roi_fraction(z)=r.common_valid_fraction(t);
                common_core_count(z)=r.common_core_count(t);
                ec_rms_MHz(z)=r.ec_rms_MHz(t);
                C_actual(z)=r.C_actual(t,j,a);
                C_pred(z)=r.C_pred(t,j,a);
                pred_linear(z)=r.pred_linear(t,j,a);
                pred_quadratic(z)=r.pred_quadratic(t,j,a);
                signed_error(z)=r.prediction_residual(t,j,a);
                null_abs_error(z)=abs(C_actual(z));
                abs_gain_vs_zero(z)=null_abs_error(z)-abs(signed_error(z));
                gradient_rms(z)=r.gradient_rms(t,j);
                gradient_h_difference(z)=r.gradient_h_difference(t,j);
                failure_id{z}=r.failure_id{t};
                failure_reason{z}=r.failure_reason{t};
            end
        end
    end
    T=table(trial_idx,strain,alpha,success,scatter_seed,aux_ref_seed, ...
        aux_meas_seed,ec_rms_MHz,common_roi_fraction,common_core_count, ...
        C_actual,C_pred,pred_linear,pred_quadratic,signed_error, ...
        null_abs_error,abs_gain_vs_zero, ...
        gradient_rms,gradient_h_difference,failure_id,failure_reason, ...
        'VariableNames',{'trial','strain_ue','alpha','success', ...
        'scatter_seed','aux_ref_seed','aux_meas_seed','ec_rms_MHz', ...
        'common_roi_fraction','common_core_count','C_actual_ue2', ...
        'C_pred_ue2','linear_term_ue2','quadratic_term_ue2', ...
        'actual_minus_pred_ue2','null_prediction_abs_error_ue2', ...
        'abs_gain_vs_zero_ue2','gradient_RMS_ue_per_alpha', ...
        'gradient_h_difference_ue_per_alpha','failure_id','failure_reason'});
    folder=cfg.p2b.output_dir;
    if ~isfolder(folder),mkdir(folder);end
    writetable(T,fullfile(folder,'P2B_DEVELOPMENT_trials.csv'));
end