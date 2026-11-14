function o=p2_run_trial(cfg,truth,t)
%P2_RUN_TRIAL 固定同一物理双扫描，对共模e_c/差模e_d作4组重构消融。
% 00: qtrue/qtrue
% 10: qtrue+ec / qtrue+ec
% 01: qtrue-ed/2 / qtrue+ed/2
% 11: qtrue+ec-ed/2 / qtrue+ec+ed/2 (还原两次SSWT)
%
% 真值仅用于机制注入、Oracle和事后评分；此函数不可作为部署校正器。
% 4应变水平/4方法每个trial共用散射体、辅助估计与固定有效Core掩码。
    local=cfg;
    local.v6.scatter_seed=cfg.p1p2.scatter_seed_base+(t-1)*cfg.p1p2.scatter_stride;
    sr=cfg.p1p2.aux_ref_seed_base+(t-1)*cfg.p1p2.aux_stride;
    sm=cfg.p1p2.aux_meas_seed_base+(t-1)*cfg.p1p2.aux_stride;
    o.seed_scatter=local.v6.scatter_seed;
    o.seed_ref=sr;o.seed_meas=sm;
    [reference,scatter]=v6_rayleigh_signal(local,truth);
    source=struct('ref_signal',reference,'scatter',scatter);
    ar=v6_estimate_aux(local,truth,sr);
    am=v6_estimate_aux(local,truth,sm);
    qtrue=truth.nu_offset_Hz(:);
    er=ar.q_est_Hz(:)-qtrue;
    em=am.q_est_Hz(:)-qtrue;
    ec=(er+em)/2;
    ed=em-er;
    o.common_error_rms_MHz=sqrt(mean(ec.^2))/1e6;
    o.differential_error_rms_MHz=sqrt(mean(ed.^2))/1e6;
    o.labels={'00_Oracle','10_Common','01_Differential','11_Combined'};
    qr={qtrue,qtrue+ec,qtrue-ed/2,qtrue+ec-ed/2};
    qm={qtrue,qtrue+ec,qtrue+ed/2,qtrue+ec+ed/2};
    if max(abs(qr{4}-ar.q_est_Hz(:)))>0.01 || ...
       max(abs(qm{4}-am.q_est_Hz(:)))>0.01
        error('P2:Decomposition','ec/ed的11组不能还原两条SSWT坐标。');
    end
    K=numel(cfg.p1p2.strain_microeps);
    A=4;
    met=cell(K,A);
    refs=cell(A,1);
    for h=1:A
        refs{h}=v6_reconstruct_trace(local,truth,reference,qr{h});
    end
    for j=1:K
        strain=cfg.p1p2.strain_microeps(j);
        pair=v6c_forward_pair(local,truth,strain,source);
        for h=1:A
            meas=v6_reconstruct_trace(local,truth,pair.measurement_signal,qm{h});
            m=v6c_demodulate_strain(local,refs{h},meas,refs{1},pair.geometry);
            if ~m.valid
                error('P2:Gauge','应变%.2f με, 组%d: %s',strain,h,m.failure_reason);
            end
            met{j,h}=m;
        end
    end
    % 对四个α组合与所有应变水平统一掩码，禁止应变变化时择优换测点。
    m=met{1,1};
    core=m.core_valid;
    stat=m.static_valid;
    common=m.valid_gauge;
    z=m.z_gauge_mid_m;
    stat=stat & z>=cfg.v6c.strain_end_m+cfg.v6c.static_margin_m & ...
        z<=cfg.v6.roi_m(2);
    for j=1:K
        for h=1:A
            mh=met{j,h};
            if numel(mh.valid_gauge)~=numel(common) || ...
                any(abs(mh.z_gauge_mid_m-z)>1e-9)
                error('P2:SpatialGrid','各组距离/Gauge坐标不一致。');
            end
            core=core & mh.core_valid;
            stat=stat & mh.static_valid;
            common=common & mh.valid_gauge;
        end
    end
    roi=z>=cfg.v6.roi_m(1) & z<=cfg.v6.roi_m(2);
    frac=nnz(common)/max(1,nnz(roi));
    if nnz(core)<cfg.p1p2.min_common_core || ...
       nnz(stat)<cfg.p1p2.min_common_static || ...
       frac<cfg.p1p2.min_common_roi_fraction
        error('P2:FixedMask','4组与跨应变的共同Gauge不足：Core=%d,静态=%d,ROI=%.3f', ...
           nnz(core),nnz(stat),frac);
    end
    o.M_core=nan(K,A);          % 每个固定Core位置应变误差平方的均值 (με)^2
    o.M_raw_core=nan(K,A);      % 未做9-bin平滑的相同Core位置的M
    o.rmse_core=nan(K,A);
    o.rmse_static=nan(K,A);
    o.bias_core=nan(K,A);
    o.core_count=nnz(core);
    o.static_count=nnz(stat);
    o.common_roi_fraction=frac;
    o.roi_midpoint_count=nnz(roi);
    for j=1:K
        for h=1:A
            mh=met{j,h};
            e=mh.strain_error_microeps(core);
            raw=mh.raw_strain_error_microeps(core);
            o.M_core(j,h)=mean(e.^2);
            o.M_raw_core(j,h)=mean(raw.^2);
            o.rmse_core(j,h)=sqrt(o.M_core(j,h));
            o.rmse_static(j,h)=sqrt(mean(mh.measured_gauge_strain_microeps(stat).^2));
            o.bias_core(j,h)=mean(e);
        end
    end
    o.I_core=o.M_core(:,4)-o.M_core(:,2)-o.M_core(:,3)+o.M_core(:,1);
    o.C_core=o.M_core(:,2)-o.M_core(:,1);
    o.D_core=o.M_core(:,3)-o.M_core(:,1);
    o.I_raw_core=o.M_raw_core(:,4)-o.M_raw_core(:,2)- ...
                 o.M_raw_core(:,3)+o.M_raw_core(:,1);
    o.success=true;
    if t==1
        o.example.z_gauge_mid_m=z;
        o.example.common_core=core;
        o.example.true_strain=met{end,1}.true_gauge_strain_microeps;
        o.example.measured=cell(A,1);
        for h=1:A
            val=met{end,h}.measured_gauge_strain_microeps;
            val(~core)=NaN;
            o.example.measured{h}=val;
        end
    end
end