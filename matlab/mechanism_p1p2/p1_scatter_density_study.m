function out=p1_scatter_density_study(cfg,truth)
%P1_SCATTER_DENSITY_STUDY 新开发种子下的散射密度收敛诊断。
% 固定物理扫频、带宽与同一随机复测度，比较oracle非零应变误差。
% 同一个 trial 的各密度使用全部方法共通的Core/ROI空间掩码。
    p1p2_assert_protocol(cfg);
    lev=cfg.p1p2.p1_scat_levels(:).';
    N=cfg.p1p2.p1_scat_repeats;K=numel(lev);
    out.dataset='development';
    out.levels=lev;
    out.step_mm=cfg.v6.scatter_step_m*1000./(2.^lev);
    out.n_trials=N;
    out.success=false(N,1);
    out.failure_id=cell(N,1);
    out.failure_reason=cell(N,1);
    out.seed=nan(N,1);
    out.core_rmse=nan(N,K);
    out.raw_core_rmse=nan(N,K);
    out.holdout_rmse=nan(N,K);
    out.common_valid_roi=nan(N,1);
    out.common_core_count=nan(N,1);
    out.core_counts=nan(N,K);
    for t=1:N
        seed=cfg.p1p2.scatter_seed_base+500000+(t-1)*cfg.p1p2.scatter_stride;
        out.seed(t)=seed;
        try
            mats=cell(K,1);
            for k=1:K
                [reference,scatter]=p1_nested_scatter(cfg,truth,seed,lev(k));
                source=struct('ref_signal',reference,'scatter',scatter);
                pair=v6c_forward_pair(cfg,truth,cfg.p1p2.p1_strain_microeps,source);
                rr=v6_reconstruct_trace(cfg,truth,reference,truth.nu_offset_Hz);
                mm=v6_reconstruct_trace(cfg,truth,pair.measurement_signal,truth.nu_offset_Hz);
                met=v6c_demodulate_strain(cfg,rr,mm,rr,pair.geometry);
                if ~met.valid
                    error('P1:Gauge','level %d 的Gauge失败：%s',lev(k),met.failure_reason);
                end
                mats{k}=met;
                out.core_counts(t,k)=nnz(met.core_valid);
            end
            core=mats{1}.core_valid;
            common=mats{1}.valid_gauge;
            stat=mats{1}.static_valid;
            for k=2:K
                core=core&mats{k}.core_valid;
                common=common&mats{k}.valid_gauge;
                stat=stat&mats{k}.static_valid;
            end
            z=mats{1}.z_gauge_mid_m;
            roi=z>=cfg.v6.roi_m(1)&z<=cfg.v6.roi_m(2);
            frac=nnz(common)/max(1,nnz(roi));
            if nnz(core)<cfg.p1p2.min_common_core || ...
               nnz(stat)<cfg.p1p2.min_common_static || ...
               frac<cfg.p1p2.min_common_roi_fraction
                error('P1:CommonMask','跨离散密度共同有效Core/ROI不足。');
            end
            for k=1:K
                met=mats{k};
                out.core_rmse(t,k)=sqrt(mean(met.strain_error_microeps(core).^2));
                out.raw_core_rmse(t,k)=sqrt(mean(met.raw_strain_error_microeps(core).^2));
                out.holdout_rmse(t,k)=sqrt(mean(met.measured_gauge_strain_microeps(stat).^2));
            end
            out.common_core_count(t)=nnz(core);
            out.common_valid_roi(t)=frac;
            out.success(t)=true;
        catch ME
            out.failure_id{t}=ME.identifier;
            out.failure_reason{t}=ME.message;
            if cfg.p1p2.verbose
                fprintf(2,'[P1 density] trial %d failed | %s | %s\n',t,ME.identifier,ME.message);
            end
        end
    end
    out.failure_rate=1-nnz(out.success)/N;
    out.mean_core=nan(1,K);
    out.mean_raw=nan(1,K);
    out.mean_holdout=nan(1,K);
    out.paired_vs_finest_CI95=nan(K,2);
    if any(out.success)
        out.mean_core=mean(out.core_rmse(out.success,:),1);
        out.mean_raw=mean(out.raw_core_rmse(out.success,:),1);
        out.mean_holdout=mean(out.holdout_rmse(out.success,:),1);
        if nnz(out.success)>=2
            for k=1:K
                delta=out.core_rmse(out.success,k)-out.core_rmse(out.success,end);
                [lo,hi]=v6b_bootstrap_ci(delta,cfg.p1p2.bootstrap_reps, ...
                                    cfg.p1p2.bootstrap_seed+100+k);
                out.paired_vs_finest_CI95(k,:)=[lo hi];
            end
        end
    end
    fprintf('[P1 density] successful %d/%d, failure %.2f%%\n', ...
        nnz(out.success),N,100*out.failure_rate);
    fprintf('Step(mm): ');fprintf(' %.4f',out.step_mm);fprintf('\n');
    fprintf('Mean Oracle Core(ue): ');fprintf(' %.6f',out.mean_core);fprintf('\n');
    fprintf('Mean raw-phasor Core(ue): ');fprintf(' %.6f',out.mean_raw);fprintf('\n');
    fprintf('All level comparisons use a fixed mask per trial; no single-shot convergence claim.\n');
end