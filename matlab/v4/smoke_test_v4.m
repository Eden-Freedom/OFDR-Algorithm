function smoke_test_v4()
%SMOKE_TEST_V4 端到端联合校准的基本物理和数值回归测试。
% 先验证线性/无噪声基线，再验证非线性/有噪声主要流程。
% 不要求 SSWT 必须优于全部基线，只要求物理坐标正确、有限、峰可恢复。
    cfg=config_v4();
    cfg.plot.enabled=false;
    cfg.v4.plot_enabled=false;
    cfg.v4.include_stft_cwt=false;
    cfg.v4.save_png=false;
    cfg.v3.show_benchmark=false;

    fprintf('\n--- V4 smoke test 1: no noise, linear TLS ---\n');
    cfg.sim.add_noise=false;
    cfg.laser.ripple_a=0;
    cfg.laser.drift_b=0;
    [~,t0,~,r0,m0]=main_v4(cfg);
    assert(all(diff(r0.estimated_u)>0),'SSWT 校准轨迹必须递增。');
    assert(all(isfinite(r0.spectra.nufft_sswt)),'NUFFT 含非有限数值。');
    assert(max(abs(r0.true_u-t0.u))<1e-8,'真值坐标未映射到标准频率位置。');
    assert(all(abs(m0.nufft_truth.errors_m)<1.0*r0.dz_m), ...
           '线性扫描真实轨迹的反射点应落在 1 bin 以内。');

    fprintf('\n--- V4 smoke test 2: noisy nonlinear TLS ---\n');
    cfg=config_v4();
    cfg.v4.plot_enabled=false;
    cfg.v4.include_stft_cwt=false;
    [~,~,sig,r,m]=main_v4(cfg);
    assert(all(diff(r.estimated_u)>0),'非线性光频轨迹必须严格递增。');
    assert(r.estimated_u(end)<1,'SSWT 光频坐标末端必须在 [0,1)。');
    assert(all(isfinite(r.spectra.nufft_sswt)),'联合重构非有限。');
    assert(m.nufft_sswt.magnitude_relative_l2 < m.fft_uncalibrated.magnitude_relative_l2, ...
           '当前典型非线性仿真应优于未校准 FFT；检查参数或实现。');
    assert(all(abs(m.nufft_sswt.errors_m)<2*r.dz_m), ...
           '反射点位置误差不应超过两个距离 bins。');
    assert(numel(m.nufft_sswt.peaks_m)==numel(sig.z_true_m), ...
           '峰位数量应等于预设反射点数量。');
    fprintf('\nPASS: V4 linear/noiseless and nonlinear/noisy joint tests.\n');
    fprintf('Note: tests are deterministic when cfg.sim.random_seed is fixed.\n');
end
