function p2b_plot_results(r)
%P2B_PLOT_RESULTS 新开发组只展示固定预设alpha的预测精度与模型局限。
    s=r.summary;
    if s.n_success==0,return;end
    eps=s.strains_microeps(:);
    for v=1:numel(s.test_alpha)
        figure('Color','w','Name', ...
            sprintf('P2b Fig%d | Actual vs local predicted C',v));
        plot(eps,s.mean_C_actual(:,v),'-o','LineWidth',1.4);hold on;
        plot(eps,s.mean_C_pred(:,v),'--s','LineWidth',1.4);hold off;grid on;
        xlabel('Applied strain (microstrain)');
        ylabel('Common-mode MSE contrast C (microstrain^2)');
        legend('Actual MSE difference','Local derivative prediction','Location','best');
        title(sprintf('DEVELOPMENT %d/%d | held-out alpha %.2f | fixed Core mask', ...
            s.n_success,s.n_total,s.test_alpha(v)));
    end
    j=numel(eps);
    v=numel(s.test_alpha);
    figure('Color','w','Name','P2b Fig3 | Trial-level prediction error at max strain');
    delta=reshape(r.prediction_residual(r.success,j,v),[],1);
    plot(find(r.success),delta,'o-');hold on;
    plot([.5 r.n_trials+.5],[0 0],'k--');hold off;grid on;
    xlabel('Development paired trial index');
    ylabel('Actual minus predicted C (microstrain^2)');
    title(sprintf('Applied strain %.1f microstrain; alpha %.2f; failures=%d', ...
        eps(end),s.test_alpha(end),s.n_failure));

    figure('Color','w','Name','P2b Fig4 | Local h sensitivity');
    plot(eps,s.mean_gradient_rms,'-o','LineWidth',1.2);hold on;
    plot(eps,s.mean_gradient_h_difference,'--s','LineWidth',1.2);
    hold off;grid on;
    xlabel('Applied strain (microstrain)');
    ylabel('Directional derivative RMS (microstrain / alpha)');
    legend('Primary h derivative RMS','RMS difference between h values', ...
        'Location','best');
    title('Difference in gradients diagnoses local step sensitivity, not truth performance');
    if isfield(r,'example') && isfield(r.example,'midpoint_m')
        ex=r.example;
        figure('Color','w','Name','P2b Fig5 | Example spatial first-order prediction');
        plot(ex.midpoint_m,ex.actual_diff_alpha1_ue,'.');hold on;
        plot(ex.midpoint_m,ex.linear_diff_alpha1_ue,'-','LineWidth',1.2);
        hold off;grid on;
        xlabel('Fixed Core gauge midpoint z (m)');
        ylabel('Relative to alpha=0 strain change (microstrain)');
        legend('Actual alpha=1 minus alpha=0','First-order alpha*g prediction', ...
            'Location','best');
        title('One scatter realization, 5 microstrain; never infer population from this view');
    end
end