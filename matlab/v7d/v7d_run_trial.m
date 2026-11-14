function out=v7d_run_trial(cfg,truth,trial_index)
%V7D_RUN_TRIAL 同一试次对照七方法；第6列是原封不动的V7c CV-SAPC。
% 第7列仅替换成逐候选可行性V7d-PF。所有方法共享瑞利散射、两次
% 辅助干涉信号和物理TLS扫频，最终以七方法共同有效Gauge进行评分。
% 全程只有Oracle评价分支使用真实q(t)，实际校正不使用真值。
    local=cfg;
    local.v6.scatter_seed=cfg.v6.scatter_seed+(trial_index-1)*cfg.v7d.scatter_stride;
    local.v6.aux_seed_ref=cfg.v6.aux_seed_ref+(trial_index-1)*cfg.v7d.aux_stride;
    local.v6.aux_seed_meas=cfg.v6.aux_seed_meas+(trial_index-1)*cfg.v7d.aux_stride;
    out.seed_scatter=local.v6.scatter_seed;
    out.seed_ref=local.v6.aux_seed_ref;
    out.seed_meas=local.v6.aux_seed_meas;

    [rawscatter,scatter]=v6_rayleigh_signal(local,truth);
    source=struct('ref_signal',rawscatter,'scatter',scatter);
    pair=v6c_forward_pair(local,truth,local.v7.strain_microeps,source);
    ar=v6_estimate_aux(local,truth,local.v6.aux_seed_ref);
    am=v6_estimate_aux(local,truth,local.v6.aux_seed_meas);
    q0=am.q_est_Hz(:);
    ref=v6_reconstruct_trace(local,truth,pair.reference_signal,ar.q_est_Hz);
    base=v6_reconstruct_trace(local,truth,pair.measurement_signal,q0);
    smoothedq=v7_smooth_aux(local,truth,am);
    smoothed=v6_reconstruct_trace(local,truth,pair.measurement_signal,smoothedq);
    affine=v7_static_phase_fit(local,truth,ref,pair.measurement_signal,q0,'affine');
    sapc=v7_static_phase_fit(local,truth,ref,pair.measurement_signal,q0,'full');

    % V7c 与 V7d 获得完全相同的候选拟合、参考迹线和辅助估计。
    gatec=v7c_cv_gate(local,truth,ref,pair.measurement_signal,q0,affine,sapc);
    qC=affine.q_corrected_Hz(:)+gatec.alpha* ...
        (sapc.q_corrected_Hz(:)-affine.q_corrected_Hz(:));
    if any(diff(qC)<=0)||max(abs(qC-q0))>local.v7.max_correction_MHz*1e6
        % 与原始V7c_run_trial完全相同的最终回退逻辑。
        gatec.alpha=0;gatec.fallback=true;
        gatec.reason='full-fit mixed-coordinate gate: fallback to affine';
        qC=affine.q_corrected_Hz(:);
    end
    traceC=v6_reconstruct_trace(local,truth,pair.measurement_signal,qC);

    gated=v7d_cv_gate(local,truth,ref,pair.measurement_signal,q0,affine,sapc);
    [okD,detailD,qD]=v7d_candidate_feasible(q0, ...
        affine.q_corrected_Hz,sapc.q_corrected_Hz,gated.alpha, ...
        local.v7d.max_extra_correction_MHz,local.v7d.max_total_correction_MHz);
    if ~okD
        % 非法全段候选属软件逻辑失败；不能无声地转成成功试次。
        error('V7d:FinalCandidate','门控输出未通过最终全段可行性：%s',detailD.reason);
    end
    traceD=v6_reconstruct_trace(local,truth,pair.measurement_signal,qD);

    % 以下才允许使用Oracle真实坐标、几何位移与应变值进行评估。
    qtrue=truth.nu_offset_Hz(:);
    oracleRef=v6_reconstruct_trace(local,truth,pair.reference_signal,qtrue);
    oracleMeas=v6_reconstruct_trace(local,truth,pair.measurement_signal,qtrue);
    refs={oracleRef,ref,ref,ref,ref,ref,ref};
    meas={oracleMeas,base,smoothed,affine.measurement_trace, ...
          sapc.measurement_trace,traceC,traceD};
    names={'oracle','independent_sswt','smoothed_sswt', ...
           'static_affine','SAPC','CV_SAPC_V7c','PF_SAPC_V7d'};
    out.labels=names;
    out.metrics=cell(7,1);
    core=[];holdout=[];common=[];
    for k=1:7
        m=v6c_demodulate_strain(local,refs{k},meas{k},oracleRef,pair.geometry);
        if ~m.valid
            error('V7d:Gauge','%s Gauge有效性检查失败',names{k});
        end
        out.metrics{k}=m;
        if k==1
            core=m.core_valid;
            common=m.valid_gauge;
            zz=m.z_gauge_mid_m;
            holdout=m.static_valid & ...
                zz>=local.v7.test_static_m(1) & ...
                zz<=local.v7.test_static_m(2);
        else
            core=core&m.core_valid;
            common=common&m.valid_gauge;
            holdout=holdout&m.static_valid;
        end
    end
    if nnz(core)<15 || nnz(holdout)<15 || ...
            nnz(common)/numel(common)<local.v7.minimum_common_valid
        error('V7d:CommonMask','七方法共同Gauge数不足，不能比较。');
    end
    out.core_rmse=nan(1,7);
    out.holdout_rmse=nan(1,7);
    out.core_bias=nan(1,7);
    out.valid_fraction=nan(1,7);
    for k=1:7
        m=out.metrics{k};
        coreError=m.strain_error_microeps(core);
        staticStrain=m.measured_gauge_strain_microeps(holdout);
        out.core_rmse(k)=sqrt(mean(coreError.^2));
        out.core_bias(k)=mean(coreError);
        out.holdout_rmse(k)=sqrt(mean(staticStrain.^2));
        out.valid_fraction(k)=m.valid_fraction;
    end
    out.gate_v7c=gatec;
    out.gate_v7d=gated;
    out.full_extra_peak_MHz=max(abs( ...
        sapc.q_corrected_Hz(:)-affine.q_corrected_Hz(:)))/1e6;
    out.final_extra_peak_MHz=detailD.extra_peak_MHz;
    out.final_total_peak_MHz=detailD.total_peak_MHz;
    out.common_core_count=nnz(core);
    out.common_holdout_count=nnz(holdout);
    out.common_valid_fraction=nnz(common)/numel(common);
    out.valid=true;
    if trial_index==1
        out.example.z=zz;
        out.example.true=out.metrics{1}.true_gauge_strain_microeps;
        out.example.strain=cell(7,1);
        for k=1:7
            trace=out.metrics{k}.measured_gauge_strain_microeps;
            trace(~common)=NaN;
            out.example.strain{k}=trace;
        end
        out.example.common_core=core;
    end
end
