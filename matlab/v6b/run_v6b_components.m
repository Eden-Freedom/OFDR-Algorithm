function out = run_v6b_components(cfg,truth)
%RUN_V6B_COMPONENTS 分离独立 SSWT 的“锚定线性比例”与“锚定非线性”误差。
% 这些误差分量是诊断用：使用光频真值拟合得到，不是无监督的校正方法。
    local=cfg;
    [signal,scatter]=v6_rayleigh_signal(local,truth);
    oracle=v6_reconstruct_trace(local,truth,signal,truth.nu_offset_Hz);
    a=v6_estimate_aux(local,truth,local.v6.aux_seed_ref);
    b=v6_estimate_aux(local,truth,local.v6.aux_seed_meas);
    ref=v6_reconstruct_trace(local,truth,signal,a.q_est_Hz);
    differr=b.q_est_Hz-a.q_est_Hz;
    d=v6b_decompose_error(truth.nu_offset_Hz,differr, ...
        oracle.window.*oracle.density);
    keys={'no_diff','ramp_only','nonlinear_only','full_diff'};
    eparts={zeros(size(differr)),d.anchored_ramp_Hz, ...
        d.anchored_nonlinear_Hz,differr};
    out.case_order=keys;
    out.metrics=cell(numel(keys),1);
    out.case_valid=false(numel(keys),1);
    out.failure_reason=cell(numel(keys),1);
    out.gauge_rmse_rad=nan(numel(keys),1);
    out.false_proxy_rmse_microeps=nan(numel(keys),1);
    out.valid_fraction=nan(numel(keys),1);
    out.diff_rmse_MHz=nan(numel(keys),1);
    out.q_ref_Hz=a.q_est_Hz;
    out.q_meas_Hz=b.q_est_Hz;
    out.error_diff_Hz=differr;
    out.parts_Hz=eparts;
    out.decomposition=d;
    out.scatterers=scatter;
    out.reference_calibration=a;
    out.measurement_calibration=b;
    for j=1:numel(keys)
        e=eparts{j};
        out.diff_rmse_MHz(j)=sqrt(mean(e.^2))/1e6;
        try
            meas=v6_reconstruct_trace(local,truth,signal,a.q_est_Hz+e);
            met=v6_demodulate_zero_strain(local,ref,meas,oracle);
            if ~met.valid,error('V6b:InvalidGauge','%s',met.failure_reason);end
            out.metrics{j}=met;
            out.gauge_rmse_rad(j)=met.gauge_phase_rmse_rad;
            out.false_proxy_rmse_microeps(j)=met.false_strain_rmse_microeps;
            out.valid_fraction(j)=met.valid_fraction;
            out.case_valid(j)=true;out.failure_reason{j}='';
        catch ME
            out.failure_reason{j}=ME.message;
        end
    end
    out.sum_check_max_error_Hz=d.reconstruction_max_error_Hz;
    if out.sum_check_max_error_Hz>1e-3
        warning('V6b:Decomposition','分量相加未能还原原始锚定误差。');
    end
    % 累积的相位响应一般非线性，不把两种 RMS 直接相加当成总 RMS。
end
