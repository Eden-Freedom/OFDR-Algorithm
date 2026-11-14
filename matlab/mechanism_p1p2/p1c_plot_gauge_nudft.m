function p1c_plot_gauge_nudft(a)
%P1C_PLOT_GAUGE_NUDFT P1c已知开发种子上的数值一致性可视化。
% 图1显示固定Core位置上的直接NUDFT-NUFFT应变差及尾部误差。
% 图2显示Oracle Core RMSE对照；不表示实验创新/独立统计样本。
    z=a.core_midpoint_m(:);
    delta=a.direct_minus_nufft_strain_ue(:);
    if numel(z)~=numel(delta) || isempty(z)
        error('P1C:Plot','缺少逐Core Gauge误差。');
    end
    figure('Color','w','Name','P1c Fig1 | Direct NUDFT minus NUFFT Gauge error');
    subplot(2,1,1);
    plot(z,delta,'.','MarkerSize',7);hold on;
    plot([min(z) max(z)],[0 0],'k--');hold off;grid on;
    xlabel('Fixed Core gauge midpoint z (m)');
    ylabel('NUDFT - NUFFT strain (microstrain)');
    title(sprintf('Same known P1a seed | %d fixed Core gauges | no re-selection',a.n_core_gauges));
    subplot(2,1,2);
    mag=sort(abs(delta));
    plot(100*(1:numel(mag)).'/numel(mag),mag,'LineWidth',1.2);
    grid on;
    xlabel('Empirical percentile of |numerical strain difference| (%)');
    ylabel('Absolute difference (microstrain)');
    title('Per-gauge numerical discrepancy tail; NOT a bootstrap CI');

    figure('Color','w','Name','P1c Fig2 | Oracle Gauge RMSE NUFFT vs direct NUDFT');
    vals=[a.oracle_core_NUFFT_RMSE_ue,a.oracle_core_NUDFT_RMSE_ue];
    bar(vals);grid on;
    set(gca,'XTick',1:2,'XTickLabel',{'NUFFT','Direct NUDFT'});
    ylabel('Oracle Core strain RMSE (microstrain)');
    title(sprintf('Fixed same Core mask | signed difference %+.6g ue | bound %.6g ue', ...
        a.oracle_rmse_difference_ue,a.core_rmse_difference_bound_ue));
end