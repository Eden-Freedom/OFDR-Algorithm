function metrics = evaluate_joint_v4(results,truth,signals,cfg)
%EVALUATE_JOINT_V4 光频校准→距离域的误差传递定量指标。
% 同时记录复数谱误差、幅度谱误差、峰位偏差和孤立峰 FWHM。
% FWHM 定义为功率半高宽：|S|^2=peak^2/2，不能混同零填充显示间隔。
    names=fieldnames(results.spectra);
    z=results.z_m(:);
    dz=results.dz_m;
    ref=results.spectra.nufft_truth(:);
    ref_mag=abs(ref);
    metrics.methods=names;
    for a=1:numel(names)
        label=names{a}; y=results.spectra.(label); y=y(:);
        er=y-ref;
        stats.complex_relative_l2=norm(er)/max(norm(ref),realmin);
        stats.magnitude_relative_l2=norm(abs(y)-ref_mag)/max(norm(ref_mag),realmin);
        [peaks,errors]=local_peaks(y,z,signals.z_true_m,dz);
        stats.peaks_m=peaks;
        stats.errors_m=errors;
        metrics.(label)=stats;
    end
    metrics.nominal_resolution_m=dz;
    metrics.calibration=results.calibration_metrics;
    e=results.estimated_u(:)-results.true_u(:);
    metrics.normalized_u_rmse=sqrt(mean(e.^2));
    metrics.scan_error_rmse_MHz=sqrt(mean((e*results.nominal_span_Hz/1e6).^2));
    metrics.scan_error_max_MHz=max(abs(e))*results.nominal_span_Hz/1e6;
    metrics.time=results.elapsed;
    if isfield(results,'isolated') && ~isempty(results.isolated)
        metrics.isolated=struct();
        iso=results.isolated;
        labels={'fft_uncalibrated','nufft_truth','nufft_sswt','interp_sswt'};
        for j=1:numel(labels)
            name=labels{j};
            metrics.isolated.(name).power_fwhm_m=power_fwhm_v4(z,iso.(name),iso.z_true_m);
            metrics.isolated.(name).energy90_width_m=energy_width_v4(z,iso.(name),0.90);
        end
    else
        metrics.isolated=[];
    end
    metrics.fut_true_positions_m=signals.z_true_m;
end

function [peaks,errors]=local_peaks(signal,z,ztrue,dz)
    ztrue=ztrue(:);
    peaks=nan(size(ztrue));errors=peaks;
    for j=1:numel(ztrue)
        sep=abs(ztrue-ztrue(j));sep(j)=inf;
        halfwidth=min(max(3*dz,0.0025),0.42*min(sep));
        ii=find(abs(z-ztrue(j))<=halfwidth);
        if isempty(ii),continue;end
        [~,ix]=max(abs(signal(ii)));
        peaks(j)=z(ii(ix));
        errors(j)=peaks(j)-ztrue(j);
    end
end
