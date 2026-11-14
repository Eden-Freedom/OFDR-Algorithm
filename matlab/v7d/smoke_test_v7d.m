function smoke_test_v7d()
%SMOKE_TEST_V7D 仅两个新开发种子；证明程序流程，不做科研CI解释。
    smoke_test_v7d_feasibility();
    smoke_test_v7d_summary();
    cfg=config_v7d();
    cfg.v7d.development_repeats=2;
    cfg.v7d.make_plots=false;
    cfg.v7d.save_results=false;
    cfg.v7d.verbose=true;
    cfg.v7d.run_frozen_test=false;
    [~,results]=main_v7d(cfg);
    r=results.development;
    if nnz(r.success)~=2
        fprintf(2,'[V7d smoke] failed trials:\n');
        for i=find(~r.success).'
            fprintf(2,'trial %d | %s | %s\n',i, ...
                r.failure_id{i},r.failure_reason{i});
        end
        error('V7d:SmokeFailure','2/2开发试次未全部成功，禁止进入24次开发集。');
    end
    assert(size(r.core_rmse,2)==7 && ...
           all(all(isfinite(r.core_rmse(r.success,:)))) && ...
           all(all(isfinite(r.holdout_rmse(r.success,:)))), ...
           'V7d:SmokeMetrics','七方法Core/Holdout误差必须有限。');
    assert(all(r.common_core_count(r.success)>=15) && ...
           all(r.common_holdout_count(r.success)>=15), ...
           'V7d:SmokeMask','七方法共同Gauge不足。');
    assert(all(r.alpha_v7d(r.success)>=0 & r.alpha_v7d(r.success)<=1), ...
           'V7d:SmokeAlpha','候选alpha超范围。');
    assert(all(r.final_extra_peak_MHz(r.success)<= ...
               cfg.v7d.max_extra_correction_MHz+1e-10) && ...
           all(r.final_total_peak_MHz(r.success)<= ...
               cfg.v7d.max_total_correction_MHz+1e-10), ...
           'V7d:SmokeCoordinate','新方法最终坐标约束失败。');
    % alpha=0/1时对应Affine/Full SAPC；验证与原数值核完全等价。
    for i=find(r.success).'
        if abs(r.alpha_v7c(i))<1e-12
            assert(abs(r.core_rmse(i,6)-r.core_rmse(i,4))<1e-8, ...
                'V7d:SmokeV7cAffine','旧V7c回退不等于Affine。');
        elseif abs(r.alpha_v7c(i)-1)<1e-12
            assert(abs(r.core_rmse(i,6)-r.core_rmse(i,5))<1e-8, ...
                'V7d:SmokeV7cFull','旧V7c alpha=1不等于Full SAPC。');
        end
        if abs(r.alpha_v7d(i))<1e-12
            assert(abs(r.core_rmse(i,7)-r.core_rmse(i,4))<1e-8, ...
                'V7d:SmokeNewAffine','新V7d回退不等于Affine。');
        elseif abs(r.alpha_v7d(i)-1)<1e-12
            assert(abs(r.core_rmse(i,7)-r.core_rmse(i,5))<1e-8, ...
                'V7d:SmokeNewFull','新V7d alpha=1不等于Full SAPC。');
        end
    end
    fprintf('[V7d smoke] PASS: 2/2 paired 7-method development trials.\n');
    fprintf('NOTE: 2/2 smoke does not validate V7d superiority.\n');
end
