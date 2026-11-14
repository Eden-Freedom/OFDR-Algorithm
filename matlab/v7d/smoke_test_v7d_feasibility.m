function smoke_test_v7d_feasibility()
%SMOKE_TEST_V7D_FEASIBILITY 不需要光学仿真的确定性单元测试。
    q0=(0:9)'*1e6;
    qA=q0+0.1e6;
    qS=qA+1.2e6*sin(pi*(0:9)'/9);
    [ok0,~,~]=v7d_candidate_feasible(q0,qA,qS,0,0.8,5);
    [ok05,d05,~]=v7d_candidate_feasible(q0,qA,qS,0.5,0.8,5);
    [ok1,d1,~]=v7d_candidate_feasible(q0,qA,qS,1,0.8,5);
    assert(ok0 && ok05 && ~ok1, ...
        'V7d:UnitCandidate','alpha=0、0.5应通过，alpha=1应超额外限幅。');
    assert(d05.extra_peak_MHz<=0.8 && d1.extra_peak_MHz>0.8, ...
        'V7d:UnitAmplitude','候选额外修正单位或峰值错误。');
    qbad=qA;qbad(5)=-1e6; % 在幅度条件足够宽时也必须检查坐标单调性。
    [okbad,dbad]=v7d_candidate_feasible(q0,qA,qbad,1,100,100);
    assert(~okbad && strcmp(dbad.reason,'nonmonotone candidate coordinate'), ...
        'V7d:UnitMonotone','未拒绝非单调坐标。');
    [oktotal,dt]=v7d_candidate_feasible(q0,qA+7e6,qA+7e6,0,0.8,5);
    assert(~oktotal && strcmp(dt.reason,'candidate total correction > limit'), ...
        'V7d:UnitTotal','总修正幅度约束失效。');
    cfg=config_v7d();
    cfg.v7d.run_frozen_test=true;
    blocked=false;
    try
        v7d_assert_protocol(cfg);
    catch ME
        blocked=strcmp(ME.identifier,'V7d:FrozenLocked');
    end
    assert(blocked,'V7d:UnitFrozen','冻结测试安全锁未生效。');
    fprintf('[V7d feasibility unit] PASS: extra/total/monotone and frozen lock.\n');
end
