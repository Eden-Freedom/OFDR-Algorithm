function out = run_v6b_independent_sswt(cfg,truth)
%RUN_V6B_INDEPENDENT_SSWT 用真实 V2-SSWT 每次独立辅助噪声进行成对重复。
% 与控制误差的 1.71 MHz RMS 注入试验不同：不强制两次 SSWT RMSE 相等。
    nt=cfg.v6b.sswt_repeats;
    out.repeats=nt;
    fields={'reference_rmse_MHz','measurement_rmse_MHz', ...
        'diff_rmse_MHz','gauge_rmse_rad','false_proxy_rmse_microeps', ...
        'valid_fraction','near_wrap_count'};
    for j=1:numel(fields),out.(fields{j})=nan(nt,1);end
    out.valid=false(nt,1);
    out.failure_reason=cell(nt,1);
    out.aux_seed_ref=zeros(nt,1);out.aux_seed_meas=zeros(nt,1);
    out.scatter_seed=zeros(nt,1);
    out.example=struct();
    for t=1:nt
        local=cfg;
        local.v6.aux_seed_ref=cfg.v6.aux_seed_ref+(t-1)*cfg.v6b.aux_seed_stride;
        local.v6.aux_seed_meas=cfg.v6.aux_seed_meas+(t-1)*cfg.v6b.aux_seed_stride;
        local.v6.scatter_seed=cfg.v6.scatter_seed+(t-1)*cfg.v6b.scatter_seed_stride;
        out.aux_seed_ref(t)=local.v6.aux_seed_ref;
        out.aux_seed_meas(t)=local.v6.aux_seed_meas;
        out.scatter_seed(t)=local.v6.scatter_seed;
        try
            [signal,scatter]=v6_rayleigh_signal(local,truth);
            oracle=v6_reconstruct_trace(local,truth,signal,truth.nu_offset_Hz);
            aux_r=v6_estimate_aux(local,truth,local.v6.aux_seed_ref);
            aux_m=v6_estimate_aux(local,truth,local.v6.aux_seed_meas);
            out.reference_rmse_MHz(t)=aux_r.q_rmse_MHz;
            out.measurement_rmse_MHz(t)=aux_m.q_rmse_MHz;
            out.diff_rmse_MHz(t)=sqrt(mean((aux_m.q_est_Hz-aux_r.q_est_Hz).^2))/1e6;
            ref=v6_reconstruct_trace(local,truth,signal,aux_r.q_est_Hz);
            meas=v6_reconstruct_trace(local,truth,signal,aux_m.q_est_Hz);
            met=v6_demodulate_zero_strain(local,ref,meas,oracle);
            if ~met.valid,error('V6b:InvalidGauge','%s',met.failure_reason);end
            out.gauge_rmse_rad(t)=met.gauge_phase_rmse_rad;
            out.false_proxy_rmse_microeps(t)=met.false_strain_rmse_microeps;
            out.valid_fraction(t)=met.valid_fraction;
            out.near_wrap_count(t)=met.near_wrap_count;
            out.valid(t)=true;out.failure_reason{t}='';
            if t==1
                out.example.reference=aux_r;
                out.example.measurement=aux_m;
                out.example.truth=truth;
                out.example.scatterers=scatter;
                out.example.main_signal=signal;
                out.example.metrics=met;
            end
        catch ME
            out.failure_reason{t}=ME.message;
        end
        if cfg.v6b.verbose
            fprintf('[V6b SSWT] %d/%d valid=%d delta %.3f MHz, proxy %.4f ue\n', ...
                t,nt,out.valid(t),out.diff_rmse_MHz(t),out.false_proxy_rmse_microeps(t));
        end
    end
    out.failure_rate=1-nnz(out.valid)/nt;
    good=out.valid;
    if any(good)
        out.mean_proxy_microeps=mean(out.false_proxy_rmse_microeps(good));
        out.mean_gauge_rad=mean(out.gauge_rmse_rad(good));
        [lo,hi]=v6b_bootstrap_ci(out.false_proxy_rmse_microeps(good), ...
            cfg.v6b.bootstrap_reps,cfg.v6b.bootstrap_seed+200);
        out.proxy_CI95_microeps=[lo hi];
    else
        out.mean_proxy_microeps=NaN;out.mean_gauge_rad=NaN;
        out.proxy_CI95_microeps=[NaN NaN];
    end
end
