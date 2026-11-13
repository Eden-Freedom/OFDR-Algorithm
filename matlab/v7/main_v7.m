function [cfg,results]=main_v7(cfg)
%MAIN_V7 V7 可观测静止区相位一致性原型；无真值校正，报告失败次数。
% 默认8次用于技术验证；论文统计配置36次与固定超参数、未见种子。
    here=fileparts(mfilename('fullpath'));addpath(fullfile(here,'../v6c'));
    if nargin<1||isempty(cfg),cfg=config_v7();end
    t0=tic;truth=simulate_laser_sweep(cfg);
    n=cfg.v7.repeats;labels={'oracle','independent_sswt','smoothed_sswt','static_affine','SAPC'};
    m=numel(labels);results.labels=labels;results.success=false(n,1);
    results.failure_reason=cell(n,1);results.core_rmse=nan(n,m);
    results.static_holdout=nan(n,m);results.static_all=nan(n,m);
    results.valid_fraction=nan(n,m);results.core_bias=nan(n,m);
    results.train_phase_before=nan(n,1);results.train_phase_after=nan(n,1);
    results.examples=struct();results.seed_scatter=nan(n,1);
    for j=1:n
        try
            trial=run_v7_trial(cfg,truth,j);
            results.success(j)=trial.valid;
            results.core_rmse(j,:)=trial.core_rmse(:).';
            results.static_holdout(j,:)=trial.static_holdout_rmse(:).';
            results.static_all(j,:)=trial.full_static_rmse(:).';
            results.valid_fraction(j,:)=trial.valid_fraction(:).';
            results.core_bias(j,:)=trial.core_bias(:).';
            results.train_phase_before(j)=trial.sapc_train_phase_before;
            results.train_phase_after(j)=trial.sapc_train_phase_after;
            results.seed_scatter(j)=trial.seed_scatter;
            if j==1,results.examples=trial.example;end
        catch ME
            results.failure_reason{j}=ME.message;
            if cfg.v7.verbose, fprintf('[V7 fail] trial %d: %s\n',j,ME.message);end
        end
    end
    results.cfg=cfg;results.runtime_s=toc(t0);
    good=results.success;results.summary.n_success=nnz(good);
    results.summary.failure_rate=1-nnz(good)/n;
    results.summary.mean_core=nan(1,m);results.summary.mean_holdout=nan(1,m);
    results.summary.mean_valid=nan(1,m);results.summary.core_CI95=nan(m,2);
    results.summary.paired_gain_sswt_vs_SAPC=NaN;
    results.summary.paired_gain_CI95=[NaN NaN];
    if any(good)
        results.summary.mean_core=mean(results.core_rmse(good,:),1);
        results.summary.mean_holdout=mean(results.static_holdout(good,:),1);
        results.summary.mean_valid=mean(results.valid_fraction(good,:),1);
        for k=1:m
            [lo,hi]=v6b_bootstrap_ci(results.core_rmse(good,k), ...
                cfg.v7.bootstrap_reps,cfg.v7.bootstrap_seed+k);
            results.summary.core_CI95(k,:)=[lo,hi];
        end
        diff=results.core_rmse(good,2)-results.core_rmse(good,5);
        results.summary.paired_gain_sswt_vs_SAPC=mean(diff);
        [lo,hi]=v6b_bootstrap_ci(diff,cfg.v7.bootstrap_reps,cfg.v7.bootstrap_seed+50);
        results.summary.paired_gain_CI95=[lo hi];
    end
    fprintf('\n======== V7 | Static-anchor phase-consistency PROTOTYPE ========\n');
    fprintf('Success %d/%d, failure %.1f%%, applied %.2f ue\n', ...
        nnz(good),n,100*results.summary.failure_rate,cfg.v7.strain_microeps);
    fprintf('Method             Core RMSE(ue)  Held-out static RMS(ue)  Valid(%%)\n');
    for k=1:m
        fprintf('%-19s %12.4f %21.4f %10.1f\n',labels{k}, ...
            results.summary.mean_core(k),results.summary.mean_holdout(k), ...
            100*results.summary.mean_valid(k));
    end
    fprintf('Paired SSWT minus SAPC core RMSE = %.4f ue, CI95=[%.4f %.4f]\n', ...
        results.summary.paired_gain_sswt_vs_SAPC,results.summary.paired_gain_CI95);
    fprintf('SAPC uses ONLY known upstream static phase (training). Downstream is held out.\n');
    fprintf('NO CLAIM OF BENEFIT if core, holdout, or validity fails to improve.\n');
    if cfg.v7.save_results
        if ~exist(cfg.v7.output_dir,'dir'),mkdir(cfg.v7.output_dir);end
        save(fullfile(cfg.v7.output_dir,'V7_static_anchor_pilot.mat'),'cfg','results','-v7.3');
        v7_export_tables(cfg,results);
    end
    if cfg.v7.make_plots,v7_plot_results(cfg,results);end
end
