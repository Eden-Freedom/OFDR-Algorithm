function smoke_test_v1()
%SMOKE_TEST_V1 无噪声、自知真值的 V1 数学自检。
% 运行：addpath('matlab/v1'); smoke_test_v1;
% 本测试不要求任何额外工具箱，也不打开图片窗口。

    cfg = config_v1();
    cfg.sim.add_noise = false;
    cfg.plot.enabled = false;

    truth = simulate_laser_sweep(cfg);
    signals = simulate_ofdr_signals(cfg, truth);
    report = validate_v1(cfg, truth, signals);
    assert(report.monotonic && report.no_aliasing, '物理约束自检失败。');
    assert(isequal(signals.aux, signals.aux_clean), '关闭噪声后辅助信号不一致。');
    assert(isequal(signals.main, signals.main_clean), '关闭噪声后主信号不一致。');

    % 由复指数的相位增量验证 f_aux = tau_aux*dnu/dt。
    % 确保相邻相位增量 < pi，由 validate_v1 的奈奎斯特检查保证。
    phase = 2*pi*cfg.aux.delay_s*truth.nu_offset_Hz + cfg.aux.phase_rad;
    p_unwrapped = unwrap(angle(exp(1i*phase)));
    f_phase_diff = diff(p_unwrapped)/(2*pi*truth.dt_s);
    f_analytic_mid = 0.5*(signals.aux_beat_Hz(1:end-1)+ ...
                          signals.aux_beat_Hz(2:end));
    rel_err = max(abs(f_phase_diff-f_analytic_mid))/mean(f_analytic_mid);
    assert(rel_err < 5e-4, '辅助 MZI 相位差拍频与解析拍频不一致。');

    % 测试：严格线性扫频下，对每个单独反射分量做 FFT 应找到正确距离。
    cfg_linear = cfg;
    cfg_linear.laser.ripple_a = 0;
    cfg_linear.laser.drift_b = 0;
    truth_linear = simulate_laser_sweep(cfg_linear);
    signal_linear = simulate_ofdr_signals(cfg_linear, truth_linear);
    validate_v1(cfg_linear, truth_linear, signal_linear);

    N = truth_linear.N;
    npos = floor(N/2)+1;
    zbin = report.fft_range_bin_m;
    for j = 1:numel(cfg_linear.fut.z_m)
        F = abs(fft(signal_linear.main_components(:,j)));
        [~, index_max] = max(F(1:npos));
        z_est_m = (index_max-1)*zbin;
        assert(abs(z_est_m-cfg_linear.fut.z_m(j)) <= zbin, ...
               '单反射点 %d 的 FFT 位置误差超过一个距离 bin。', j);
    end

    % 固定种子确保加噪声的仿真也可以重复生成。
    cfg_noise = config_v1();
    s_a = simulate_ofdr_signals(cfg_noise, truth);
    s_b = simulate_ofdr_signals(cfg_noise, truth);
    assert(isequal(s_a.aux, s_b.aux) && isequal(s_a.main, s_b.main), ...
           '随机种子固定后数据未能复现。');

    fprintf('V1 smoke test PASS: 物理约束、相位拍频、线性 FFT 距离映射、随机复现。\n');
    fprintf('Auxiliary beat relative max error: %.3e\n', rel_err);
    fprintf('Ideal distance bin: %.3f mm\n', zbin*1e3);
end
