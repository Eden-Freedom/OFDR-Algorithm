function p2ca_plot_task_relevance(r)
%P2CA_PLOT_TASK_RELEVANCE 绘制辅助盲模式是否影响主点反射相位的数学示例。
% 不是Rayleigh、相位敏感OFDR空间重构或实际应变误差图。
    figure('Color','w','Name','P2c-A2 Fig4 | Auxiliary null mode and main delay');
    subplot(2,1,1);
    plot(r.k,r.x_reference,'-','LineWidth',1.2);hold on;
    plot(r.k,r.x_measurement,'--','LineWidth',1.2);
    hold off;grid on;
    xlabel('Frequency sample cell index (0-based)');
    ylabel('Relative frequency x = nu * dt (cycles/cell)');
    title('Two strictly monotone sweeps, different by auxiliary-null periodic component');
    legend('Reference sweep','Measurement sweep','Location','best');

    subplot(2,1,2);
    plot(r.aux_t_over_dt,r.aux_phase_difference_rad,'-o', ...
        'MarkerSize',3,'LineWidth',1.0);
    hold on;
    plot(r.aux_t_over_dt,r.main_phase_difference_rad,'--', ...
        'LineWidth',1.3);
    plot(r.aux_t_over_dt,r.main_same_delay_phase_difference_rad,':', ...
        'LineWidth',1.2);
    hold off;grid on;
    xlabel('Shared observation time / dt');
    ylabel('Measurement - reference interferometric phase (rad)');
    legend('Auxiliary delay 4 dt: blind','Main single point delay 2 dt: sensitive', ...
       'Main delay 4 dt: blind too','Location','best');
    title('Auxiliary-unobservable drift may or may not affect a main delay');

    figure('Color','w','Name','P2c-A2 Fig5 | Main delay sensitivity vs common cancellation');
    plot(r.aux_t_over_dt,r.main_phase_difference_rad,'-o','MarkerSize',3);
    hold on;
    plot(r.aux_t_over_dt,r.main_common_mode_difference_rad,'--', ...
         'LineWidth',1.3);
    hold off;grid on;
    xlabel('Shared observation time / dt');
    ylabel('Paired main phase difference (rad)');
    legend('Blind component only in measurement sweep', ...
           'Identical blind component in both scans', ...
           'Location','best');
    title('Paired-scan differential effect; NOT a strain estimate');
end