function v6d_export_tables(cfg,r)
%V6D_EXPORT_TABLES 用 CSV 保存逐trial数据与CI，NaN保留为失败而非0。
    dir=cfg.v6d.output_dir;if ~exist(dir,'dir'),mkdir(dir);end
    n=numel(r.trial_success);k=numel(r.labels);
    T=table();T.trial=(1:n).';T.scatter_seed=r.seed_scatter;
    T.ref_seed=r.seed_ref;T.meas_seed=r.seed_meas;
    T.complete=r.trial_success;T.slope_ppm=r.slope_ppm;
    T.nonlinear_MHz=r.nonaffine_weighted_MHz;T.total_diff_MHz=r.diff_total_rmse_MHz;
    for j=1:k
        label=r.labels{j};T.([label '_core_ue'])=r.core_rmse(:,j);
        T.([label '_static_ue'])=r.static_rmse(:,j);
        T.([label '_phase_rad'])=r.gauge_phase_rmse(:,j);
        T.([label '_valid_fraction'])=r.raw_valid_fraction(:,j);
    end
    writetable(T,fullfile(dir,'V6d_paired_trials.csv'));
    S=table(r.labels(:),r.summary.mean_core_rmse(:),r.summary.ci_core(:,1), ...
        r.summary.ci_core(:,2),r.summary.mean_static_rmse(:),r.summary.mean_phase_rmse(:), ...
        'VariableNames',{'case_name','core_mean_ue','ci_lower_ue','ci_upper_ue', ...
                         'static_mean_ue','gauge_phase_mean_rad'});
    writetable(S,fullfile(dir,'V6d_summary.csv'));
end
