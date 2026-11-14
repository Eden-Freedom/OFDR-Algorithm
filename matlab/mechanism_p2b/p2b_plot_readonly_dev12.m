function p2b_plot_readonly_dev12(T,d)
%P2B_PLOT_READONLY_DEV12 P2b事后只读诊断可视化：不改旧5图/原数据。
% 两幅图仅使用已运行开发trial，数据点是trial而不是独立Gauge。
% 对照中的二次项/留一常数模型均是探索性事后基线，不是新冻结证据。
    if nargin<2
        error('P2B:PlotInput','请先调用[T,d]=p2b_readonly_audit_dev12()。');
    end
    if d.n_success==0
        fprintf('[P2b readonly plots] 无成功trial，不绘图。\n');
        return;
    end
    ok=T.success;
    actual=T.C_actual_ue2(ok);
    predicted=T.C_pred_ue2(ok);
    lo=min([actual;predicted]);
    hi=max([actual;predicted]);
    margin=max((hi-lo)*.06,1e-6);

    figure('Color','w','Name','P2b Audit Fig6 | Primary trial predicted vs actual');
    scatter(actual,predicted,38,'filled');hold on;
    plot([lo-margin hi+margin],[lo-margin hi+margin],'k--','LineWidth',1.1);
    hold off;grid on;axis equal;
    xlabel('Actual common-mode C (microstrain^2)');
    ylabel('Predicted common-mode C (microstrain^2)');
    title(sprintf('P2b development | %.0f ue, alpha %.1f | %d/%d trials', ...
        d.primary_eps_ue,d.primary_alpha,d.n_success,d.n_total));
    legend('Each point = one independent paired trial','Perfect equality', ...
        'Location','best');

    figure('Color','w','Name','P2b Audit Fig7 | Primary paired absolute errors');
    ids=T.trial(ok);
    plot(ids,T.model_abs_error_ue2(ok),'o-','LineWidth',1.2);hold on;
    plot(ids,T.zero_abs_error_ue2(ok),'s--','LineWidth',1.2);
    plot(ids,T.quadratic_only_abs_error_ue2(ok),'^:','LineWidth',1.2);
    if d.n_success>=2
        plot(ids,T.LOO_abs_error_ue2(ok),'d-.','LineWidth',1.2);
    end
    hold off;grid on;
    xlabel('Development trial index (independent trials; not chronological time)');
    ylabel('Absolute prediction error in C (microstrain^2)');
    title('Primary 5ue, alpha=1 | quadratic-only and LOO are POST-HOC diagnostics');
    if d.n_success>=2
        legend('Full Taylor (Oracle r0 & ec)','Predeclared C=0', ...
            'Quadratic-only (post-hoc)','LOO constant (post-hoc)', ...
            'Location','best');
    else
        legend('Full Taylor (Oracle r0 & ec)','Predeclared C=0', ...
            'Quadratic-only (post-hoc)','Location','best');
    end
    fprintf('[P2b readonly plots] Fig6/7 rendered from existing development MAT only.\n');
end