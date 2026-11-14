function r=p2_run_trials(cfg,truth)
%P2_RUN_TRIALS 开发集4应变水平×4种校正坐标的完全配对实验。
% 失败trial保留在预设分母，不能删除与重新选seed。
    p1p2_assert_protocol(cfg);
    n=cfg.p1p2.repeats;
    K=numel(cfg.p1p2.strain_microeps);
    r.dataset='development';
    r.n_trials=n;
    r.strain_microeps=cfg.p1p2.strain_microeps(:).';
    r.labels={'00_Oracle','10_Common','01_Differential','11_Combined'};
    r.success=false(n,1);
    r.failure_id=cell(n,1);
    r.failure_reason=cell(n,1);
    r.seed_scatter=nan(n,1);
    r.seed_ref=nan(n,1);
    r.seed_meas=nan(n,1);
    r.ec_rms_MHz=nan(n,1);
    r.ed_rms_MHz=nan(n,1);
    r.common_core_count=nan(n,1);
    r.common_static_count=nan(n,1);
    r.common_roi_fraction=nan(n,1);
    r.M_core=nan(n,K,4);
    r.M_raw_core=nan(n,K,4);
    r.rmse_core=nan(n,K,4);
    r.rmse_static=nan(n,K,4);
    r.bias_core=nan(n,K,4);
    r.C_core=nan(n,K);
    r.D_core=nan(n,K);
    r.I_core=nan(n,K);
    r.I_raw_core=nan(n,K);
    t0=tic;
    for t=1:n
        r.seed_scatter(t)=cfg.p1p2.scatter_seed_base+(t-1)*cfg.p1p2.scatter_stride;
        r.seed_ref(t)=cfg.p1p2.aux_ref_seed_base+(t-1)*cfg.p1p2.aux_stride;
        r.seed_meas(t)=cfg.p1p2.aux_meas_seed_base+(t-1)*cfg.p1p2.aux_stride;
        try
            out=p2_run_trial(cfg,truth,t);
            r.success(t)=true;
            r.ec_rms_MHz(t)=out.common_error_rms_MHz;
            r.ed_rms_MHz(t)=out.differential_error_rms_MHz;
            r.common_core_count(t)=out.core_count;
            r.common_static_count(t)=out.static_count;
            r.common_roi_fraction(t)=out.common_roi_fraction;
            r.M_core(t,:,:)=reshape(out.M_core,1,K,4);
            r.M_raw_core(t,:,:)=reshape(out.M_raw_core,1,K,4);
            r.rmse_core(t,:,:)=reshape(out.rmse_core,1,K,4);
            r.rmse_static(t,:,:)=reshape(out.rmse_static,1,K,4);
            r.bias_core(t,:,:)=reshape(out.bias_core,1,K,4);
            r.C_core(t,:)=out.C_core;
            r.D_core(t,:)=out.D_core;
            r.I_core(t,:)=out.I_core;
            r.I_raw_core(t,:)=out.I_raw_core;
            if t==1,r.example=out.example;end
        catch ME
            r.failure_id{t}=ME.identifier;
            r.failure_reason{t}=ME.message;
            if cfg.p1p2.verbose
                fprintf(2,'[P2] trial %d failed | %s | %s\n', ...
                    t,ME.identifier,ME.message);
                fprintf(2,'%s\n',getReport(ME,'extended','hyperlinks','off'));
            end
        end
        if cfg.p1p2.verbose
            fprintf('[P2] trial %d/%d, successes %d\n',t,n,nnz(r.success));
        end
    end
    r.elapsed_s=toc(t0);
    r.summary=p2_summary(r,cfg);
end