function m = v6c_demodulate_strain(cfg,reference,measurement,oracle_ref,geometry)
%V6C_DEMODULATE_STRAIN 仿真真值 vs Gauge 相位测得的应变（με）。
% 先复用 V6a 的 wrapped gauge 相位，再使用已知 ε(z) 的积分计算窗口真值。
% 不是借用应变真值去校正估计；真值仅用于评分和验证传感系数。
    m=v6_demodulate_zero_strain(cfg,reference,measurement,oracle_ref);
    z=m.z_m(:);n=numel(z);lag=m.gauge_lag_bins;
    I=(1:n-lag).';J=I+lag;zg=m.z_gauge_mid_m;
    displacement=interp1(geometry.z_grid_m,geometry.displacement_grid_m, ...
                         z([I;J]),'linear','extrap');
    if any(~isfinite(displacement)),error('V6c:TrueStrain','真值积分域不足。');end
    N=numel(I);true_microeps=1e6*(displacement(N+1:end)-displacement(1:N))/m.gauge_length_actual_m;
    true_phase=true_microeps/m.gauge_scale_microeps_per_rad;
    allowed=abs(true_phase)<cfg.v6c.gauge_wrap_guard_rad;
    % 原始 gauge 结果保留用于与 V6a 直接比较；不能暗中把平滑结果作为原始数据。
    m.raw_gauge_phase_rad=m.gauge_phase_rad;
    m.raw_gauge_strain_microeps=m.equivalent_false_strain_microeps;
    w=cfg.v6c.phase_avg_bins;
    if ~(isscalar(w)&&w>=1&&w==floor(w)&&mod(w,2)==1)
        error('V6c:PhaseAveraging','phase_avg_bins 必须为正奇整数。');
    end
    m.phase_avg_bins=w;
    m.effective_spatial_support_m=(lag+w-1)*(z(2)-z(1));
    if w>1
        Rr=reference.spectrum(:);Rm=measurement.spectrum(:);
        C=Rm.*conj(Rr);
        phasor=C(J).*conj(C(I));
        phasor=conv(phasor,ones(w,1)/w,'same');
        m.gauge_phase_rad=angle(phasor);
        m.equivalent_false_strain_microeps=m.gauge_phase_rad*m.gauge_scale_microeps_per_rad;
    end
    m.true_gauge_strain_microeps=true_microeps;
    m.true_gauge_phase_rad=true_phase;
    m.measured_gauge_strain_microeps=m.equivalent_false_strain_microeps;
    m.strain_error_microeps=m.measured_gauge_strain_microeps-true_microeps;
    m.raw_strain_error_microeps=m.raw_gauge_strain_microeps-true_microeps;
    m.phase_error_rad=m.gauge_phase_rad-true_phase;
    % 注意不能在真值相位已达到 ±pi 时用 wrapped gauge 伪称高准确率。
    m.valid_gauge=m.valid_gauge & allowed;
    m.near_wrap_truth_count=nnz(~allowed & ...
        zg>=cfg.v6.roi_m(1) & zg<=cfg.v6.roi_m(2));
    m.valid_fraction=nnz(m.valid_gauge)/max(1,nnz(zg>=cfg.v6.roi_m(1)&zg<=cfg.v6.roi_m(2)));
    start=cfg.v6c.strain_start_m;finish=cfg.v6c.strain_end_m;
    inner=start+cfg.v6c.transition_m +cfg.v6c.core_margin_m+0.5*m.gauge_length_actual_m;
    outer=finish-cfg.v6c.transition_m-cfg.v6c.core_margin_m-0.5*m.gauge_length_actual_m;
    core=zg>=inner & zg<=outer;
    static=zg<=start-cfg.v6c.static_margin_m | zg>=finish+cfg.v6c.static_margin_m;
    elig=zg>=cfg.v6.roi_m(1) & zg<=cfg.v6.roi_m(2);
    m.core_eligible=core&elig;
    m.static_eligible=static&elig;
    m.core_valid=m.valid_gauge & core;
    m.static_valid=m.valid_gauge & static;
    m.core_valid_fraction=nnz(m.core_valid)/max(nnz(m.core_eligible),1);
    m.static_valid_fraction=nnz(m.static_valid)/max(nnz(m.static_eligible),1);
    m.valid=m.valid && m.core_valid_fraction>=cfg.v6c.minimum_core_valid_fraction && ...
        nnz(m.static_valid)>10 && m.near_wrap_truth_count==0;
    if ~m.valid && isempty(m.failure_reason)
        m.failure_reason='core/static gate insufficient or truth gauge wrapping';
    end
    m.full_strain_rmse_microeps=v6c_rms(m.strain_error_microeps(m.valid_gauge));
    m.full_gauge_phase_rmse_rad=v6c_rms(m.phase_error_rad(m.valid_gauge));
    m.core_strain_rmse_microeps=v6c_rms(m.strain_error_microeps(m.core_valid));
    m.core_raw_strain_rmse_microeps=v6c_rms(m.raw_strain_error_microeps(m.core_valid));
    m.static_raw_false_strain_rmse_microeps=v6c_rms(m.raw_gauge_strain_microeps(m.static_valid));
    m.core_bias_microeps=v6c_mean(m.strain_error_microeps(m.core_valid));
    m.core_measured_mean_microeps=v6c_mean(m.measured_gauge_strain_microeps(m.core_valid));
    m.core_true_mean_microeps=v6c_mean(m.true_gauge_strain_microeps(m.core_valid));
    m.static_false_strain_rmse_microeps=v6c_rms(m.measured_gauge_strain_microeps(m.static_valid));
    m.static_false_strain_bias_microeps=v6c_mean(m.measured_gauge_strain_microeps(m.static_valid));
    m.full_strain_p95_abs_microeps=v6c_p95(abs(m.strain_error_microeps(m.valid_gauge)));
    m.z_core_bounds_m=[inner,outer];
end
function v=v6c_rms(x)
    x=x(isfinite(x));if isempty(x),v=NaN;else,v=sqrt(mean(x.^2));end
end
function v=v6c_mean(x)
    x=x(isfinite(x));if isempty(x),v=NaN;else,v=mean(x);end
end
function v=v6c_p95(x)
    x=sort(x(isfinite(x)));if isempty(x),v=NaN;else,v=x(max(1,ceil(.95*numel(x))));end
end
