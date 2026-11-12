function signals = simulate_ofdr_signals(cfg, truth)
%SIMULATE_OFDR_SIGNALS 由同一条 TLS 轨迹生成辅助 MZI 与主 OFDR 信号。
%
% 辅助 MZI：s_aux = A*cos(2*pi*tau_aux*(nu-nu_start) + phi_aux)
% 对应真实瞬时拍频 f_aux = tau_aux*(dnu/dt)。
%
% 主 OFDR：第 j 个位置 z_j 的双程时延 tau_j = 2*ng*z_j/c。
% 信号为 sum_j A_j*cos(2*pi*tau_j*(nu-nu_start) + phi_j)。
%
% 注意：使用“短时延/冻结频率”近似，而非精确光场延迟差分。
% 添加的是电域 AWGN，SNR=10*log10(交流信号功率/噪声功率)。
% 不使用 awgn() 工具箱函数；固定随机种子保证复现。

    N = truth.N;
    tau_aux = cfg.aux.delay_s;
    z = cfg.fut.z_m(:);
    amp = cfg.fut.amplitude(:);
    phi = cfg.fut.phase_rad(:);
    c = cfg.const.c_m_s;
    ng = cfg.fut.group_index;

    if ~(isscalar(tau_aux) && isfinite(tau_aux) && tau_aux > 0)
        error('辅助 MZI 有效时延必须为正数。');
    end
    if ~(isscalar(ng) && ng > 1 && isfinite(ng))
        error('光纤群折射率必须大于 1。');
    end
    if isempty(z) || any(~isfinite(z)) || any(z <= 0) || ...
            numel(z) ~= numel(amp) || numel(z) ~= numel(phi) || ...
            any(~isfinite(amp)) || any(~isfinite(phi))
        error('FUT 的位置、幅度和相位必须为等长的有限非空向量；反射位置为正。');
    end

    % 仅需光频偏移：绝对光频对应的常相位已吸收到 phi 中。
    phase_aux = 2*pi*tau_aux*truth.nu_offset_Hz + cfg.aux.phase_rad;
    aux_clean = cfg.aux.amplitude*cos(phase_aux);
    f_aux = tau_aux*truth.tuning_rate_Hz_s;

    tau_main = 2*ng*z/c;
    % N×M 相位矩阵，第 j 列对应位置 z_j 的一束反射光。
    phase_main = 2*pi*(truth.nu_offset_Hz*tau_main.') + phi.';
    components = cos(phase_main).*amp.';
    main_clean = sum(components, 2);
    f_main = truth.tuning_rate_Hz_s*tau_main.';

    rng(cfg.sim.random_seed, 'twister');
    if cfg.sim.add_noise
        aux = add_noise_at_snr(aux_clean, cfg.aux.snr_dB);
        main = add_noise_at_snr(main_clean, cfg.main.snr_dB);
    else
        aux = aux_clean;
        main = main_clean;
    end

    signals.aux_clean = aux_clean;
    signals.aux = aux;
    signals.main_clean = main_clean;
    signals.main = main;
    signals.main_components = components;
    signals.aux_beat_Hz = f_aux;
    signals.main_beat_Hz = f_main;
    signals.main_delay_s = tau_main;
    signals.z_true_m = z;
    signals.N = N;
end

function noisy = add_noise_at_snr(clean, snr_dB)
%ADD_NOISE_AT_SNR 依据去均值的信号功率添加零均值白噪声。
% 不使用 Signal Processing/Communications Toolbox。
    if ~(isscalar(snr_dB) && isfinite(snr_dB))
        error('SNR 必须是有限的 dB 数值。');
    end
    ac = clean-mean(clean);
    signal_power = mean(ac.^2);
    if signal_power <= 0
        error('干涉信号的交流分量功率必须大于零。');
    end
    noise_sigma = sqrt(signal_power / 10^(snr_dB/10));
    noisy = clean + noise_sigma*randn(size(clean));
end
