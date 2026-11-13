function [cfg,results]=main_v6d(cfg)
%MAIN_V6D 真值分量消融：无物理应变真值泄漏到待部署校准器（本程序不部署校准器）。
% 用法：addpath('matlab/v6d'); smoke_test_v6d; [cfg,r]=main_v6d();
    here=fileparts(mfilename('fullpath'));addpath(fullfile(here,'../v6c'));
    if nargin<1||isempty(cfg),cfg=config_v6d();end
    t=tic;truth=simulate_laser_sweep(cfg);
    results=run_v6d_ablation(cfg,truth);
    results.runtime_s=toc(t);results.cfg=cfg;
    fprintf('\n=========== V6d | paired nonzero-strain component ablation ==========\n');
    fprintf('Successful paired trials: %d/%d (%.1f%% failure)\n', ...
        results.summary.n_success,cfg.v6d.repeats,100*results.summary.failure_rate);
    fprintf('Component             Core RMSE(ue)     Static RMS(ue)  Gauge phase(rad)   CI95 core(ue)\n');
    for k=1:numel(results.labels)
        fprintf('%-22s %10.4f %17.4f %16.5f    [%.4f %.4f]\n', ...
            results.labels{k},results.summary.mean_core_rmse(k), ...
            results.summary.mean_static_rmse(k),results.summary.mean_phase_rmse(k), ...
            results.summary.ci_core(k,1),results.summary.ci_core(k,2));
    end
    fprintf('IMPORTANT: truth-based split is a DIAGNOSTIC, not a correction method.\n');
    if cfg.v6d.save_results
        if ~exist(cfg.v6d.output_dir,'dir'),mkdir(cfg.v6d.output_dir);end
        save(fullfile(cfg.v6d.output_dir,'V6d_component_ablation.mat'),'cfg','results','-v7.3');
        v6d_export_tables(cfg,results);
    end
    if cfg.v6d.make_plots,v6d_plot_results(cfg,results);end
end
