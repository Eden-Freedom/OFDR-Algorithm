function smoke_test_v6b()
%SMOKE_TEST_V6B 快速数学自检：共同误差、相同RMS与rho、分量可重建性。
    cfg=config_v6b();
    cfg.v6.scatter_step_m=.006; % 小规模光纤散射体以减少运行时间
    cfg.v6b.repeats=2;cfg.v6b.sswt_repeats=1;
    cfg.v6b.make_plots=false;cfg.v6b.save_results=false;cfg.v6b.verbose=false;
    [~,r]=main_v6b(cfg);
    C=r.correlation;idx=find(abs(C.rho_target-1)<1e-12,1);
    assert(~isempty(idx),'必须包含 rho=1 共模控制组');
    assert(all(C.valid(idx,:)),'rho=1 工况必须有效');
    assert(max(abs(C.diff_rmse_MHz(idx,:)))<1e-9,'rho=1 不应产生坐标差');
    assert(max(abs(C.common_gauge_rmse_rad(idx,:)))<1e-8,'rho=1 必须有零 gauge 相位');
    assert(all(C.summary.n_success>0),'至少一个共同有效的 trial');
    for j=1:C.repeats
        assert(max(abs(C.empirical_rho(:,j)-C.rho_target))<1e-8, ...
            '控制相关系数与目标值不符。');
    end
    assert(r.components.sum_check_max_error_Hz<1e-3, ...
        '锚定 ramp 与非线性残差之和应回到原始差分。');
    assert(any(isfinite(r.spatial.gauge_rmse_rad(:))), ...
        '距离-gauge 矩阵应有可用值。');
    assert(numel(r.sswt.valid)==1,'独立 SSWT 重复数不对。');
    fprintf('V6b smoke test PASS: rho=1 cancels; paired masks, weighted components and multi-gauge matrix valid.\n');
end
