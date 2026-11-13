function smoke_test_v6d()
%SMOKE_TEST_V6D 小规模路径和物理一致性验证，不宣称统计显著性。
    cfg=config_v6d();cfg.v6d.repeats=2;cfg.v6d.bootstrap_reps=50;
    cfg.v6d.save_results=false;cfg.v6d.make_plots=false;
    [~,r]=main_v6d(cfg);
    assert(r.summary.n_success==2,'V6d: 小规模消融失败');
    assert(max(r.sum_check_Hz)<1e-3,'V6d: 分解重建未通过');
    assert(max(r.core_rmse(:,1))<2,'V6d: 共模组应变误差过大');
    assert(all(isfinite(r.core_rmse(:))) && all(isfinite(r.static_rmse(:))));
    fprintf('[V6d smoke] PASS: 2 paired nonzero-strain trials, decomposition and common masks.\n');
end
