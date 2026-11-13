function out=run_v7_trial(cfg,truth,trial_index)
%RUN_V7_TRIAL 五种方法比较；校正器只看上游静态区域相位与辅助SSWT。
    local=cfg;
    local.v6.scatter_seed=cfg.v6.scatter_seed+(trial_index-1)*cfg.v7.scatter_stride;
    local.v6.aux_seed_ref=cfg.v6.aux_seed_ref+(trial_index-1)*cfg.v7.aux_stride;
    local.v6.aux_seed_meas=cfg.v6.aux_seed_meas+(trial_index-1)*cfg.v7.aux_stride;
    out.seed_scatter=local.v6.scatter_seed;
    out.seed_ref=local.v6.aux_seed_ref;out.seed_meas=local.v6.aux_seed_meas;
    [s,scatter]=v6_rayleigh_signal(local,truth);
    source=struct('ref_signal',s,'scatter',scatter);
    pair=v6c_forward_pair(local,truth,local.v7.strain_microeps,source);
    qtrue=truth.nu_offset_Hz(:);
    ar=v6_estimate_aux(local,truth,local.v6.aux_seed_ref);
    am=v6_estimate_aux(local,truth,local.v6.aux_seed_meas);
    ref=v6_reconstruct_trace(local,truth,pair.reference_signal,ar.q_est_Hz);
    oracle_ref=v6_reconstruct_trace(local,truth,pair.reference_signal,qtrue);
    base=v6_reconstruct_trace(local,truth,pair.measurement_signal,am.q_est_Hz);
    smoothq=v7_smooth_aux(local,truth,am);
    smoothtrace=v6_reconstruct_trace(local,truth,pair.measurement_signal,smoothq);
    affine=v7_static_phase_fit(local,truth,ref,pair.measurement_signal,am.q_est_Hz,'affine');
    sapc=v7_static_phase_fit(local,truth,ref,pair.measurement_signal,am.q_est_Hz,'full');
    oraclem=v6_reconstruct_trace(local,truth,pair.measurement_signal,qtrue);
    ref_all={oracle_ref,ref,ref,ref,ref};
    meas_all={oraclem,base,smoothtrace,affine.measurement_trace,sapc.measurement_trace};
    labels={'oracle','independent_sswt','smoothed_sswt','static_affine','SAPC'};
    out.method_names=labels;out.metrics=cell(numel(labels),1);
    out.valid=false;out.failure_reason='';
    validlist=true(numel(labels),1);
    for k=1:numel(labels)
        mm=v6c_demodulate_strain(local,ref_all{k},meas_all{k},oracle_ref,pair.geometry);
        if ~mm.valid,validlist(k)=false;end
        out.metrics{k}=mm;
    end
    if ~all(validlist)
        error('V7:CaseInvalid','有校正方法未通过gauge有效性检查');
    end
    common=out.metrics{1}.valid_gauge;core=out.metrics{1}.core_valid;
    static=out.metrics{1}.static_valid;
    for k=2:numel(labels)
        common=common&out.metrics{k}.valid_gauge;
        core=core&out.metrics{k}.core_valid;
        static=static&out.metrics{k}.static_valid;
    end
    z=out.metrics{1}.z_gauge_mid_m;
    holdout=static & z>=cfg.v7.test_static_m(1)&z<=cfg.v7.test_static_m(2);
    if nnz(core)<15||nnz(holdout)<15 || ...
        nnz(common)/numel(common)<cfg.v7.minimum_common_valid
        error('V7:Mask','共同 core/holdout 有效样本不足');
    end
    out.core_rmse=nan(numel(labels),1);
    out.static_holdout_rmse=nan(numel(labels),1);
    out.full_static_rmse=nan(numel(labels),1);
    out.valid_fraction=nan(numel(labels),1);
    out.core_bias=nan(numel(labels),1);
    for k=1:numel(labels)
        mm=out.metrics{k};
        e=mm.strain_error_microeps(core);
        out.core_rmse(k)=sqrt(mean(e.^2));
        out.core_bias(k)=mean(e);
        tmp=mm.measured_gauge_strain_microeps(holdout);
        out.static_holdout_rmse(k)=sqrt(mean(tmp.^2));
        tmp=mm.measured_gauge_strain_microeps(static);
        out.full_static_rmse(k)=sqrt(mean(tmp.^2));
        out.valid_fraction(k)=mm.valid_fraction;
    end
    out.common_mask=common;out.common_core=core;out.common_holdout=holdout;
    out.affine_beta_MHz=affine.beta_MHz;out.sapc_beta_MHz=sapc.beta_MHz;
    out.affine_train_phase_before=affine.rms_before_rad;
    out.affine_train_phase_after=affine.rms_after_rad;
    out.sapc_train_phase_before=sapc.rms_before_rad;
    out.sapc_train_phase_after=sapc.rms_after_rad;
    out.q_delta_sswt_MHz=sqrt(mean((am.q_est_Hz-ar.q_est_Hz).^2))/1e6;
    out.valid=true;
    if trial_index==1
        out.example.z_gauge_m=z;
        out.example.true_microeps=out.metrics{1}.true_gauge_strain_microeps;
        out.example.traces=cell(numel(labels),1);
        for k=1:numel(labels)
            tmp=out.metrics{k}.measured_gauge_strain_microeps;
            tmp(~common)=NaN;out.example.traces{k}=tmp;
        end
        out.example.phase_train_inputs=affine.training_indices;
        out.example.sapc_trajectory_correction_Hz=sapc.delta_q_Hz;
    end
end
