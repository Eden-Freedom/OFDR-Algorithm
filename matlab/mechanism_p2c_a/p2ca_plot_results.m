function p2ca_plot_results(r)
%P2CA_PLOT_RESULTS 三张纯数学观测可辨识性图，不代表物理随机验证。
    e=r.example;
    figure('Color','w','Name','P2c-A Fig1 | Single vs two delay singular values');
    vals={r.rank_one_known_offset.singular_values, ...
          r.rank_one_unknown_offset.singular_values, ...
          r.rank_two_unknown_offsets.singular_values};
    names={'one delay, calibrated offset','one delay, unknown offset', ...
           'two delays, independent unknown offsets'};
    hold on;
    for j=1:3
        s=vals{j};s=s(:);
        s(s<1e-12)=NaN; % 零值另由nullity明确表示，semilogy不能画0
        semilogy((1:numel(s)).',s,'-o','MarkerSize',3,'LineWidth',1);
    end
    hold off;grid on;
    xlabel('Ordered singular-value index (not spatial frequency)');
    ylabel('Singular value (dimensionless x=nu*dt)');
    legend(names,'Location','best');
    title(sprintf('Deterministic rank check: nullity [one %.0f, centered %.0f, two centered %.0f]', ...
        r.rank_one_known_offset.nullity, ...
        r.rank_one_unknown_offset.nullity, ...
        r.rank_two_unknown_offsets.nullity));

    figure('Color','w','Name','P2c-A Fig2 | Single-delay unobservable periodic direction');
    subplot(2,1,1);
    plot(e.k,e.x_original,'-');hold on;
    plot(e.k,e.x_blind_perturbed,'--');hold off;grid on;
    xlabel('Frequency time-cell index (0 based)');
    ylabel('nu*dt (cycles per cell)');
    legend('original monotone sweep','changed monotone sweep','Location','best');
    title('Different monotone sweeps, same exact single-delay phase');
    subplot(2,1,2);
    plot(e.t1_s/r.sample_dt_s, ...
         e.phi_blind_1-e.phi_original_1,'-o','MarkerSize',3);
    hold on;
    plot(e.t2_s/r.sample_dt_s, ...
         e.phi_blind_2-e.phi_original_2,'--','LineWidth',1.2);
    hold off;grid on;
    xlabel('Observed time / dt');
    ylabel('Phase difference (rad)');
    legend('first delay (blind)','second delay (sensitive)','Location','best');
    title('An exact null direction for 4-bin delay is seen by 5-bin delay');

    figure('Color','w','Name','P2c-A Fig3 | Unknown-delay linear-chirp ambiguity');
    plot(e.chirp_time_bins,e.chirp_phi_delay1,'-o','MarkerSize',3);hold on;
    plot(e.chirp_time_bins,e.chirp_phi_delay_alt,'--');
    hold off;grid on;
    xlabel('Observation time / dt');
    ylabel('Ideal unwrapped auxiliary phase (rad)');
    legend(sprintf('delay = %.2f dt',r.delay1_s/r.sample_dt_s), ...
           sprintf('delay = %.2f dt',e.tau_alt_s/r.sample_dt_s), ...
           'Location','best');
    title('Unknown delay + unknown phase offset: same phase for distinct linear sweeps');
end