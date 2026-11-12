function report = validate_v1(cfg, truth, signals)
%VALIDATE_V1 检查 V1 信号模型的物理有效性与数据完整性。
% 当采样率无法覆盖最大拍频时，报错而不是输出看似合理的混叠图。

    N = cfg.acq.N;
    fs = cfg.acq.fs_Hz;
    names = {'t_s','nu_Hz','nu_offset_Hz','lambda_m','tuning_rate_Hz_s'};
    for j = 1:numel(names)
        x = truth.(names{j});
        if numel(x) ~= N || any(~isfinite(x(:)))
            error('真值数组 %s 长度错误或含有 NaN/Inf。', names{j});
        end
    end
    names = {'aux','aux_clean','main','main_clean','aux_beat_Hz'};
    for j = 1:numel(names)
        x = signals.(names{j});
        if numel(x) ~= N || any(~isfinite(x(:)))
            error('信号数组 %s 长度错误或含有 NaN/Inf。', names{j});
        end
    end
    if any(diff(truth.nu_offset_Hz) <= 0) || any(truth.tuning_rate_Hz_s <= 0)
        error('扫频轨迹没有保持严格单调，需减小非线性强度。');
    end
    if size(signals.main_components, 1) ~= N || ...
            size(signals.main_components, 2) ~= numel(cfg.fut.z_m)
        error('主 OFDR 各反射点分量的数组维度不正确。');
    end

    max_aux_Hz = max(abs(signals.aux_beat_Hz));
    max_main_Hz = max(abs(signals.main_beat_Hz(:)));
    nyquist_Hz = fs/2;
    if max(max_aux_Hz, max_main_Hz) >= nyquist_Hz
        error(['超过奈奎斯特采样极限：最高拍频 %.1f kHz、Nyquist %.1f kHz。' ...
               '请增加采样率或减小扫频速率/光纤距离/辅助时延。'], ...
               max(max_aux_Hz, max_main_Hz)/1e3, nyquist_Hz/1e3);
    end

    c = cfg.const.c_m_s;
    ng = cfg.fut.group_index;
    theory_dz_m = c/(2*ng*truth.delta_nu_Hz);
    % 对标称均匀光频采样，每一个正频率 FFT bin 的距离刻度。
    z_fft_bin_m = c/(2*ng*truth.delta_nu_Hz);
    % 非线性扫频最速时，可保证无混叠的最远反射距离（冻结频率近似）。
    conservative_range_m = c*fs/(4*ng*max(truth.tuning_rate_Hz_s));

    report.nyquist_Hz = nyquist_Hz;
    report.max_aux_beat_Hz = max_aux_Hz;
    report.max_main_beat_Hz = max_main_Hz;
    report.ideal_delta_z_m = theory_dz_m;
    report.fft_range_bin_m = z_fft_bin_m;
    report.conservative_max_range_m = conservative_range_m;
    report.main_true_z_m = signals.z_true_m;
    report.main_delay_s = signals.main_delay_s;
    report.monotonic = true;
    report.no_aliasing = true;
end
