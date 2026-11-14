function out=p1_run_oracle_nudft(cfg,truth)
%P1_RUN_ORACLE_NUDFT 一个新开发散射实现，用精确NUDFT检查当前NUFFT。
    local=cfg;
    local.v6.scatter_seed=cfg.p1p2.scatter_seed_base+200000;
    [sig,scatter]=v6_rayleigh_signal(local,truth);
    pair=v6c_forward_pair(local,truth,cfg.p1p2.p1_strain_microeps, ...
        struct('ref_signal',sig,'scatter',scatter));
    out=p1_oracle_nudft_check(local,truth,pair);
    out.scatter_seed=local.v6.scatter_seed;
    fprintf('[P1 NUDFT] checked %d complex k bins | ref relL2=%.3g meas relL2=%.3g\n', ...
        out.tested_bins,out.rel_l2(1),out.rel_l2(2));
    fprintf('[P1 NUDFT] ref phaseRMSE=%.3g rad, meas phaseRMSE=%.3g rad\n', ...
        out.phase_rmse_rad(1),out.phase_rmse_rad(2));
    fprintf('NOTE: compare numerical tolerance against configured V3 NUFFT accuracy; not a physical error bound.\n');
end