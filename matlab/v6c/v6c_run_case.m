function out = v6c_run_case(cfg,truth,pair,oracle_ref,cal_ref,cal_meas)
%V6C_RUN_CASE 同一物理配对信号下比较真实/共模/独立 SSWT 坐标。
% 不通过真实应变更正轨迹，也不将低幅度失效样本计为零。
    q=truth.nu_offset_Hz(:);
    out.order={'oracle','common_sswt','independent_sswt'};
    qrefs={q,cal_ref.q_est_Hz(:),cal_ref.q_est_Hz(:)};
    qmeas={q,cal_ref.q_est_Hz(:),cal_meas.q_est_Hz(:)};
    out.cases=struct();out.common_valid=cell(3,1);
    metrics=cell(3,1);
    for i=1:3
        name=out.order{i};c=struct();c.valid=false;c.failure_reason='';
        c.q_ref_Hz=qrefs{i};c.q_meas_Hz=qmeas{i};
        c.calibration_difference_rmse_MHz=sqrt(mean((qmeas{i}-qrefs{i}).^2))/1e6;
        try
            R=v6_reconstruct_trace(cfg,truth,pair.reference_signal,qrefs{i});
            M=v6_reconstruct_trace(cfg,truth,pair.measurement_signal,qmeas{i});
            met=v6c_demodulate_strain(cfg,R,M,oracle_ref,pair.geometry);
            c.metrics=met;c.valid=met.valid;
            if ~c.valid,c.failure_reason=met.failure_reason;end
            metrics{i}=met;
        catch ME
            c.failure_reason=ME.message;
            c.metrics=[];
        end
        out.cases.(name)=c;
    end
    % 跨方法共同掩码，和 V6b 一样保留每方法原始有效率。
    if all(cellfun(@(m)~isempty(m)&&m.valid,metrics))
        mask=metrics{1}.valid_gauge;
        for i=2:3,mask=mask&metrics{i}.valid_gauge;end
        for i=1:3
            z=out.order{i};c=out.cases.(z);
            c.metrics.common_scored_mask=mask;
            c.metrics.common_strain_rmse_microeps=v6c_mask_rms(c.metrics.strain_error_microeps,mask);
            c.metrics.common_phase_rmse_rad=v6c_mask_rms(c.metrics.phase_error_rad,mask);
            out.cases.(z)=c;
        end
    end
end
function out=v6c_mask_rms(x,mask)
    v=x(mask & isfinite(x));if isempty(v),out=NaN;else,out=sqrt(mean(v.^2));end
end
