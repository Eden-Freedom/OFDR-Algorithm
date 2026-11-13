function out=v7b_run_trials(cfg,n,group_idx,tag)
%V7B_RUN_TRIALS 使用 V7 原核执行配对试次；种子与历史 V7 不重合。
% 只提供 trial 级统计样本，不对 gauge 像素做独立样本 bootstrap。
    if nargin<4,tag='blind';end
    v7b_assert_frozen(cfg);
    if ~(isscalar(n)&&isfinite(n)&&n==floor(n)&&n>=1)
        error('V7b:Repetitions','repeats 必须正整数');
    end
    local=cfg; local.v6.scatter_seed=cfg.v7b.scatter_seed_base+group_idx*cfg.v7b.seed_group_stride;
    local.v6.aux_seed_ref=cfg.v7b.aux_ref_seed_base+group_idx*cfg.v7b.seed_group_stride;
    local.v6.aux_seed_meas=cfg.v7b.aux_meas_seed_base+group_idx*cfg.v7b.seed_group_stride;
    local.v7.scatter_stride=cfg.v7b.scatter_stride;
    local.v7.aux_stride=cfg.v7b.aux_stride;
    local.v7.save_results=false;local.v7.make_plots=false;
    truth=simulate_laser_sweep(local);
    M=5;out.labels={'oracle','independent_sswt','smoothed_sswt','static_affine','SAPC'};
    out.tag=tag;out.group_idx=group_idx;out.n_trials=n;out.success=false(n,1);
    out.failure_reason=cell(n,1);out.failure_id=cell(n,1);
    out.seed_scatter=nan(n,1);out.seed_ref=nan(n,1);out.seed_meas=nan(n,1);
    out.core_rmse=nan(n,M);out.static_holdout=nan(n,M);
    out.valid_fraction=nan(n,M);out.core_bias=nan(n,M);
    out.training_before=nan(n,1);out.training_after=nan(n,1);
    out.affine_training_before=nan(n,1);out.affine_training_after=nan(n,1);
    out.hessian_rcond=nan(n,1);out.affine_hessian_rcond=nan(n,1);
    out.data_hessian_rcond=nan(n,1);out.jacobian_rank=nan(n,1);
    out.train_count=nan(n,1);out.beta_l2_MHz=nan(n,1);
    out.max_correction_MHz=nan(n,1);out.affine_correction_MHz=nan(n,1);
    out.diff_rmse_MHz=nan(n,1);out.aux_ref_rmse_MHz=nan(n,1);
    out.aux_meas_rmse_MHz=nan(n,1);
    out.cfg_conditions=struct('aux_snr_dB',local.v6.aux_snr_dB, ...
        'train_static_m',local.v7.train_static_m,'gauge_length_m',local.v6.gauge_length_m, ...
        'strain_microeps',local.v7.strain_microeps,'laser_ripple_a',local.laser.ripple_a);
    t0=tic;
    for j=1:n
        out.seed_scatter(j)=local.v6.scatter_seed+(j-1)*local.v7.scatter_stride;
        out.seed_ref(j)=local.v6.aux_seed_ref+(j-1)*local.v7.aux_stride;
        out.seed_meas(j)=local.v6.aux_seed_meas+(j-1)*local.v7.aux_stride;
        try
            tr=run_v7_trial(local,truth,j);
            if ~tr.valid,error('V7b:TrialInvalid','run_v7_trial 返回无效试次');end
            out.core_rmse(j,:)=tr.core_rmse(:).';
            out.static_holdout(j,:)=tr.static_holdout_rmse(:).';
            out.valid_fraction(j,:)=tr.valid_fraction(:).';
            out.core_bias(j,:)=tr.core_bias(:).';
            out.training_before(j)=tr.sapc_train_phase_before;
            out.training_after(j)=tr.sapc_train_phase_after;
            out.affine_training_before(j)=tr.affine_train_phase_before;
            out.affine_training_after(j)=tr.affine_train_phase_after;
            out.hessian_rcond(j)=tr.sapc_hessian_rcond;
            out.data_hessian_rcond(j)=tr.sapc_data_hessian_rcond;
            out.jacobian_rank(j)=tr.sapc_jacobian_rank;
            out.affine_hessian_rcond(j)=tr.affine_hessian_rcond;
            out.train_count(j)=tr.sapc_train_count;
            out.beta_l2_MHz(j)=tr.sapc_beta_l2_MHz;
            out.max_correction_MHz(j)=tr.sapc_correction_peak_MHz;
            out.affine_correction_MHz(j)=tr.affine_correction_peak_MHz;
            out.diff_rmse_MHz(j)=tr.q_delta_sswt_MHz;
            out.aux_ref_rmse_MHz(j)=tr.aux_rmse_ref_MHz;
            out.aux_meas_rmse_MHz(j)=tr.aux_rmse_meas_MHz;
            out.success(j)=true;
        catch ME
            out.failure_reason{j}=ME.message;out.failure_id{j}=ME.identifier;
            if cfg.v7b.verbose
                fprintf('[V7b %s] failure %d/%d: %s\n',tag,j,n,ME.message);
            end
        end
        if cfg.v7b.verbose && (mod(j,10)==0 || j==n)
            fprintf('[V7b %s] %d/%d trials finished, %d valid\n',...
                tag,j,n,nnz(out.success(1:j)));
        end
    end
    out.runtime_s=toc(t0);
    out.summary=v7b_summarize(out,cfg.v7b.bootstrap_reps, ...
                               cfg.v7b.bootstrap_seed+group_idx*31);
end
