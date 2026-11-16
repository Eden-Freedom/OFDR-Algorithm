function smoke_test_p2ca_task_relevance()
%SMOKE_TEST_P2CA_TASK_RELEVANCE 合成解析不变量，无随机试次或冻结数据。
    rngBefore=rng;
    cfg=config_p2c_a();
    cfg.p2ca.make_plots=false;
    cfg.p2ca.save_results=false;
    r=p2ca_task_relevant_nullmode(cfg);
    assert(r.aux_blind_max_rad<1e-10, ...
        'P2CA:ImpactSmokeAux','预设4格辅助盲模态未得到零观测。');
    assert(abs(r.main_reflector_max_rad-2*pi*.01)<1e-10 && ...
           abs(r.second_aux_max_rad-2*pi*.01)<1e-10, ...
        'P2CA:ImpactSmokeMain','主单反射点或第二辅助相位响应不符合解析预测。');
    assert(r.main_same_as_aux_delay_max_rad<1e-10 && ...
           r.main_common_scan_max_rad<1e-10 && ...
           r.main_shared_dc_invariance_max_rad<1e-10, ...
        'P2CA:ImpactSmokeInvariant','共同/同延迟/共同DC扰动未抵消。');
    assert(all(diff(r.x_reference)>0) && all(diff(r.x_measurement)>0), ...
        'P2CA:ImpactSmokeMonotone','两个扫频必须严格单调。');
    assert(isequal(rngBefore,rng),'P2CA:ImpactSmokeRng', ...
        '纯数学审计不应改变MATLAB随机数状态。');
    cfg=config_p2c_a();cfg.p2ca.frozen_enabled=true;
    caught=false;
    try
        p2ca_task_relevant_nullmode(cfg);
    catch ME
        caught=strcmp(ME.identifier,'P2CA:FrozenLocked');
    end
    assert(caught,'P2CA:ImpactSmokeFrozen','冻结安全锁无效。');
    fprintf('[P2c-A2 task relevance unit] PASS: auxiliary-null, main-sensitive, common scan/DC cancellation, frozen lock.\n');
end