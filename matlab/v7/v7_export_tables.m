function v7_export_tables(cfg,r)
%V7_EXPORT_TABLES 所有失败trial保留为NaN，配对随机种子不当作像素级抽样。
    dir=cfg.v7.output_dir;
    n=numel(r.success);T=table((1:n).',r.success,r.seed_scatter, ...
        'VariableNames',{'trial','success','scatter_seed'});
    for k=1:numel(r.labels)
        key=r.labels{k};
        T.([key '_core_rmse_ue'])=r.core_rmse(:,k);
        T.([key '_holdout_static_ue'])=r.static_holdout(:,k);
        T.([key '_valid_frac'])=r.valid_fraction(:,k);
    end
    writetable(T,fullfile(dir,'V7_trial_results.csv'));
    S=table(r.labels(:),r.summary.mean_core(:),r.summary.core_CI95(:,1), ...
        r.summary.core_CI95(:,2),r.summary.mean_holdout(:),r.summary.mean_valid(:), ...
        'VariableNames',{'method','core_rmse_ue','ci_low','ci_high', ...
                         'static_holdout_ue','valid_fraction'});
    writetable(S,fullfile(dir,'V7_method_summary.csv'));
end
