function d=v5_beat_diagnostics(context, beat_est_Hz, recovery_delay_s)
%V5_BEAT_DIAGNOSTICS 拍频误差的边界贡献及累计积分，含全部样本。
    if nargin<3,recovery_delay_s=context.cfg.aux.delay_s;end
    t=context.truth.t_s(:);
    ftrue=context.signals.aux_beat_Hz(:);
    fhat=beat_est_Hz(:);
    e=fhat-ftrue;
    d.error_Hz=e;d.time_s=t;
    d.cumulative_integral_Hz=cumtrapz(t,e)/context.cfg.aux.delay_s;
    d.beat_bias_Hz=mean(e);
    d.beat_rmse_full_Hz=sqrt(mean(e.^2));
    keep=t>=t(1)+.05*(t(end)-t(1))&t<=t(end)-.05*(t(end)-t(1));
    d.beat_rmse_central90_Hz=sqrt(mean(e(keep).^2));
    d.recovery_delay_s=recovery_delay_s;
    recovered=recover_optical_frequency(fhat,t,recovery_delay_s, ...
        context.truth.nu_start_Hz,context.cfg.const.c_m_s);
    d.estimated_q_Hz=recovered.nu_offset_Hz;
    d.q_error_Hz=d.estimated_q_Hz-context.q_true_Hz;
    d.q_decomposition=v5_error_decomposition(context,d.q_error_Hz);
    % 分段积分采用梯形每条时间边（不丢失边界上的最后一条采样边）。
    dt=diff(t);
    increment=.5*(e(1:end-1)+e(2:end)).*dt/context.cfg.aux.delay_s;
    normalized_mid=(t(1:end-1)+t(2:end))/(2*context.cfg.laser.duration_s);
    d.edge_start_contribution_Hz=sum(increment(normalized_mid<.05));
    d.middle_contribution_Hz=sum(increment(normalized_mid>=.05&normalized_mid<.95));
    d.edge_end_contribution_Hz=sum(increment(normalized_mid>=.95));
    d.segment_sum_error_Hz=sum(increment)-sum(d.cumulative_integral_Hz(end));
end
