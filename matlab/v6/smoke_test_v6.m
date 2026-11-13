function smoke_test_v6()
%SMOKE_TEST_V6 验证零应变共模消除、相关误差/有效门控与单位转换。
% 首轮测试减少空间散射体数量以加快执行；正式结果仍需 main_v6 默认配置。
    cfg=config_v6();
    cfg.v6.scatter_step_m=0.006;
    cfg.v6.make_plots=false;
    cfg.v6.save_results=false;
    [~,r]=main_v6(cfg);
    oracle=r.cases.oracle_oracle;
    common=r.cases.common_sswt;
    rho1=r.cases.rho_100;
    rho0=r.cases.rho_000;
    assert(oracle.valid && common.valid && rho1.valid && rho0.valid,'关键测试工况无效。');
    assert(oracle.metrics.false_strain_rmse_microeps<1e-8,'真实坐标零应变应接近零。');
    assert(common.metrics.false_strain_rmse_microeps<1e-8,'严格共模校准误差应抵消。');
    assert(rho1.metrics.false_strain_rmse_microeps<1e-8,'rho=1 的完全相同注入误差应抵消。');
    assert(rho0.diff_coordinate_rmse_MHz>0.1,'rho=0 的输入差分过小。');
    assert(rho0.metrics.gauge_phase_rmse_rad>1e-6, ...
        'rho=0 产生的差分坐标误差未能进入 gauge 相位，请核查物理模型。');
    assert(abs(r.controlled.rho_empirical(end))<1e-9,'控制相关性失败。');
    assert(abs(r.controlled.rmse_ref_MHz-cfg.v6.inject_rms_MHz)<1e-8,'参考端 RMS 标定失败。');
    assert(all(abs(r.controlled.rmse_meas_MHz-cfg.v6.inject_rms_MHz)<1e-8),'测量端 RMS 标定失败。');
    assert(oracle.metrics.gauge_lag_bins>0 && oracle.metrics.gauge_length_actual_m>0);
    assert(nnz(oracle.metrics.valid_gauge)>0,'有效 gauge 点数量不能为零。');
    fprintf('V6a smoke test PASS: oracle, common and rho=1 yield zero false strain; rho=0 has distinct coordinate error.\n');
end
