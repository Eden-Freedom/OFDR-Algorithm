function o=p2b_run_trial(cfg,truth,t)
%P2B_RUN_TRIAL 固定一组散射与辅助估计，比较共模α微扰和非局部α。
% 四个应变水平上全部α共用同一物理主信号、Core/Static/Gauge有效交集。
% qtrue与ec仅用于机制注入；真实应变仅用于评分和Oracle r0（禁止部署）。
    p2b_assert_protocol(cfg);
    local=cfg;
    local.v6.scatter_seed=cfg.p2b.scatter_seed_base+(t-1)*cfg.p2b.scatter_stride;
    sr=cfg.p2b.aux_ref_seed_base+(t-1)*cfg.p2b.aux_stride;
    sm=cfg.p2b.aux_meas_seed_base+(t-1)*cfg.p2b.aux_stride;
    agrid=cfg.p2b.alpha_grid(:).';
    strains=cfg.p2b.strain_microeps(:).';
    K=numel(strains);A=numel(agrid);
    h=cfg.p2b.primary_h;
    h2=cfg.p2b.secondary_h;
    test_alpha=cfg.p2b.test_alpha(:).';
    ix0=find(abs(agrid)<1e-12,1);
    im=find(abs(agrid+h)<1e-12,1);
    ip=find(abs(agrid-h)<1e-12,1);
    im2=find(abs(agrid+h2)<1e-12,1);
    ip2=find(abs(agrid-h2)<1e-12,1);
    if any(cellfun(@isempty,{ix0,im,ip,im2,ip2}))
        error('P2B:Grid','α网格缺少0或预设的中心差分点。');
    end
    itest=zeros(1,numel(test_alpha));
    for v=1:numel(test_alpha)
        itest(v)=find(abs(agrid-test_alpha(v))<1e-12,1);
    end

    [ref_signal,scatter]=v6_rayleigh_signal(local,truth);
    source=struct('ref_signal',ref_signal,'scatter',scatter);
    ar=v6_estimate_aux(local,truth,sr);
    am=v6_estimate_aux(local,truth,sm);
    qtrue=truth.nu_offset_Hz(:);
    ec=0.5*(ar.q_est_Hz(:)+am.q_est_Hz(:))-qtrue;
    if numel(ec)~=truth.N || any(~isfinite(ec))
        error('P2B:CommonError','共模误差轨迹尺寸/数值非法。');
    end
    reftrace=cell(1,A);
    for ia=1:A
        q=qtrue+agrid(ia)*ec;
        if any(diff(q)<=0) || any(~isfinite(q))
            error('P2B:NonMonotone','trial=%d, alpha=%g 的共同重构坐标非法。',t,agrid(ia));
        end
        reftrace{ia}=v6_reconstruct_trace(local,truth,ref_signal,q);
    end

    met=cell(K,A);
    for j=1:K
        pair=v6c_forward_pair(local,truth,strains(j),source);
        for ia=1:A
            q=qtrue+agrid(ia)*ec;
            ms=v6_reconstruct_trace(local,truth,pair.measurement_signal,q);
            m=v6c_demodulate_strain(local,reftrace{ia},ms, ...
                                    reftrace{ix0},pair.geometry);
            if ~m.valid
                error('P2B:Gauge','trial=%d, strain=%g, α=%g: %s', ...
                      t,strains(j),agrid(ia),m.failure_reason);
            end
            met{j,ia}=m;
        end
    end

    core=met{1,ix0}.core_valid;
    static=met{1,ix0}.static_valid;
    valid=met{1,ix0}.valid_gauge;
    z=met{1,ix0}.z_gauge_mid_m;
    for j=1:K
        for ia=1:A
            m=met{j,ia};
            if numel(m.valid_gauge)~=numel(valid) || ...
               any(abs(m.z_gauge_mid_m-z)>1e-9)
                error('P2B:GaugeGrid','所有alpha/应变必须有同一Gauge空间网格。');
            end
            core=core & m.core_valid;
            static=static & m.static_valid;
            valid=valid & m.valid_gauge;
        end
    end
    roi=z>=cfg.v6.roi_m(1)&z<=cfg.v6.roi_m(2);
    fraction=nnz(valid)/max(nnz(roi),1);
    if nnz(core)<cfg.p2b.min_common_core || ...
       nnz(static)<cfg.p2b.min_common_static || ...
       fraction<cfg.p2b.min_common_roi_fraction
        error('P2B:Mask','trial=%d,固定Core=%d,Static=%d,ROI=%.4f不足。', ...
              t,nnz(core),nnz(static),fraction);
    end

    o=struct();
    o.success=true;
    o.scatter_seed=local.v6.scatter_seed;
    o.aux_ref_seed=sr;o.aux_meas_seed=sm;
    o.ec_rms_MHz=sqrt(mean(ec.^2))/1e6;
    o.strains_microeps=strains;
    o.test_alpha=test_alpha;
    o.common_core_count=nnz(core);
    o.common_static_count=nnz(static);
    o.common_valid_fraction=fraction;
    o.common_roi_denominator=nnz(roi);
    nTest=numel(test_alpha);
    o.C_actual=nan(K,nTest);
    o.C_pred=nan(K,nTest);
    o.prediction_residual=nan(K,nTest);
    o.pred_linear=nan(K,nTest);
    o.pred_quadratic=nan(K,nTest);
    o.local_gradient_rms=nan(K,1);
    o.gradient_h_rms_difference=nan(K,1);
    o.mean_baseline_MSE=nan(K,1);
    o.zero_max_abs_strain_ue=NaN;
    if t==1,o.example=struct();end
    for j=1:K
        f=cell(1,A);
        for ia=1:A
            f{ia}=met{j,ia}.measured_gauge_strain_microeps(core);
            if any(~isfinite(f{ia}))
                error('P2B:Finite','固定Core的应变估计包含非有限数值。');
            end
        end
        tr=met{j,ix0}.true_gauge_strain_microeps(core);
        baseline=f{ix0}-tr;
        baselineM=mean(baseline.^2);
        grad1=(f{ip}-f{im})/(2*h);
        grad2=(f{ip2}-f{im2})/(2*h2);
        o.local_gradient_rms(j)=sqrt(mean(grad1.^2));
        o.gradient_h_rms_difference(j)=sqrt(mean((grad1-grad2).^2));
        o.mean_baseline_MSE(j)=baselineM;
        for v=1:nTest
            alpha=test_alpha(v);
            out=p2b_predict_local(baseline,f{im},f{ip},h,alpha);
            actual=mean((f{itest(v)}-tr).^2)-baselineM;
            o.C_actual(j,v)=actual;
            o.C_pred(j,v)=out.C_pred;
            o.prediction_residual(j,v)=actual-out.C_pred;
            o.pred_linear(j,v)=out.linear_term;
            o.pred_quadratic(j,v)=out.quadratic_term;
        end
        if abs(strains(j))<1e-12
            values=zeros(1,A);
            for ia=1:A,values(ia)=max(abs(f{ia}));end
            o.zero_max_abs_strain_ue=max(values);
        end
        if t==1 && abs(strains(j)-5)<1e-12
            o.example.midpoint_m=z(core);
            o.example.epsilon_true_ue=tr;
            o.example.oracle_residual_ue=baseline;
            o.example.gradient_ue_per_alpha=grad1;
            o.example.actual_diff_alpha1_ue=f{itest(end)}-f{ix0};
            o.example.linear_diff_alpha1_ue=grad1*test_alpha(end);
        end
    end
end