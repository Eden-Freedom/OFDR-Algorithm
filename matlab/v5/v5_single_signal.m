function s=v5_single_signal(context,z_m,amplitude,phase_rad)
%V5_SINGLE_SIGNAL 与 V1 相同的无噪声冻结频率模型，不因坐标注入而修改。
    if nargin<3,amplitude=1;end
    if nargin<4,phase_rad=context.cfg.v5.phase_rad;end
    if numel(z_m)~=numel(amplitude) && ~(isscalar(amplitude))
        error('反射位置和幅度长度不一致');
    end
    z_m=z_m(:); amplitude=amplitude(:); phase_rad=phase_rad(:);
    if isscalar(amplitude),amplitude=repmat(amplitude,numel(z_m),1);end
    if isscalar(phase_rad),phase_rad=repmat(phase_rad,numel(z_m),1);end
    rate_max=max(context.truth.tuning_rate_Hz_s);
    maxbeat=2*context.cfg.fut.group_index*max(z_m)/context.cfg.const.c_m_s*rate_max;
    if maxbeat>=context.truth.fs_Hz/2
        error('最大反射位置 %.3fm 导致 %.1fkHz 拍频超过 Nyquist。',max(z_m),maxbeat/1e3);
    end
    tau=2*context.cfg.fut.group_index*z_m/context.cfg.const.c_m_s;
    P=2*pi*(context.q_true_Hz*tau.') + phase_rad.';
    s=sum(cos(P).*amplitude.',2);
end
