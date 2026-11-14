function [cfg,results]=main_p1p2(cfg)
%MAIN_P1P2 新方向第一轮：P1数值/散射模型核查 + P2共模差模机制消融。
% 真值只参与机制注入、Oracle评价与误差评分，不做部署拟合。
% 仅允许新开发种子，冻结测试由p1p2_assert_protocol禁止。
    if nargin<1||isempty(cfg),cfg=config_p1p2();end
    p1p2_assert_protocol(cfg);
    results.protocol_id=cfg.p1p2.protocol;
    results.evidence='Development mechanism experiment; not a deployable algorithm';
    results.method_note='Common/differential error injected relative to qtrue, same physical paired signals';
    truth=simulate_laser_sweep(cfg);
    if cfg.p1p2.run_p1_direct
        results.p1_direct=p1_run_oracle_nudft(cfg,truth);
    end
    if cfg.p1p2.run_p1_density
        results.p1_density=p1_scatter_density_study(cfg,truth);
    end
    if cfg.p1p2.run_p2
        results.p2=p2_run_trials(cfg,truth);
        s=results.p2.summary;
        fprintf('\n========== P2 | COMMON / DIFFERENTIAL MECHANISM | DEV ==========\n');
        fprintf('Success %d/%d, failures %d (%.2f%%)\n', ...
            s.n_success,s.n_total,s.n_failure,100*s.failure_rate);
        if s.n_success>0
            fprintf('Strain (ue): ');fprintf(' %.2f',s.strain_microeps);fprintf('\n');
            fprintf('Mean common effect C (ue^2): ');fprintf(' %+.6g',s.mean_C);fprintf('\n');
            fprintf('Mean differential effect D (ue^2): ');fprintf(' %+.6g',s.mean_D);fprintf('\n');
            fprintf('Mean signed interaction I (ue^2): ');fprintf(' %+.6g',s.mean_I);fprintf('\n');
            fprintf('Mean ROI-common gauge: %.2f%%\n',100*s.mean_common_roi_fraction);
            fprintf('WARNING: 8-trial development CIs are exploratory, not a new algorithm claim.\n');
        end
    end
    if cfg.p1p2.save_results
        folder=cfg.p1p2.output_dir;
        if ~exist(folder,'dir'),mkdir(folder);end
        save(fullfile(folder,'P1P2_DEVELOPMENT_results.mat'),'cfg','results','-v7.3');
        if isfield(results,'p2'),p2_export_trials(folder,results.p2);end
    end
    if cfg.p1p2.make_plots
        p1p2_plot_results(cfg,results);
    end
    fprintf('No frozen experiment executed; all reported results are development/mechanism only.\n');
end