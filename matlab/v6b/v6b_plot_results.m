function v6b_plot_results(results,cfg)
%V6B_PLOT_RESULTS 五幅论文问题导向的图，每图的阅读指南见 docs/V6B_FIGURE_READING_GUIDE.md。
    C=results.correlation;S=results.sswt;A=results.components;G=results.spatial;
    rho=C.rho_target(:);
    fig=figure('Name','V6b Figure 1 | correlation and matched-mask uncertainty','Color','w');
    subplot(3,1,1);
    plot(rho,C.summary.mean_diff_MHz,'o-','LineWidth',1.3);grid on;
    ylabel('Diff. q RMSE (MHz)');
    title(sprintf('Same per-scan injected RMSE | %d paired random trials',C.repeats));
    subplot(3,1,2);
    plot(rho,C.summary.mean_gauge_rad,'o-','LineWidth',1.3);grid on;
    ylabel('Gauge phase RMS (rad)');
    title('All rho groups scored on a common valid-gauge mask per trial');
    subplot(3,1,3);
    mu=C.summary.mean_proxy_microeps;
    ci=C.summary.proxy_CI95_microeps;
    low=max(0,mu-ci(:,1));high=max(0,ci(:,2)-mu);
    errorbar(rho,mu,low,high,'o-','LineWidth',1.3);grid on;
    xlabel('Inter-scan calibration error correlation (rho)');
    ylabel('False strain proxy RMS (ue)');
    title('Paired-trial bootstrap 95% CI on mean; INVALID trials excluded and counted');
    save_fig(fig,cfg,'v6b_fig1_correlation_ci.png');

    fig=figure('Name','V6b Figure 2 | differential error vs gauge phase','Color','w');
    subplot(2,1,1);hold on;colors=lines(numel(rho));
    for i=1:numel(rho)
        valid=C.valid(i,:) & isfinite(C.common_gauge_rmse_rad(i,:));
        plot(C.diff_rmse_MHz(i,valid),C.common_gauge_rmse_rad(i,valid), ...
             'o','Color',colors(i,:),'MarkerFaceColor',colors(i,:));
    end
    grid on;xlabel('Inter-scan q difference RMSE (MHz)');
    ylabel('Matched-mask gauge RMS (rad)');
    legend(arrayfun(@(a)sprintf('rho = %.2f',a),rho,'UniformOutput',false), ...
        'Location','northwest');
    title('Each point is one independent fiber+error realization (not independent pixels)');
    subplot(2,1,2);
    hold on;
    for i=1:numel(rho)
        valid=C.valid(i,:) & isfinite(C.common_gauge_rmse_rad(i,:));
        plot(C.diff_nonlinear_rmse_MHz(i,valid),C.common_gauge_rmse_rad(i,valid), ...
             'o','Color',colors(i,:),'MarkerFaceColor',colors(i,:));
    end
    grid on;xlabel('Weighted non-affine differential error RMS (MHz)');
    ylabel('Matched-mask gauge RMS (rad)');
    title('Does non-affine residual predict gauge phase better than total differential RMSE?');
    save_fig(fig,cfg,'v6b_fig2_error_structure.png');

    fig=figure('Name','V6b Figure 3 | differential residual ablation','Color','w');
    x=(1:numel(A.case_order)).';
    subplot(3,1,1);
    bar(x,A.diff_rmse_MHz);grid on;
    ylabel('Diff. RMSE (MHz)');
    title(sprintf('SSWT difference weighted slope %.3f ppm, non-affine %.3f MHz', ...
        A.decomposition.scale_ppm,A.decomposition.nonlinear_weighted_rmse_Hz/1e6));
    subplot(3,1,2);
    bar(x,A.gauge_rmse_rad);grid on;
    ylabel('Gauge RMS (rad)');
    subplot(3,1,3);
    bar(x,A.false_proxy_rmse_microeps);grid on;
    ylabel('False strain proxy (ue)');
    set(gca,'XTick',x,'XTickLabel', ...
        {'No diff','Anchored ramp','Anchored nonlinear','Full diff'});
    xtickangle(12);title('Diagnostic components use oracle truth; NOT deployable correction');
    save_fig(fig,cfg,'v6b_fig3_component_ablation.png');

    fig=figure('Name','V6b Figure 4 | distance and gauge length','Color','w');
    mid=mean(G.distance_bands_m,2);
    subplot(2,1,1);
    imagesc(mid,G.gauge_actual_mm,G.gauge_rmse_rad);axis xy;colorbar;
    xlabel('Distance-band center (m)');ylabel('Actual gauge length (mm)');
    title('Gauge phase RMS (rad), same rho=0 injected errors across all cells');
    subplot(2,1,2);
    imagesc(mid,G.gauge_actual_mm,100*G.valid_fraction);axis xy;colorbar;
    xlabel('Distance-band center (m)');ylabel('Actual gauge length (mm)');
    title('Valid gauge points (%) – interpret RMS with validity fraction');
    save_fig(fig,cfg,'v6b_fig4_spatial_gauge_map.png');

    fig=figure('Name','V6b Figure 5 | repeated independent SSWT','Color','w');
    subplot(2,1,1);
    hold on;
    plot(1:S.repeats,S.reference_rmse_MHz,'o-');
    plot(1:S.repeats,S.measurement_rmse_MHz,'o-');
    plot(1:S.repeats,S.diff_rmse_MHz,'k*-');
    grid on;xlabel('Independent SSWT paired trial');
    ylabel('Calibration RMSE (MHz)');
    legend('Reference SSWT','Measurement SSWT','Difference','Location','best');
    title('Real auxiliary-noise SSWT pairs: per-scan RMSE is NOT forced equal');
    subplot(2,1,2);
    yyaxis left;
    plot(1:S.repeats,S.gauge_rmse_rad,'o-');
    ylabel('Gauge phase RMS (rad)');
    yyaxis right;
    plot(1:S.repeats,S.valid_fraction*100,'s-');
    ylabel('Valid fraction (%)');
    xlabel('Independent SSWT paired trial');grid on;
    title('Zero applied strain; gauge phase and dropout must both be reported');
    save_fig(fig,cfg,'v6b_fig5_independent_sswt.png');
end
function save_fig(fig,cfg,filename)
    if ~cfg.v6b.save_results,return;end
    output=fullfile(cfg.v6b.output_dir,'figures');
    if ~exist(output,'dir'),mkdir(output);end
    print(fig,fullfile(output,filename),'-dpng','-r150');
end
