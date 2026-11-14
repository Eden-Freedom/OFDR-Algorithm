function smoke_test_v7c_summary()
%SMOKE_TEST_V7C_SUMMARY 独立于昂贵光学仿真的统计汇总容器自检。
% 用人为构造的数组检查：结构体追加、失败分母、配对收益符号与空结果分支。
% 数据只用于软件单元测试，不是真实 MATLAB 仿真或任何科研性能结果。
    config_v7c(); % 加入 V7b/V6b 等历史函数路径，不运行冻结样本。

    r=struct();
    r.n_trials=3;
    r.labels={'oracle','independent_sswt','smoothed_sswt', ...
              'static_affine','SAPC','CV_SAPC'};
    r.success=[true;true;false];
    % 前两行为成功的两个伪造 trial；第三行为失败试次（保留在分母）。
    r.core_rmse=[0.10 0.50 0.40 0.30 0.20 0.15; ...
                 0.10 0.60 0.50 0.40 0.30 0.45; ...
                 NaN NaN NaN NaN NaN NaN];
    r.holdout_rmse=[0.10 0.45 0.40 0.35 0.30 0.20; ...
                    0.10 0.50 0.45 0.40 0.35 0.43; ...
                    NaN NaN NaN NaN NaN NaN];
    r.valid_fraction=[repmat(0.90,1,6);repmat(0.85,1,6);nan(1,6)];
    r.chosen_alpha=[0.5;0;NaN];
    r.fallback=[false;true;false];
    r.cv_folds_ok=[true;true;false];

    s=v7c_summarize(r,200,260113); % 小型、固定种子的 trial bootstrap 单元测试。
    assert(s.total==3 && s.n_success==2 && s.failures==1, ...
           'V7c:TestSummaryCounts','统计汇总未保留失败 trial 分母。');
    assert(numel(s.comparisons)==3, ...
           'V7c:TestComparisonCount','三个对照必须全部生成。');
    assert(strcmp(s.comparisons(2).versus,'static_affine'), ...
           'V7c:TestComparisonLabel','第二个对照应为 Static affine。');
    % 与 affine 的逐试次 Core 增益为 [+0.15,-0.05]，均值 +0.05。
    expected=mean(r.core_rmse(r.success,4)-r.core_rmse(r.success,6));
    assert(abs(s.comparisons(2).core_gain_mean-expected)<1e-12, ...
           'V7c:TestPairing','配对 Core 收益计算不正确。');
    assert(s.comparisons(2).wins==1 && s.comparisons(2).losses==1, ...
           'V7c:TestWinsLosses','胜负 trial 统计错误。');
    assert(all(isfinite(s.comparisons(2).core_gain_CI95)), ...
           'V7c:TestBootstrap','两条成功伪造试次的 bootstrap CI 应有限。');

    % 所有试次失败时应正常返回，不允许假造性能统计。
    r.success(:)=false;
    empty=v7c_summarize(r,200,260113);
    assert(empty.n_success==0 && isempty(empty.comparisons) && ...
           all(isnan(empty.mean_core)), ...
           'V7c:TestNoSuccess','0 成功试次的空结果处理错误。');
    fprintf('[V7c summary unit] PASS: 3 comparison structs, paired gains, failure denominator, zero-success branch.\\n');
end
