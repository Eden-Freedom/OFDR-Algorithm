function p1p2_plot_results(cfg,results)
%P1P2_PLOT_RESULTS 仅开发机制图；完整逐图指南在docs中。
    if isfield(results,'p1_direct')
        a=results.p1_direct;
        figure('Color','w','Name','P1 Fig1 | Oracle NUFFT vs direct NUDFT');
        bar(a.rel_l2);
        set(gca,'XTickLabel',a.labels);
        ylabel('Relative L2 complex spectrum discrepancy');
        title(sprintf('P1 DEV: %d equal-window, equal-density spatial bins',a.tested_bins));
        grid on;
    end
    if isfield(results,'p1_density')
        a=results.p1_density;
        if nnz(a.success)>0
            figure('Color','w','Name','P1 Fig2 | nested scatter convergence');
            plot(a.step_mm,a.mean_core,'-o','LineWidth',1.4);hold on;
            plot(a.step_mm,a.mean_raw,'-s','LineWidth',1.4);
            hold off;grid on;
            set(gca,'XDir','reverse');
            xlabel('Nested scatterer cell width (mm)');
            ylabel('Oracle Core RMSE (microstrain)');
            legend('9-bin averaged gauge','Raw gauge phasor','Location','best');
            title(sprintf('P1 DEV, %d/%d success: coupled random measure, fixed-mask per trial', ...
                    nnz(a.success),a.n_trials));
        end
    end
    if ~isfield(results,'p2'),return;end
    r=results.p2;s=r.summary;
    if s.n_success==0,return;end
    eps=s.strain_microeps;
    figure('Color','w','Name','P2 Fig1 | Four-arm Core RMSE versus strain');
    plot(eps,s.mean_rmse,'-o','LineWidth',1.35);
    xlabel('Applied strain (microstrain)');
    ylabel('Mean paired-trial Core RMSE (microstrain)');
    legend(r.labels,'Location','best');
    title(sprintf('P2 DEV | %d/%d valid trials | fixed spatial mask within each trial', ...
                  s.n_success,s.n_total));
    grid on;

    figure('Color','w','Name','P2 Fig2 | Signed common/differential interaction');
    subplot(2,1,1);
    plot(eps,s.mean_C,'-o',eps,s.mean_D,'-s',eps,s.mean_I,'-^', ...
         'LineWidth',1.2);
    xlabel('Applied strain (microstrain)');
    ylabel('Signed mean squared-error contrast (microstrain^2)');
    legend('C = M10 - M00','D = M01 - M00', ...
           'I = M11 - M10 - M01 + M00','Location','best');
    title('Additivity tested in MSE, NOT a nonnegative error budget');
    grid on;
    subplot(2,1,2);
    low=s.I_CI95(:,1);high=s.I_CI95(:,2);
    if all(isfinite(low))&&all(isfinite(high))
        errorbar(eps,s.mean_I,s.mean_I-low,high-s.mean_I,'o-','LineWidth',1.2);
    else
        plot(eps,s.mean_I,'o-','LineWidth',1.2);
    end
    hold on;plot([min(eps) max(eps)],[0 0],'k--');hold off;grid on;
    xlabel('Applied strain (microstrain)');
    ylabel('Interaction I (microstrain^2)');
    title('95% bootstrap by whole trial; small development n is exploratory');

    if isfield(r,'example')
        x=r.example;
        figure('Color','w','Name','P2 Fig3 | one example gauge strain at largest strain');
        plot(x.z_gauge_mid_m,x.true_strain,'k-','LineWidth',1.8);hold on;
        for a=1:4
            plot(x.z_gauge_mid_m,x.measured{a},'LineWidth',.8);
        end
        hold off;grid on;
        xlim([cfg.v6c.strain_start_m-.08 cfg.v6c.strain_end_m+.08]);
        xlabel('Gauge midpoint distance (m)');
        ylabel('Gauge strain (microstrain)');
        legend([{'Known gauge-averaged strain'},r.labels], ...
            'Location','best');
        title(sprintf('Paired scatter example, applied %.1f microstrain; invalid positions NaN', ...
            eps(end)));
    end
end