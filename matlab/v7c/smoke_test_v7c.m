function smoke_test_v7c()
%SMOKE_TEST_V7C 仅运行两个全新开发试次；不能把2次 CI 当作科研结论。
    cfg=config_v7c();cfg.v7c.development_repeats=2;
    cfg.v7c.run_frozen_test=false;cfg.v7c.run_conditions=false;
    cfg.v7c.make_plots=false;cfg.v7c.save_results=false;
    v7c_assert_protocol(cfg);
    [~,r]=main_v7c(cfg);
    x=r.development;
    assert(x.n_trials==2,'Smoke 必须恰好包含两个配对试次');
    assert(nnz(x.success)==2,'至少一个试次失败：检查 failure_reason');
    assert(all(all(isfinite(x.core_rmse(x.success,:)))),'Core RMSE must be finite');
    assert(all(all(isfinite(x.holdout_rmse(x.success,:)))),'holdout RMS must be finite');
    assert(all(x.chosen_alpha(x.success)>=0 & x.chosen_alpha(x.success)<=1));
    assert(all(x.seed_scatter < cfg.v7c.test_seed_base(1)),'开发集与测试种子范围不应重叠');
    assert(all(x.common_core_count(x.success)>=15));
    assert(all(x.common_holdout_count(x.success)>=15));
    assert(all(x.valid_fraction(x.success,6)>0.2));
    fprintf('[V7c smoke] PASS: no ground-truth input to gate, %d/2 valid paired trials.\n',nnz(x.success));
    fprintf('NOTE: all conclusions still require independent frozen MATLAB test.\n');
end
