function out = run_v6b_spatial_gauge(cfg,truth)
%RUN_V6B_SPATIAL_GAUGE 固定同一参考/测量对，扫描 gauge 长度与距离段。
% 所有空间带采用同一完整 ROI 的参考幅度门限；不分别重定门限。
    local=cfg;
    [signal,scatter]=v6_rayleigh_signal(local,truth);
    oracle=v6_reconstruct_trace(local,truth,signal,truth.nu_offset_Hz);
    local.v6.rho_values=0;
    pairs=v6_controlled_residuals(local,truth.N,truth.fs_Hz);
    ref=v6_reconstruct_trace(local,truth,signal,truth.nu_offset_Hz+pairs.e_ref_Hz);
    meas=v6_reconstruct_trace(local,truth,signal, ...
        truth.nu_offset_Hz+pairs.e_meas_Hz{1});
    bands=cfg.v6b.distance_bands_m;
    gauges=cfg.v6b.gauge_mm(:);
    ng=numel(gauges);nb=size(bands,1);
    out.distance_bands_m=bands;out.gauge_requested_mm=gauges;
    out.gauge_actual_mm=nan(ng,1);
    out.gauge_rmse_rad=nan(ng,nb);
    out.false_proxy_rmse_microeps=nan(ng,nb);
    out.valid_fraction=nan(ng,nb);
    out.valid_count=zeros(ng,nb);
    out.failure_reason=cell(ng,nb);
    for j=1:ng
        temp=local;
        temp.v6.gauge_length_m=gauges(j)*1e-3;
        met=v6_demodulate_zero_strain(temp,ref,meas,oracle);
        out.gauge_actual_mm(j)=met.gauge_length_actual_m*1e3;
        z=met.z_gauge_mid_m;
        for k=1:nb
            eligible=z>=bands(k,1)&z<bands(k,2);
            valid=eligible&met.valid_gauge;
            out.valid_fraction(j,k)=nnz(valid)/max(1,nnz(eligible));
            out.valid_count(j,k)=nnz(valid);
            if nnz(valid)>=8
                g=met.gauge_phase_rad(valid);
                p=met.equivalent_false_strain_microeps(valid);
                out.gauge_rmse_rad(j,k)=sqrt(mean(g.^2));
                out.false_proxy_rmse_microeps(j,k)=sqrt(mean(p.^2));
                out.failure_reason{j,k}='';
            else
                out.failure_reason{j,k}='该空间段有效 gauge 点少于8';
            end
        end
    end
    out.rho_target=0;
    out.rho_empirical=pairs.rho_empirical(1);
    out.scatterers=scatter;
    out.main_signal=signal;
    out.reference_error_Hz=pairs.e_ref_Hz;
    out.measurement_error_Hz=pairs.e_meas_Hz{1};
end
