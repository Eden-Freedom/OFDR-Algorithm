function smoke_test_p2b()
%SMOKE_TEST_P2B 2个新开发trial，共模有限差分预测端到端测试。
% 数据计入以后12次开发重复的前两个trial；不额外占用独立测试集。
    smoke_test_p2b_math();
    smoke_test_p2b_summary();
    cfg=config_p2b();
    cfg.p2b.development_repeats=2;
    cfg.p2b.make_plots=false;
    cfg.p2b.save_results=false;
    [~,results]=main_p2b(cfg);
    r=results.development;
    if nnz(r.success)~=2
        for k=find(~r.success).'
            fprintf(2,'[P2b smoke] trial %d: %s | %s\n', ...
                    k,r.failure_id{k},r.failure_reason{k});
        end
        error('P2B:SmokeFailure','2/2开发试次未通过，禁止进行12次开发实验。');
    end
    assert(all(isfinite(r.C_actual(r.success,:,:)),'all') && ...
           all(isfinite(r.C_pred(r.success,:,:)),'all'), ...
           'P2B:Finite','方向预测和实际C不应出现非有限值。');
    assert(all(r.common_core_count(r.success)>=cfg.p2b.min_common_core) && ...
           all(r.common_valid_fraction(r.success)>=cfg.p2b.min_common_roi_fraction), ...
           'P2B:GaugeCount','固定空间掩码/有效率未满足预设最低要求。');
    assert(all(r.zero_max_abs_strain_ue(r.success)<1e-6), ...
           'P2B:ZeroInvariant','零应变共模相同坐标重构应得到近零响应。');
    fprintf('[P2b smoke] PASS: 2/2 paired new development trials, fixed masks, zero-strain invariance.\n');
    fprintf('This is code functionality, NOT evidence of predictive accuracy.\n');
end