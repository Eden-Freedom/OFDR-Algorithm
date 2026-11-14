function smoke_test_p2b_readonly_audit()
%SMOKE_TEST_P2B_READONLY_AUDIT 纯合成trial表检查只读分析和失败分母。
% 不调用OFDR物理函数、不运行随机数、不读取任何冻结集。
    n=3;K=4;A=2;
    r=struct();
    r.dataset='development';
    r.n_trials=n;
    r.strains_microeps=[0 1 5 10];
    r.test_alpha=[0.5 1];
    r.success=[true;true;false];
    r.scatter_seed=[100;101;102];
    r.common_core_count=[50;60;NaN];
    r.common_valid_fraction=[.9;.8;NaN];
    r.gradient_rms=[0 .1 .2 .3;0 .1 .2 .3;NaN NaN NaN NaN];
    r.gradient_h_difference=[0 .001 .002 .003;0 .001 .002 .003;NaN NaN NaN NaN];
    r.failure_id={'','','P2B:MockFailure'};
    r.failure_reason={'','','synthetic failed trial'};
    r.C_actual=nan(n,K,A);
    r.C_pred=nan(n,K,A);
    r.pred_linear=nan(n,K,A);
    r.pred_quadratic=nan(n,K,A);
    r.prediction_residual=nan(n,K,A);
    % 只要成功的trial在所有条件下满足代数恒等式即可；
    % 主终点5με/alpha=1分别测试不同的逐trial预测误差。
    for t=1:2
        for j=1:K
            for v=1:A
                r.C_actual(t,j,v)=.01*j*v*t;
                r.C_pred(t,j,v)=.0095*j*v*t;
                r.pred_linear(t,j,v)=.003*j*v*t;
                r.pred_quadratic(t,j,v)=.0065*j*v*t;
                r.prediction_residual(t,j,v)= ...
                    r.C_actual(t,j,v)-r.C_pred(t,j,v);
            end
        end
    end
    r.summary.gain_CI95=nan(K,A,2);
    r.summary.gain_CI95(3,2,:)=reshape([.045 .085],1,1,2);
    [T,d]=p2b_readonly_audit_dev12(r);
    assert(height(T)==3 && d.n_total==3 && d.n_success==2 && ...
           d.n_failure==1 && abs(d.failure_rate-1/3)<1e-12, ...
           'P2B:AuditDenominator','失败试次未保留在分母。');
    assert(~T.success(3) && isnan(T.C_actual_ue2(3)) && ...
           strcmp(T.failure_id{3},'P2B:MockFailure'), ...
           'P2B:AuditFailure','失败试次未保留原因与缺失指标。');
    assert(abs(d.primary_model_MAE-.0045)<1e-12 && ...
           abs(d.primary_zero_MAE-.09)<1e-12 && ...
           abs(d.primary_quadratic_only_MAE-.0315)<1e-12, ...
           'P2B:AuditMAE','三个误差基线的均值计算错误。');
    assert(d.model_better_than_zero==2 && ...
           d.model_better_than_quadratic==2 && ...
           d.model_better_than_LOO==2, ...
           'P2B:AuditComparison','胜负数量错误。');
    assert(all(abs(d.main_gain_CI95-[.045 .085])<1e-12), ...
           'P2B:AuditCI','没有只读保留既定主终点CI。');
    assert(abs(d.mean_relative_h_difference-.01)<1e-12, ...
           'P2B:AuditDerivative','导数两步长相对差计算错误。');
    rejected=false;
    try
        y=r;
        y.dataset='frozen';
        p2b_readonly_audit_dev12(y);
    catch ME
        rejected=strcmp(ME.identifier,'P2B:AuditDevOnly');
    end
    assert(rejected,'P2B:AuditFrozen','禁止对冻结结果执行本开发诊断。');
    fprintf('[P2b readonly audit unit] PASS: primary, post-hoc baselines, failures, CI and frozen lock.\n');
end