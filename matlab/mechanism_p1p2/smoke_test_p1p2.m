function smoke_test_p1p2()
%SMOKE_TEST_P1P2 新开发种子上的最小端到端核查，不作统计显著性解释。
    smoke_test_p1p2_math();
    cfg=config_p1p2();
    cfg.p1p2.repeats=2;
    cfg.p1p2.run_p1_direct=true;
    cfg.p1p2.run_p1_density=false;
    cfg.p1p2.run_p2=true;
    cfg.p1p2.make_plots=false;
    cfg.p1p2.save_results=false;
    [~,results]=main_p1p2(cfg);
    a=results.p1_direct;
    assert(a.tested_bins>=8 && all(isfinite(a.rel_l2)) && ...
           all(isfinite(a.max_abs)), ...
           'P1:SmokeNUDFT','直接NUDFT比对数值非有限或采样太少。');
    r=results.p2;
    if nnz(r.success)~=2
        for k=find(~r.success).'
            fprintf(2,'[P1P2 smoke] Trial %d | %s | %s\n',k, ...
                r.failure_id{k},r.failure_reason{k});
        end
        error('P2:SmokeTrial','2/2全流程机制开发试次未通过。');
    end
    assert(size(r.M_core,2)==4 && size(r.M_core,3)==4 && ...
        all(isfinite(r.M_core(r.success,:,:)),'all'), ...
        'P2:SmokeShape','4应变×4机制组MSE非法。');
    assert(all(r.common_core_count(r.success)>=cfg.p1p2.min_common_core) && ...
           all(r.common_roi_fraction(r.success)>=cfg.p1p2.min_common_roi_fraction), ...
           'P2:SmokeCoverage','固定共同Core/ROI覆盖不足。');
    % 零应变同一主信号、相同坐标的00与10必须基本无假应变。
    z00=reshape(r.M_core(r.success,1,1),[],1);
    z10=reshape(r.M_core(r.success,1,2),[],1);
    assert(all(z00<1e-10) && all(z10<1e-10), ...
        'P2:SmokeZero','零应变相同坐标的共模理论不变性未通过。');
    fprintf('[P1P2 smoke] PASS: P1 NUDFT finite; P2 2/2, fixed masks, zero-strain common invariance.\n');
    fprintf('NOTE: Smoke is functional evidence only, not mechanism statistics or model validity.\n');
end