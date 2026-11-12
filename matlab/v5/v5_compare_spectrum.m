function stats=v5_compare_spectrum(ref, candidate, z_true, cfg)
%V5_COMPARE_SPECTRUM 细网格相干幅度、功率峰宽和未对齐的相位指标。
% 只使用统一物理幅度基准；不把每一条谱自身归一化到最大值。
    if any(ref.z_fine_m~=candidate.z_fine_m),error('局部光谱网格必须一致');end
    z=ref.z_fine_m;
    a=v5_peak_metrics(z,ref.fine,z_true,cfg);
    b=v5_peak_metrics(z,candidate.fine,z_true,cfg);
    stats.ref_peak=a;stats.estimated_peak=b;
    stats.magnitude_relative_l2=norm(abs(candidate.fine)-abs(ref.fine))/max(norm(abs(ref.fine)),realmin);
    stats.complex_relative_l2=norm(candidate.fine-ref.fine)/max(norm(ref.fine),realmin);
    stats.delta_location_m=b.peak_m-a.peak_m;
    stats.absolute_location_error_m=b.absolute_error_m;
    stats.fwhm_growth=(b.fwhm_m-a.fwhm_m)/a.fwhm_m;
    stats.energy90_growth=(b.energy90_width_m-a.energy90_width_m)/a.energy90_width_m;
    stats.peak_power_loss_dB=10*log10(max(b.peak_power,realmin)/max(a.peak_power,realmin));
    % 原始复数响应在固定“真实位置”的相位，不进行事后峰位对齐。
    [~,j]=min(abs(z-z_true));
    stats.fixed_location_phase_delta_rad=angle(candidate.fine(j)*conj(ref.fine(j)));
    stats.fixed_location_amplitude_ratio=abs(candidate.fine(j))/max(abs(ref.fine(j)),realmin);
    % 峰相位仅为补充；峰位变化时不同位置的相位不可直接视为固定点误差。
    stats.peak_phase_delta_rad=angle(exp(1i*(b.peak_phase_rad-a.peak_phase_rad)));
    stats.valid=a.valid&&b.valid;
    if stats.valid,stats.reason='';else,stats.reason=[a.reason ' | ' b.reason];end
    if ~isempty(ref.coarse) && ~isempty(candidate.coarse)
        stats.full_magnitude_relative_l2=norm(abs(candidate.coarse)-abs(ref.coarse))/max(norm(abs(ref.coarse)),realmin);
        stats.full_complex_relative_l2=norm(candidate.coarse-ref.coarse)/max(norm(ref.coarse),realmin);
    else
        stats.full_magnitude_relative_l2=NaN;
        stats.full_complex_relative_l2=NaN;
    end
end
