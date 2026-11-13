function smoke_test_v7()
%SMOKE_TEST_V7 验证算法无真值拟合、输出有限、物理应变未被训练区泄漏。
    cfg=config_v7();cfg.v7.repeats=2;cfg.v7.bootstrap_reps=100;
    cfg.v7.save_results=false;cfg.v7.make_plots=false;
    [~,r]=main_v7(cfg);
    if r.summary.n_success~=2
        error('V7:SmokeFailure','静态拟合2次试验未全部有效: %s',strjoin(r.failure_reason(~r.success),'; '));
    end
    assert(all(isfinite(r.core_rmse(:))),'非有限core RMSE');
    assert(all(isfinite(r.static_holdout(:))),'非有限holdout RMS');
    fprintf('[V7 smoke] PASS: valid trials, trained upstream only, physical strain scored independently.\n');
end
