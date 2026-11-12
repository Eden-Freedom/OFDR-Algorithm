function smoke_test_v5()
%SMOKE_TEST_V5 小规模物理与数值断言（此文件需要使用者在 MATLAB 运行）。
% 检查 1) 真值峰宽粗细差异；2) 细网格收敛；3) 纯比例定位；
% 4) 绝对常数偏置锚定不变性；5) 零注入一致性及非法轨迹拒绝。
    cfg=config_v5();cfg.v5.save_results=false;cfg.v5.make_plots=false;
    ctx=v5_setup(cfg,false);
    z0=cfg.v5.single_z_m;
    s=v5_single_signal(ctx,z0,1,cfg.v5.phase_rad);
    z=v5_fine_grid(cfg,z0,cfg.v5.fine_step_m);
    ref=v5_spectrum(ctx,ctx.q_true_Hz,s,'fixed',z,false);
    p=v5_peak_metrics(z,ref.fine,z0,cfg);
    assert(p.valid,'真实单峰无有效 FWHM');
    % 文档独立核验的参考值 1.1781mm：留有足够容差验证正确数量级。
    assert(abs(p.fwhm_m*1e3-1.1781)<.05, ...
       '细网格 Hann 单峰 FWHM 与计划核验相差太大: %.6f mm',p.fwhm_m*1e3);
    z2=v5_fine_grid(cfg,z0,cfg.v5.convergence_step_m);
    c=v5_spectrum(ctx,ctx.q_true_Hz,s,'fixed',z2,false);
    p2=v5_peak_metrics(z2,c.fine,z0,cfg);
    assert(p2.valid&&abs(p.fwhm_m-p2.fwhm_m)<.005e-3, ...
       '0.02/0.01mm 峰宽未收敛');
    % 重新计算粗网格，不直接使用补偿后的图像视觉猜测 FWHM。
    t=v5_spectrum(ctx,ctx.q_true_Hz,s,'fixed',[],true);
    pc=v5_peak_metrics(ctx.z_coarse_m,t.coarse,z0,cfg);
    assert(pc.fwhm_m>p.fwhm_m*1.15,'粗网格 FWHM 不应近似细网格 FWHM');
    % 常数锚定前偏置不可影响归一化坐标。
    [u,~]=prepare_frequency_coordinates_v4(ctx.q_true_Hz,cfg,'baseline');
    [ub,~]=prepare_frequency_coordinates_v4(ctx.q_true_Hz+10e6,cfg,'offset');
    assert(max(abs(u-ub))<1e-12,'绝对光频偏置不变性失败');
    % 纯比例误差，反射位置 z_est ≈ z/(1+epsilon)；峰位需细网格可辨。
    eps=-100e-6;
    q_est=ctx.q_true_Hz*(1+eps);
    alt=v5_spectrum(ctx,q_est,s,'full',z,false);
    pa=v5_peak_metrics(z,alt.fine,z0,cfg);
    observed=pa.peak_m-p.peak_m;
    expected=z0/(1+eps)-z0;
    assert(pa.valid && abs(observed-expected)<.04e-3, ...
         '纯比例误差定位不符合理论，观测 %.3f um，理论 %.3f um',observed*1e6,expected*1e6);
    % 非单调的坐标要拒绝，不允许排序后悄悄运行。
    bad=ctx.q_true_Hz;bad(3)=bad(2)-1;
    did_fail=false;
    try
        prepare_frequency_coordinates_v4(bad,cfg,'invalid trajectory');
    catch
        did_fail=true;
    end
    assert(did_fail,'非法非单调轨迹没有被拒绝');
    fprintf('V5 smoke tests PASS: coarse %.4f mm, fine %.4f mm, 0.01mm %.4f mm; scale shift %.4f mm.\n', ...
        pc.fwhm_m*1e3,p.fwhm_m*1e3,p2.fwhm_m*1e3,observed*1e3);
end
