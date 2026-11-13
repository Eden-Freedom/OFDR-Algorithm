function [cfg,results] = main_v6c(cfg)
%MAIN_V6C 非零已知应变前向 -> NUFFT -> gauge 相位 -> 实际应变真值对照。
% 根目录：addpath('matlab/v6c'); smoke_test_v6c; [cfg,res]=main_v6c();
% 默认：0/1/2/5/10/20 ue 扫描。完整模型明确包含载波相位和群延迟变化。
% 主要终点为：oracle 应变 RMSE，SSWT 应变 RMSE，静止区域虚假应变 RMSE。
    here=fileparts(mfilename('fullpath'));
    for j=1:5,addpath(fullfile(fileparts(here),sprintf('v%d',j)));end
    addpath(fullfile(fileparts(here),'v6'));
    addpath(fullfile(fileparts(here),'v6b'));
    if nargin<1||isempty(cfg),cfg=config_v6c();end
    t0=tic;truth=simulate_laser_sweep(cfg);
    [refSignal,scatter]=v6_rayleigh_signal(cfg,truth);
    source=struct('ref_signal',refSignal,'scatter',scatter);
    oracle_ref=v6_reconstruct_trace(cfg,truth,refSignal,truth.nu_offset_Hz);
    c_ref=v6_estimate_aux(cfg,truth,cfg.v6.aux_seed_ref);
    c_meas=v6_estimate_aux(cfg,truth,cfg.v6.aux_seed_meas);
    epsilons=unique([cfg.v6c.strain_sweep_microeps(:);cfg.v6c.strain_microeps]);
    results.version='V6c: known nonzero applied strain; physical phase sensitivity validation';
    results.truth=truth;
    results.scatterers=scatter;
    results.calibration.reference=c_ref;
    results.calibration.measurement=c_meas;
    results.strain_sweep_microeps=epsilons;
    results.strain_tests=cell(numel(epsilons),1);
    results.test_failure_reason=cell(numel(epsilons),1);
    for i=1:numel(epsilons)
        pair=v6c_forward_pair(cfg,truth,epsilons(i),source);
        trial=v6c_run_case(cfg,truth,pair,oracle_ref,c_ref,c_meas);
        results.strain_tests{i}=struct('strain_microeps',epsilons(i), ...
            'trial',trial,'geometry',pair.geometry);
        for j=1:numel(trial.order)
            k=trial.order{j};cc=trial.cases.(k);
            if ~cc.valid
                results.test_failure_reason{i}=[results.test_failure_reason{i} ' ' k ': ' cc.failure_reason];
            end
        end
    end
    results.reference_signal=refSignal;
    results.oracle_reference=oracle_ref;
    results.source=source;
    results.cfg=cfg;
    results.runtime_s=toc(t0);
    fprintf('\n========= OFDR V6c | Nonzero strain physical validation =========\n');
    fprintf('Scatterers %d | strain zone [%.3f,%.3f]m | ramp %.1fmm | gauge %.3fmm\n', ...
        numel(scatter.z_m),cfg.v6c.strain_start_m,cfg.v6c.strain_end_m, ...
        1e3*cfg.v6c.transition_m,1e3*cfg.v6.gauge_length_m);
    fprintf('Input(ue)  Case              Core truth(ue)  Core mean(ue)  Core RMSE(ue)  Static false RMS(ue)  Valid(%%)\n');
    for i=1:numel(epsilons)
        row=results.strain_tests{i}.trial;
        for j=1:numel(row.order)
            key=row.order{j};caseResult=row.cases.(key);
            if caseResult.valid
                m=caseResult.metrics;
                fprintf('%8.2f  %-17s  %12.4f  %12.4f  %12.4f  %18.4f  %8.1f\n', ...
                    epsilons(i),key,m.core_true_mean_microeps,m.core_measured_mean_microeps, ...
                    m.core_strain_rmse_microeps,m.static_false_strain_rmse_microeps,100*m.valid_fraction);
            else
                fprintf('%8.2f  %-17s  INVALID: %s\n',epsilons(i),key,caseResult.failure_reason);
            end
        end
    end
    fprintf('Notes: oracle must recover nonzero strain; no truth-coordinates used to correct SSWT; main noise OFF.\n');
    if cfg.v6c.run_mc
        results.mc=run_v6c_nonzero_mc(cfg,truth,source);
    end
    results.runtime_s=toc(t0);
    if cfg.v6c.save_results
        if ~exist(cfg.v6c.output_dir,'dir'),mkdir(cfg.v6c.output_dir);end
        save(fullfile(cfg.v6c.output_dir,'V6c_nonzero_strain.mat'),'cfg','results','-v7.3');
        v6c_export_tables(cfg,results);
    end
    if cfg.v6c.make_plots,v6c_plot_results(cfg,results);end
end
