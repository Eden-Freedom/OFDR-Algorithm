function out=run_v6d_ablation(cfg,truth)
%RUN_V6D_ABLATION 36次非零应变真值消融，四组用同一trial相同散射与同一评估掩码。
% no_diff: ref/meas 均用 ref SSWT; ramp/nonlinear/full: 仅测量坐标增加差值分量。
% 分解用真实 q，属于 ORACLE DIAGNOSTIC，不是可部署校正算法。
    N=cfg.v6d.repeats;
    labels={'no_diff','ramp_only','nonlinear_only','full_diff'};M=numel(labels);
    out.labels=labels;out.seed_scatter=zeros(N,1);out.seed_ref=zeros(N,1);out.seed_meas=zeros(N,1);
    out.core_rmse=nan(N,M);out.static_rmse=nan(N,M);out.gauge_phase_rmse=nan(N,M);
    out.raw_valid_fraction=nan(N,M);out.common_valid_fraction=nan(N,1);
    out.diff_rmse_MHz=nan(N,M);out.valid=false(N,M);out.trial_success=false(N,1);
    out.failure_reason=cell(N,M);out.slope_ppm=nan(N,1);out.nonaffine_weighted_MHz=nan(N,1);
    out.diff_total_rmse_MHz=nan(N,1);out.sum_check_Hz=nan(N,1);
    out.example=struct();
    for j=1:N
        local=cfg;
        local.v6.scatter_seed=cfg.v6.scatter_seed+(j-1)*cfg.v6d.scatter_stride;
        local.v6.aux_seed_ref=cfg.v6.aux_seed_ref+(j-1)*cfg.v6d.aux_stride;
        local.v6.aux_seed_meas=cfg.v6.aux_seed_meas+(j-1)*cfg.v6d.aux_stride;
        out.seed_scatter(j)=local.v6.scatter_seed;
        out.seed_ref(j)=local.v6.aux_seed_ref;out.seed_meas(j)=local.v6.aux_seed_meas;
        try
            [s,scatter]=v6_rayleigh_signal(local,truth);
            source=struct('ref_signal',s,'scatter',scatter);
            pair=v6c_forward_pair(local,truth,cfg.v6d.applied_microeps,source);
            oracle_ref=v6_reconstruct_trace(local,truth,s,truth.nu_offset_Hz);
            a=v6_estimate_aux(local,truth,local.v6.aux_seed_ref);
            b=v6_estimate_aux(local,truth,local.v6.aux_seed_meas);
            d=b.q_est_Hz(:)-a.q_est_Hz(:);
            decomposition=v6b_decompose_error(truth.nu_offset_Hz,d, ...
                oracle_ref.window.*oracle_ref.density);
            if decomposition.reconstruction_max_error_Hz>1e-3
                error('V6d:Decomposition','锚定分解不能重构原始差分误差');
            end
            out.slope_ppm(j)=decomposition.scale_ppm;
            out.nonaffine_weighted_MHz(j)=decomposition.nonlinear_weighted_rmse_Hz/1e6;
            out.diff_total_rmse_MHz(j)=sqrt(mean(d.^2))/1e6;
            out.sum_check_Hz(j)=decomposition.reconstruction_max_error_Hz;
            delta={zeros(size(d)),decomposition.anchored_ramp_Hz, ...
                decomposition.anchored_nonlinear_Hz,d};
            Rr=v6_reconstruct_trace(local,truth,pair.reference_signal,a.q_est_Hz);
            met=cell(M,1);valid=true;
            for k=1:M
                out.diff_rmse_MHz(j,k)=sqrt(mean(delta{k}.^2))/1e6;
                try
                    Rm=v6_reconstruct_trace(local,truth,pair.measurement_signal, ...
                        a.q_est_Hz(:)+delta{k});
                    mm=v6c_demodulate_strain(local,Rr,Rm,oracle_ref,pair.geometry);
                    if ~mm.valid,error('V6d:Invalid','%s',mm.failure_reason);end
                    met{k}=mm;out.valid(j,k)=true;
                    out.raw_valid_fraction(j,k)=mm.valid_fraction;
                catch ME
                    valid=false;out.failure_reason{j,k}=ME.message;
                end
            end
            if valid
                core=met{1}.core_valid;stat=met{1}.static_valid;
                for k=2:M
                    core=core&met{k}.core_valid;
                    stat=stat&met{k}.static_valid;
                end
                common=met{1}.valid_gauge;
                for k=2:M,common=common&met{k}.valid_gauge;end
                eligible=met{1}.z_gauge_mid_m>=cfg.v6.roi_m(1) & ...
                         met{1}.z_gauge_mid_m<=cfg.v6.roi_m(2);
                frac=nnz(common)/max(1,nnz(eligible));out.common_valid_fraction(j)=frac;
                if nnz(core)<15||nnz(stat)<15||frac<cfg.v6d.minimum_common_valid
                    error('V6d:Mask','共同 mask 不足：core %d, static %d, %.1f%%', ...
                          nnz(core),nnz(stat),100*frac);
                end
                for k=1:M
                    err=met{k}.strain_error_microeps(core);
                    sta=met{k}.measured_gauge_strain_microeps(stat);
                    ph=met{k}.phase_error_rad(common);
                    out.core_rmse(j,k)=sqrt(mean(err.^2));
                    out.static_rmse(j,k)=sqrt(mean(sta.^2));
                    out.gauge_phase_rmse(j,k)=sqrt(mean(ph.^2));
                end
                out.trial_success(j)=true;
                if j==1
                    out.example.geometry=pair.geometry;
                    out.example.diff_Hz=d;
                    out.example.ramp_Hz=delta{2};
                    out.example.nonlinear_Hz=delta{3};
                    out.example.z_m=met{1}.z_gauge_mid_m;
                    out.example.valid_core=core;out.example.valid_static=stat;
                    out.example.metrics=met;
                end
            end
        catch ME
            for k=1:M
                if isempty(out.failure_reason{j,k}),out.failure_reason{j,k}=ME.message;end
            end
            out.trial_success(j)=false;
        end
        if cfg.v6d.verbose
            fprintf('V6d trial %d/%d | complete=%d\n',j,N,out.trial_success(j));
        end
    end
    % 对所有效应使用配对trial作为样本单位，而不是将每个空间像素当作独立重复。
    out.summary=struct();out.summary.n_success=nnz(out.trial_success);
    out.summary.failure_rate=1-out.summary.n_success/N;
    good=out.trial_success;
    out.summary.mean_core_rmse=mean(out.core_rmse(good,:),1);
    out.summary.mean_static_rmse=mean(out.static_rmse(good,:),1);
    out.summary.mean_phase_rmse=mean(out.gauge_phase_rmse(good,:),1);
    out.summary.ci_core=nan(M,2);out.summary.ci_static=nan(M,2);
    out.summary.paired_gain_vs_full_core=nan(M,1);
    out.summary.paired_gain_ci=nan(M,2);
    for k=1:M
        [lo,hi]=v6b_bootstrap_ci(out.core_rmse(good,k),cfg.v6d.bootstrap_reps, ...
                                 cfg.v6d.bootstrap_seed+11*k);
        out.summary.ci_core(k,:)=[lo,hi];
        [lo,hi]=v6b_bootstrap_ci(out.static_rmse(good,k),cfg.v6d.bootstrap_reps, ...
                                 cfg.v6d.bootstrap_seed+29*k);
        out.summary.ci_static(k,:)=[lo,hi];
        dv=out.core_rmse(good,4)-out.core_rmse(good,k);
        if ~isempty(dv),out.summary.paired_gain_vs_full_core(k)=mean(dv);end
        [lo,hi]=v6b_bootstrap_ci(dv,cfg.v6d.bootstrap_reps, ...
                                 cfg.v6d.bootstrap_seed+47*k);
        out.summary.paired_gain_ci(k,:)=[lo,hi];
    end
end
