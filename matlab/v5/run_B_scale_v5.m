function B=run_B_scale_v5(context)
%RUN_B_SCALE_V5 P1：纯比例误差×反射距离，细网格峰位核验。
% 主信号固定为真实光频生成，注入误差只修改核坐标；失败不裁剪。
    cfg=context.cfg;
    distances=cfg.v5.scale_distance_m(:);
    eps_ppm=cfg.v5.scale_ppm(:);
    nz=numel(distances);ne=numel(eps_ppm);
    truth_peak=nan(nz,1); observed=nan(nz,ne); predicted=nan(nz,ne);
    delta=nan(nz,ne);valid=false(nz,ne);fail=cell(nz,ne);
    fwhm=nan(nz,ne);peakLoss=nan(nz,ne);
    for i=1:nz
        zz=distances(i);
        s=v5_single_signal(context,zz,1,cfg.v5.phase_rad);
        z=v5_fine_grid(cfg,zz,cfg.v5.fine_step_m);
        reference=v5_spectrum(context,context.q_true_Hz,s,'fixed',z,false);
        refMetric=v5_peak_metrics(z,reference.fine,zz,cfg);
        if ~refMetric.valid,error('比例扫描参考峰无效：%s',refMetric.reason);end
        truth_peak(i)=refMetric.peak_m;
        for j=1:ne
            eps=eps_ppm(j)*1e-6;
            predicted(i,j)=zz/(1+eps)-zz;
            q_est=(1+eps)*context.q_true_Hz;
            try
                candidate=v5_spectrum(context,q_est,s,'full',z,false);
                info=v5_compare_spectrum(reference,candidate,zz,cfg);
                if ~info.valid
                    fail{i,j}=info.reason;continue;
                end
                observed(i,j)=info.estimated_peak.peak_m-zz;
                delta(i,j)=info.delta_location_m;
                fwhm(i,j)=info.estimated_peak.fwhm_m;
                peakLoss(i,j)=info.peak_power_loss_dB;
                valid(i,j)=true;fail{i,j}='';
            catch ME
                fail{i,j}=ME.message;
            end
        end
    end
    B.experiment='B-scale: proportion error and distance';
    B.distances_m=distances;
    B.scale_ppm=eps_ppm;
    B.predicted_offset_m=predicted;
    B.absolute_error_m=observed;
    B.incremental_error_m=delta;
    B.truth_peak_m=truth_peak;
    B.fwhm_m=fwhm;
    B.peak_loss_dB=peakLoss;
    B.valid=valid;B.failure_reason=fail;
    gap=abs(observed-predicted);gap(~valid)=NaN;
    B.max_prediction_disagreement_m=max(gap(valid));
    B.valid_count=nnz(valid);B.failed_count=numel(valid)-nnz(valid);
    fprintf('[B-scale] valid %d/%d, max |numerical-theory| = %.3f um\n', ...
        B.valid_count,numel(valid),B.max_prediction_disagreement_m*1e6);
end
