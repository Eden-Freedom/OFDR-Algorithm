function calibration = recover_optical_frequency(freq_Hz, t_s, tau_aux_s, nu_anchor_Hz, c_m_s)
%RECOVER_OPTICAL_FREQUENCY 把辅助 MZI 的瞬时拍频积分成光频轨迹。
%   f_aux(t) = tau_aux * (d nu /dt)
%   nu_hat(t) = nu_anchor + integral(f_aux/tau_aux dt)
% 绝对光频锚点 nu_anchor 需要已知：MZI 单路拍频只能提供光频变化量。

    freq_Hz=freq_Hz(:);
    t_s=t_s(:);
    if numel(freq_Hz)~=numel(t_s) || any(~isfinite(freq_Hz)) || ...
       any(diff(t_s)<=0) || numel(t_s)<2
        error('拍频与时间向量必须等长、有限，且时间严格递增。');
    end
    if ~(tau_aux_s>0 && nu_anchor_Hz>0 && c_m_s>0)
        error('辅助时延、光频起始锚点、光速必须为正。');
    end
    % 采用累计梯形积分，时间网格可以不等间隔。
    offset_Hz=cumtrapz(t_s, freq_Hz)/tau_aux_s;
    nu_hat_Hz=nu_anchor_Hz+offset_Hz;
    calibration.freq_Hz=freq_Hz;
    calibration.nu_offset_Hz=offset_Hz;
    calibration.nu_Hz=nu_hat_Hz;
    calibration.lambda_m=c_m_s./nu_hat_Hz;
    calibration.time_s=t_s;
end
