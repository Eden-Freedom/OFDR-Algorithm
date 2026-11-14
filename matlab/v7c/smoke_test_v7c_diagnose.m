function smoke_test_v7c_diagnose()
%SMOKE_TEST_V7C_DIAGNOSE 纯合成数据校验，只测试已有开发结果的读取与配对诊断。
% 不运行 SSWT、NUFFT、Rayleigh 或任何随机冻结种子。
    r=struct();
    r.n_trials=3;
    r.success=[true;true;false];
    r.seed_scatter=[11;22;33];
    r.chosen_alpha=[1;0;NaN];
    r.core_rmse=[0.10 0.40 0.35 0.30 0.20 0.22; ...
                 0.10 0.40 0.35 0.35 0.30 0.35; ...
                 NaN NaN NaN NaN NaN NaN];
    r.holdout_rmse=[0.10 0.45 0.40 0.38 0.30 0.32; ...
                    0.10 0.45 0.40 0.40 0.35 0.40; ...
                    NaN NaN NaN NaN NaN NaN];
    r.valid_fraction=[repmat(0.90,1,6);repmat(0.85,1,6);nan(1,6)];
    r.cv_gain_fraction=[0.15;0;NaN];
    r.data_hessian_rcond=[1e-4;1.1e-4;NaN];
    r.fallback_reason={'CV accepted non-affine blend';'CV selected affine';''};
    r.failure_id={'','','Synthetic:Failure'};
    r.failure_reason={'','','人为构造的失败，必须保留在分母'};
    results=struct('development',r);

    [T,d]=v7c_diagnose_development(results);
    assert(height(T)==3 && d.n_success==2 && d.n_failure==1, ...
        'V7c:DiagCounts','失败试次分母没有正确保留。');
    assert(d.n_affine_fallback==1 && d.n_full_sapc==1 && d.n_partial==0, ...
        'V7c:DiagAlpha','alpha 分类出现错误。');
    % trial 1: gain vs SAPC = 0.20-0.22 = -0.02;
    % trial 2: gain vs SAPC = 0.30-0.35 = -0.05 -> 最严重退化
    assert(d.worst_vs_sapc_trial==2 && abs(d.worst_vs_sapc_gain+0.05)<1e-12, ...
        'V7c:DiagWorst','无法正确定位相对 SAPC 的最大退化。');
    assert(abs(d.loo_mean_core_gain_vs_sapc(2)+0.02)<1e-12, ...
        'V7c:DiagLOO','留一均值计算有误。');
    assert(~T.success(3) && isnan(T.core_gain_vs_sapc(3)), ...
        'V7c:DiagFailure','失败试次不能被伪装成零误差。');
    fprintf('[V7c development diagnostic unit] PASS: paired gains, worst trial, LOO, failure denominator.\n');
end
