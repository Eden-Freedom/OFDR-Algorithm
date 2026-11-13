function out = run_v6c_nonzero_mc(cfg,truth,source)
%RUN_V6C_NONZERO_MC 多对独立 SSWT 噪声+不同散射体的非零应变配对重复。
% 每 trial 以散射体为独立单位；不对数千像素直接 bootstrap。
% 输出所有失败原因；与零应变假应变代理有明确区分。
    n=cfg.v6c.mc_repeats;
    out.applied_microeps=cfg.v6c.strain_microeps;
    out.seed_scatter=zeros(n,1);out.seed_ref=zeros(n,1);out.seed_meas=zeros(n,1);
    out.oracle_core_rmse=nan(n,1);out.sswt_core_rmse=nan(n,1);
    out.oracle_static_rmse=nan(n,1);out.sswt_static_rmse=nan(n,1);
    out.valid_fraction=nan(n,1);out.valid=false(n,1);out.failure_reason=cell(n,1);
    for i=1:n
        local=cfg;
        local.v6.scatter_seed=cfg.v6.scatter_seed+(i-1)*cfg.v6c.mc_scatter_seed_stride;
        local.v6.aux_seed_ref=cfg.v6.aux_seed_ref+(i-1)*cfg.v6c.mc_aux_seed_stride;
        local.v6.aux_seed_meas=cfg.v6.aux_seed_meas+(i-1)*cfg.v6c.mc_aux_seed_stride;
        out.seed_scatter(i)=local.v6.scatter_seed;
        out.seed_ref(i)=local.v6.aux_seed_ref;
        out.seed_meas(i)=local.v6.aux_seed_meas;
        try
            [s,scatter]=v6_rayleigh_signal(local,truth);
            src=struct('ref_signal',s,'scatter',scatter);
            pair=v6c_forward_pair(local,truth,cfg.v6c.strain_microeps,src);
            oracle=v6_reconstruct_trace(local,truth,s,truth.nu_offset_Hz);
            a=v6_estimate_aux(local,truth,local.v6.aux_seed_ref);
            b=v6_estimate_aux(local,truth,local.v6.aux_seed_meas);
            runs=v6c_run_case(local,truth,pair,oracle,a,b);
            A=runs.cases.oracle;B=runs.cases.independent_sswt;
            if ~(A.valid && B.valid),error('V6c:TrialInvalid','invalid oracle/SSWT case');end
            out.oracle_core_rmse(i)=A.metrics.core_strain_rmse_microeps;
            out.sswt_core_rmse(i)=B.metrics.core_strain_rmse_microeps;
            out.oracle_static_rmse(i)=A.metrics.static_false_strain_rmse_microeps;
            out.sswt_static_rmse(i)=B.metrics.static_false_strain_rmse_microeps;
            out.valid_fraction(i)=B.metrics.valid_fraction;
            out.valid(i)=true;out.failure_reason{i}='';
        catch ME
            out.failure_reason{i}=ME.message;
        end
    end
    out.valid_count=nnz(out.valid);
    out.failure_rate=1-out.valid_count/n;
    if out.valid_count>0
        out.mean_oracle_core_rmse=mean(out.oracle_core_rmse(out.valid));
        out.mean_sswt_core_rmse=mean(out.sswt_core_rmse(out.valid));
        out.mean_sswt_static_rmse=mean(out.sswt_static_rmse(out.valid));
    else
        out.mean_oracle_core_rmse=NaN;out.mean_sswt_core_rmse=NaN;
        out.mean_sswt_static_rmse=NaN;
    end
    fprintf('[V6c MC] %d/%d valid. Core RMSE (oracle / SSWT): %.4f / %.4f ue; failures %.1f%%\n', ...
        out.valid_count,n,out.mean_oracle_core_rmse,out.mean_sswt_core_rmse,100*out.failure_rate);
end
