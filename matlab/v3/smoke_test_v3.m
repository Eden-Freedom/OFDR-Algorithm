function smoke_test_v3()
%SMOKE_TEST_V3 核函数、空间峰位与NUDFT一致性无噪声验收。
% 不需要实际硬件或工具箱；不调用 V1 信号模型来验证底层 NUFFT。
    N=1024;
    n=(0:N-1)';
    u=n/N;
    k=(0:floor(N/2)).';
    opts.alpha=2;
    opts.kernel_width=12; % 设更宽的核以验证高精度上界
    x=cos(2*pi*73*u)+0.3*cos(2*pi*140*u+0.4);
    weights=ones(N,1);
    direct=fft(x)/N;
    approx=nufft_gaussian_type1_v3(u,x,weights,k,opts);
    err=norm(approx.spectrum-direct(1:numel(k)))/norm(direct(1:numel(k)));
    assert(err<1e-5,'均匀坐标下 Gaussian NUFFT 应接近普通 FFT。');

    u=n/N+0.12/(4*pi)*sin(4*pi*n/N)+0.04*(n/N).*(1-n/N);
    assert(all(diff(u)>0) && u(end)<1,'测试光频坐标必须合法。');
    wt=frequency_density_weights_v3(u,'voronoi');
    x=exp(2i*pi*73*u)+0.3*exp(2i*pi*140*u+0.4);
    kcheck=[0;1;35;73;74;140;257;400;512];
    expected=nudft_reference_v3(u,x,wt,kcheck);
    actual=nufft_gaussian_type1_v3(u,x,wt,kcheck,opts);
    rel=norm(actual.spectrum-expected)/norm(expected);
    assert(rel<1e-5,'非均匀光频 NUFFT 应接近等权约定的直接 NUDFT。');

    % 检查 V3 输出和真实空间坐标（V1 的同一物理模型，线性扫频）。
    cfg=config_v3();
    cfg.plot.enabled=false;
    cfg.v3.plot_enabled=false;
    cfg.v3.show_benchmark=false;
    cfg.sim.add_noise=false;
    cfg.laser.ripple_a=0;
    cfg.laser.drift_b=0;
    cfg.v3.kernel_width=12;
    [~,truth,signals,results,metrics]=main_v3(cfg); %#ok<ASGLU>
    for j=1:numel(signals.z_true_m)
        assert(abs(metrics.peak_errors.nufft_truth(j)) < 2*results.delta_z_m, ...
              '线性无噪声下，NUFFT 反射峰位置须与真值差距小于 2 个距离 bin。');
    end
    assert(metrics.nudft_relative_l2 < 1e-5, ...
           '物理模型下 NUFFT 数值误差过大。');
    fprintf('V3 smoke test PASS: uniform FFT error %.2e, nonuniform NUDFT error %.2e.\n', ...
            err,rel);
    fprintf('Physical-model matched NUDFT error %.2e; distance bin %.3f mm.\n', ...
            metrics.nudft_relative_l2,results.delta_z_m*1e3);
end
