function smoke_test_p1_density()
%SMOKE_TEST_P1_DENSITY 对嵌套散射随机测度作极小开发集功能自检。
% 不把少量试次的密度曲线理解成统计收敛性证明。
    cfg=config_p1p2();
    cfg.p1p2.p1_scat_repeats=2;
    truth=simulate_laser_sweep(cfg);
    out=p1_scatter_density_study(cfg,truth);
    if nnz(out.success)~=2
        for t=find(~out.success).'
            fprintf(2,'[P1 density smoke] trial %d | %s | %s\n', ...
                t,out.failure_id{t},out.failure_reason{t});
        end
        error('P1:SmokeDensity','2/2密度功能自检失败。');
    end
    assert(all(isfinite(out.core_rmse(out.success,:)),'all') && ...
           all(isfinite(out.raw_core_rmse(out.success,:)),'all'), ...
           'P1:SmokeDensityNumerics','Oracle和raw Core误差不是有限值。');
    % 相同seed下，基础层散射系数应精确等于最细层小单元复振幅之和。
    % 这是真正的“同一底层随机测度”耦合，而非仅使用相同随机种子。
    [~,coarse]=p1_nested_scatter(cfg,truth,out.seed(1),0);
    [~,fine]=p1_nested_scatter(cfg,truth,out.seed(1),2);
    grouped=sum(reshape(fine.coeff,4,[]),1).';
    assert(numel(coarse.coeff)==numel(grouped) && ...
           max(abs(coarse.coeff-grouped))<1e-12, ...
           'P1:SmokeCoupling','细粗网格并非同一底层复散射随机测度。');
    assert(all(diff(out.step_mm)<0), ...
           'P1:SmokeDensitySteps','散射细化网格间隔应逐层下降。');
    fprintf('[P1 density smoke] PASS: 2/2 coupled scatter fields, fixed-mask scoring.\n');
end