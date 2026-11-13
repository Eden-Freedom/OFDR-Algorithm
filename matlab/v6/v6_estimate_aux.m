function out = v6_estimate_aux(cfg,truth,seed)
%V6_ESTIMATE_AUX 重用 V2 复 Morlet CWT、SSWT 与脊线算法，不用黑盒 wsst。
% 两次扫描使用同一干净辅助 MZI 波形，独立随机噪声；主信号完全不变。
    clean=cfg.aux.amplitude*cos(2*pi*cfg.aux.delay_s*truth.nu_offset_Hz(:)+cfg.aux.phase_rad);
    ac=clean-mean(clean);
    sigma=sqrt(mean(ac.^2)/10^(cfg.v6.aux_snr_dB/10));
    rng(seed,'twister');
    noisy=clean+sigma*randn(size(clean));
    t0=tic;
    cwt=cwt_morlet_fft(noisy,truth.fs_Hz,cfg.sswt);
    sswt=synchrosqueeze_cwt(cwt,cfg.sswt);
    ridge=extract_sswt_ridge(sswt,cwt,cfg.sswt);
    rec=recover_optical_frequency(ridge.freq_Hz,truth.t_s,cfg.aux.delay_s, ...
                                  truth.nu_start_Hz,cfg.const.c_m_s);
    out.q_est_Hz=rec.nu_offset_Hz(:);
    out.f_hat_Hz=ridge.freq_Hz(:);
    out.f_true_Hz=cfg.aux.delay_s*truth.tuning_rate_Hz_s(:);
    out.q_error_Hz=out.q_est_Hz-truth.nu_offset_Hz(:);
    out.q_rmse_MHz=sqrt(mean(out.q_error_Hz.^2))/1e6;
    out.beat_rmse_Hz=sqrt(mean((out.f_hat_Hz-out.f_true_Hz).^2));
    out.aux_clean=clean;
    out.aux_noisy=noisy;
    out.seed=seed;
    out.runtime_s=toc(t0);
    out.ridge_confidence=ridge.confidence;
end
