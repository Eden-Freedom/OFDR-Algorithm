function s=p2_summary(r,cfg)
%P2_SUMMARY 以完整trial为统计单位，不把高度相关的空间Gauge当独立样本。
% 共模主效应: M10-M00；差模主效应: M01-M00；
% 交互项: M11-M10-M01+M00，均是有符号的(με)^2量。
    K=numel(r.strain_microeps);
    g=r.success;
    s.n_total=r.n_trials;
    s.n_success=nnz(g);
    s.n_failure=s.n_total-s.n_success;
    s.failure_rate=s.n_failure/max(1,s.n_total);
    s.strain_microeps=r.strain_microeps;
    s.mean_rmse=nan(K,4);
    s.mean_static_rmse=nan(K,4);
    s.mean_M=nan(K,4);
    s.mean_C=nan(K,1);s.mean_D=nan(K,1);s.mean_I=nan(K,1);
    s.C_CI95=nan(K,2);s.D_CI95=nan(K,2);s.I_CI95=nan(K,2);
    s.mean_I_raw=nan(K,1);
    s.mean_common_roi_fraction=NaN;
    s.mean_common_core_count=NaN;
    if ~any(g),return;end
    s.mean_common_roi_fraction=mean(r.common_roi_fraction(g));
    s.mean_common_core_count=mean(r.common_core_count(g));
    for j=1:K
        for arm=1:4
            vals=reshape(r.rmse_core(g,j,arm),[],1);
            s.mean_rmse(j,arm)=mean(vals);
            s.mean_static_rmse(j,arm)=mean(reshape(r.rmse_static(g,j,arm),[],1));
            s.mean_M(j,arm)=mean(reshape(r.M_core(g,j,arm),[],1));
        end
        C=r.C_core(g,j);D=r.D_core(g,j);I=r.I_core(g,j);
        s.mean_C(j)=mean(C);s.mean_D(j)=mean(D);s.mean_I(j)=mean(I);
        s.mean_I_raw(j)=mean(r.I_raw_core(g,j));
        if nnz(g)>=2
            [lo,hi]=v6b_bootstrap_ci(C,cfg.p1p2.bootstrap_reps, ...
                                cfg.p1p2.bootstrap_seed+10*j);
            s.C_CI95(j,:)=[lo hi];
            [lo,hi]=v6b_bootstrap_ci(D,cfg.p1p2.bootstrap_reps, ...
                                cfg.p1p2.bootstrap_seed+10*j+1);
            s.D_CI95(j,:)=[lo hi];
            [lo,hi]=v6b_bootstrap_ci(I,cfg.p1p2.bootstrap_reps, ...
                                cfg.p1p2.bootstrap_seed+10*j+2);
            s.I_CI95(j,:)=[lo hi];
        end
    end
end