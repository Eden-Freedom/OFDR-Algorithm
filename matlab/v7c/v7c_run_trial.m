function out=v7c_run_trial(cfg,truth,trial_index)
%V7C_RUN_TRIAL 零泄漏的六方法配对试验：Oracle/原始/平滑/仿射/SAPC/CV-SAPC。
% 所有最终应变和真实坐标只用于评分，不进入 CV 或 SAPC 参数拟合。
    local=cfg;
    local.v6.scatter_seed=cfg.v6.scatter_seed+(trial_index-1)*cfg.v7c.scatter_stride;
    local.v6.aux_seed_ref=cfg.v6.aux_seed_ref+(trial_index-1)*cfg.v7c.aux_stride;
    local.v6.aux_seed_meas=cfg.v6.aux_seed_meas+(trial_index-1)*cfg.v7c.aux_stride;
    out.seed_scatter=local.v6.scatter_seed;
    out.seed_ref=local.v6.aux_seed_ref;out.seed_meas=local.v6.aux_seed_meas;
    [rawscatter,scatter]=v6_rayleigh_signal(local,truth);
    source=struct('ref_signal',rawscatter,'scatter',scatter);
    pair=v6c_forward_pair(local,truth,local.v7.strain_microeps,source);
    qtrue=truth.nu_offset_Hz(:);  % ONLY oracle branch and scoring
    ar=v6_estimate_aux(local,truth,local.v6.aux_seed_ref);
    am=v6_estimate_aux(local,truth,local.v6.aux_seed_meas);
    ref=v6_reconstruct_trace(local,truth,pair.reference_signal,ar.q_est_Hz);
    oracle_ref=v6_reconstruct_trace(local,truth,pair.reference_signal,qtrue);
    base=v6_reconstruct_trace(local,truth,pair.measurement_signal,am.q_est_Hz);
    smoothq=v7_smooth_aux(local,truth,am);
    smoothtrace=v6_reconstruct_trace(local,truth,pair.measurement_signal,smoothq);
    affine=v7_static_phase_fit(local,truth,ref,pair.measurement_signal,am.q_est_Hz,'affine');
    sapc=v7_static_phase_fit(local,truth,ref,pair.measurement_signal,am.q_est_Hz,'full');
    gate=v7c_cv_gate(local,truth,ref,pair.measurement_signal,am.q_est_Hz,affine,sapc);
    qc=affine.q_corrected_Hz(:)+gate.alpha*(sapc.q_corrected_Hz(:)-affine.q_corrected_Hz(:));
    if any(diff(qc)<=0) || max(abs(qc-am.q_est_Hz(:))) > local.v7.max_correction_MHz*1e6
        % 如果 CV 选择的 α 在完整训练段拟合后失效，强制退回已验证的 affine。
        % 不能排序或截断光频坐标来隐藏超限。
        gate.alpha=0;gate.fallback=true;
        gate.reason='full-fit mixed-coordinate gate: fallback to affine';
        qc=affine.q_corrected_Hz(:);
    end
    adaptive=v6_reconstruct_trace(local,truth,pair.measurement_signal,qc);
    oracle_meas=v6_reconstruct_trace(local,truth,pair.measurement_signal,qtrue);
    refs={oracle_ref,ref,ref,ref,ref,ref};
    traces={oracle_meas,base,smoothtrace,affine.measurement_trace,sapc.measurement_trace,adaptive};
    labels={'oracle','independent_sswt','smoothed_sswt','static_affine','SAPC','CV_SAPC'};
    out.labels=labels;out.metrics=cell(6,1);out.valid=false;out.failure_reason='';
    common_valid=[];core=[];holdout=[];
    for k=1:6
        mm=v6c_demodulate_strain(local,refs{k},traces{k},oracle_ref,pair.geometry);
        if ~mm.valid,error('V7c:InvalidGauge','method %s has invalid gauge output',labels{k});end
        out.metrics{k}=mm;
        if k==1
            common_valid=mm.valid_gauge;core=mm.core_valid;
            zz=mm.z_gauge_mid_m;
            holdout=mm.static_valid & zz>=local.v7.test_static_m(1) & ...
                zz<=local.v7.test_static_m(2);
        else
            common_valid=common_valid & mm.valid_gauge;
            core=core & mm.core_valid;
            holdout=holdout & mm.static_valid;
        end
    end
    if nnz(core)<15||nnz(holdout)<15 || nnz(common_valid)/numel(common_valid)<local.v7.minimum_common_valid
        error('V7c:CommonMask','共同 Core / Holdout 位置不足，不能比较六个算法');
    end
    out.core_rmse=nan(1,6);out.holdout_rmse=nan(1,6);
    out.valid_fraction=nan(1,6);out.core_bias=nan(1,6);
    for k=1:6
        m=out.metrics{k];e=m.strain_error_microeps(core);
        out.core_rmse(k)=sqrt(mean(e.^2));out.core_bias(k)=mean(e);
        s=m.measured_gauge_strain_microeps(holdout);
        out.holdout_rmse(k)=sqrt(mean(s.^2));
        out.valid_fraction(k)=m.valid_fraction;
    end
    out.gate=gate;
    out.train_phase_affine=affine.rms_after_rad;
    out.train_phase_sapc=sapc.rms_after_rad;
    out.train_count=sapc.train_count;
    out.data_hessian_rcond=sapc.rcond_data_hessian;
    out.jacobian_rank=sapc.jacobian_rank;
    out.full_correction_peak_MHz=max(abs(sapc.delta_q_Hz))/1e6;
    out.extra_correction_peak_MHz=max(abs(sapc.q_corrected_Hz(:)-affine.q_corrected_Hz(:)))/1e6;
    out.diff_q_rmse_MHz=sqrt(mean((am.q_est_Hz(:)-ar.q_est_Hz(:)).^2))/1e6;
    out.common_core_count=nnz(core);out.common_holdout_count=nnz(holdout);
    out.valid=true;
    if trial_index==1
        out.example.z=zz;
        out.example.true=out.metrics{1}.true_gauge_strain_microeps;
        out.example.strain=cell(6,1);
        for k=1:6
            t=out.metrics{k}.measured_gauge_strain_microeps;
            t(~common_valid)=NaN;
            out.example.strain{k}=t;
        end
        out.example.common_core=core;
    end
end
