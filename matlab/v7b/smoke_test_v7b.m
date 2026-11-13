function smoke_test_v7b()
%SMOKE_TEST_V7B 冻结参数、隔离种子、配对统计与V7求解器诊断自检。
    cfg=config_v7b();cfg.v7b.blind_repeats=2;
    cfg.v7b.bootstrap_reps=100;cfg.v7b.run_conditions=false;
    cfg.v7b.save_results=false;cfg.v7b.make_plots=false;
    v7b_assert_frozen(cfg);
    cfgBad=cfg;cfgBad.v7.regularization=cfgBad.v7.regularization*2;
    rejected=false;
    try
        v7b_assert_frozen(cfgBad);
    catch ME
        rejected=strcmp(ME.identifier,'V7b:FrozenParameter');
    end
    assert(rejected,'V7b:Smoke','冻结超参数更改未被拒绝');
    [~,r]=main_v7b(cfg);
    assert(r.blind.summary.n_success==2,'V7b:Smoke','两次试次未全部成功');
    assert(all(r.blind.seed_scatter>1e6),'V7b:Smoke','盲测种子与历史重叠');
    assert(all(isfinite(r.blind.core_rmse(:))),'V7b:Smoke','core 出现非有限值');
    assert(all(isfinite(r.blind.hessian_rcond(r.blind.success))), ...
        'V7b:Smoke','条件数诊断没有输出');
    assert(isfinite(r.blind.summary.comparisons(2).core_gain_mean), ...
        'V7b:Smoke','配对统计输出无效');
    fprintf('[V7b smoke] PASS: frozen hyperparameters, 2 novel trials, paired comparison and diagnostics.\n');
end
