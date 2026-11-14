function smoke_test_p2b_summary()
%SMOKE_TEST_P2B_SUMMARY 纯合成trial表验证配对统计/CI/失败分母/零成功。
% 不是物理仿真，不访问旧开发或冻结seed。
    cfg=config_p2b();
    cfg.p2b.bootstrap_reps=200;
    n=3;K=2;A=2;
    r=struct();
    r.n_trials=n;
    r.strains_microeps=[0 5];
    r.test_alpha=[.5 1];
    r.success=[true;true;false];
    r.common_valid_fraction=[.9;.8;NaN];
    r.common_core_count=[50;60;NaN];
    r.ec_rms_MHz=[.3;.4;NaN];
    r.gradient_rms=[0 .10;0 .20;NaN NaN];
    r.gradient_h_difference=[0 .01;0 .02;NaN NaN];
    r.baseline_MSE=[0 .001;0 .002;NaN NaN];
    r.C_actual=nan(n,K,A);
    r.C_pred=nan(n,K,A);
    r.C_actual(1,:,1)=[0 .020];
    r.C_actual(2,:,1)=[0 .030];
    r.C_actual(1,:,2)=[0 .050];
    r.C_actual(2,:,2)=[0 .070];
    r.C_pred(1,:,1)=[0 .018];
    r.C_pred(2,:,1)=[0 .032];
    r.C_pred(1,:,2)=[0 .045];
    r.C_pred(2,:,2)=[0 .060];
    s=p2b_summarize(r,cfg);
    assert(s.n_total==3 && s.n_success==2 && s.n_failure==1 && ...
           abs(s.failure_rate-1/3)<1e-12, ...
           'P2B:SummaryFailures','失败试次必须计入3个trial的分母。');
    assert(abs(s.mean_C_actual(2,2)-.06)<1e-12 && ...
           abs(s.mean_C_pred(2,2)-.0525)<1e-12 && ...
           abs(s.mean_signed_error(2,2)-.0075)<1e-12, ...
           'P2B:SummaryPaired','实际/预测C的配对均值不正确。');
    assert(s.n_sign_agree(2,2)==2 && s.n_nonzero_actual(2,2)==2 && ...
           isnan(s.sign_agreement(1,1)), ...
           'P2B:SummarySign','非零响应符号一致率不正确。');
    assert(all(isfinite(reshape(s.prediction_error_CI95(2,2,:),[],1))), ...
           'P2B:SummaryBootstrap','有效的2个trial CI不应该为NaN。');
    r.success(:)=false;
    s0=p2b_summarize(r,cfg);
    assert(s0.n_success==0 && s0.n_failure==3 && ...
           all(isnan(s0.mean_C_actual),'all'), ...
           'P2B:SummaryNoSuccess','零成功不应被当作有效数值结论。');
    fprintf('[P2b summary unit] PASS: paired prediction, CI, sign agreement, failures and zero-success.\n');
end