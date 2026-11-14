function smoke_test_p1p2_readonly()
%SMOKE_TEST_P1P2_READONLY 验证只读结果诊断器的代数、符号及失败分母。
% 全部为人为构造的合成表格；不运行任何光学随机数或冻结测试。
    r=struct;
    r.dataset='development';
    r.n_trials=3;
    r.strain_microeps=[0 5];
    r.success=[true;true;false];
    r.common_roi_fraction=[.8;.9;NaN];
    r.common_core_count=[50;70;NaN];
    r.M_core=nan(3,2,4);
    r.C_core=nan(3,2);r.D_core=nan(3,2);
    r.I_core=nan(3,2);r.I_raw_core=nan(3,2);
    base=[0 .01;0 .02];
    C=[0 .02;0 .04];
    D=[.04 .025;.09 .03];
    I=[0 .001;0 -.002];
    r.M_core(1:2,:,1)=base;
    r.M_core(1:2,:,2)=base+C;
    r.M_core(1:2,:,3)=base+D;
    r.M_core(1:2,:,4)=base+C+D+I;
    r.C_core(1:2,:)=C;
    r.D_core(1:2,:)=D;
    r.I_core(1:2,:)=I;
    r.I_raw_core(1:2,:)=I*2;
    r.summary=struct('C_CI95',nan(2,2),'D_CI95',nan(2,2), ...
                     'I_CI95',nan(2,2));
    x.p2=r;
    d=p1p2_readonly_diagnose(x);
    assert(d.n_total==3 && d.n_success==2 && d.n_failure==1, ...
           'P1P2:ReadOnlyFailures','失败试次没有进入分母');
    assert(abs(d.mean_common_roi_fraction-.85)<1e-12, ...
           'P1P2:ReadOnlyROI','ROI分母错误。');
    assert(abs(d.p2_table.C_mean_ue2(2)-.03)<1e-12 && ...
           abs(d.p2_table.I_mean_ue2(2)+.0005)<1e-12, ...
           'P1P2:ReadOnlyMean','符号或均值计算错误。');
    assert(d.p2_table.C_positive(2)==2 && ...
           d.p2_table.I_negative(2)==1 && ...
           d.p2_table.I_positive(2)==1 && ...
           d.identity_max_error_ue2<1e-12, ...
           'P1P2:ReadOnlySigns','符号胜负数或MSE恒等式失败。');
    fprintf('[P1P2 readonly unit] PASS: 2x2 identity, signs, paired trial and failure count.\n');
end