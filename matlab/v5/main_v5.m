function [cfg,context,results] = main_v5(cfg)
%MAIN_V5 V5 P0/P1 主入口：基准收敛→比例误差→真实 SSWT 残差倍率。
% 在仓库根目录：addpath('matlab/v5'); [cfg,ctx,r]=main_v5();
% 第一轮不重新生成主信号（1.25m 单反射点、无噪声），只修改估计光频。
% 附加 B/C、D、E 实验使用 cfg.v5.do_* 开关启动，或单独调用相应函数。
    here=fileparts(mfilename('fullpath'));
    for version=1:4
        addpath(fullfile(fileparts(here),sprintf('v%d',version)));
    end
    if nargin<1||isempty(cfg),cfg=config_v5();end
    cfg.plot.enabled=false;cfg.v4.plot_enabled=false;
    total=tic;
    context=v5_setup(cfg,true);
    results.A=run_A_fine_reference_v5(context);
    results.B_scale=run_B_scale_v5(context);
    results.B_residual=run_B_residual_scale_v5(context);
    results.D=run_D_diagnostics_v5(context);
    results.requirements=v5_calibration_requirements(context,results.B_scale,results.B_residual);
    if cfg.v5.do_error_families
        results.B_families=run_B_error_families_v5(context);
    end
    if cfg.v5.do_snr
        results.D_snr=run_D_snr_v5(cfg);
    end
    if cfg.v5.do_doublet
        results.E=run_E_doublet_v5(context);
    end
    results.runtime_s=toc(total);
    results.experiment_plan='docs/V5_CALIBRATION_ERROR_PROPAGATION_PLAN.md';
    results.version='V5 baseline and calibration-error propagation';
    results.matlab_version=version();
    results.random_seed=cfg.sim.random_seed;
    results.git_revision=git_revision(here);
    results.inputs.t_s=context.truth.t_s;
    results.inputs.q_true_Hz=context.q_true_Hz;
    results.inputs.q_sswt_Hz=context.q_sswt_Hz;
    results.inputs.aux_clean=context.signals.aux_clean;
    results.inputs.aux_noisy=context.signals.aux;
    results.inputs.beat_true_Hz=context.signals.aux_beat_Hz;
    results.inputs.beat_hat_Hz=context.f_sswt_Hz;
    results.inputs.main_clean=context.signals.main_clean;
    results.inputs.main_noisy=context.signals.main;
    results.inputs.window_true=context.window_true;
    results.inputs.density_true=context.weights_true;
    results.inputs.window_mode=cfg.v3.window;
    results.inputs.density_mode=cfg.v3.density_mode;
    results.inputs.nufft_params=cfg.v3;
    results.inputs.distance_coarse_m=context.z_coarse_m;
    if cfg.v5.save_results
        if ~exist(cfg.v5.output_dir,'dir'),mkdir(cfg.v5.output_dir);end
        save(fullfile(cfg.v5.output_dir,'V5_baseline_P0_P1.mat'),'cfg','results','-v7.3');
    end
    if cfg.v5.save_results
        v5_export_tables(results,cfg);
    end
    if cfg.v5.make_plots
        v5_plot_results(results,cfg);
    end
    fprintf('\n=========== OFDR V5 | Calibration error propagation ===========\n');
    fprintf('P0 ideal single-peak FWHM: coarse %.4f mm, fine %.4f mm, SSWT fine %.4f mm\n', ...
       results.A.coarse_metrics.fwhm_m*1e3,results.A.reference_fwhm_m*1e3,results.A.sswt_fwhm_m*1e3);
    fprintf('P0 grid-convergence check |0.02-0.01 mm| = %.4f um\n',results.A.fwhm_convergence_m*1e6);
    fprintf('Illustrative requirements at z=2.4m: scale <= %.1f ppm; nonlinear RMS <= %.3f MHz (phase model).\n', ...
        results.requirements.scale_limit_ppm,results.requirements.nonlinear_error_rms_limit_MHz);
    fprintf('P1 proportional scan valid %d/%d; SSWT scale scan valid %d/%d\n', ...
       results.B_scale.valid_count,numel(results.B_scale.valid), ...
       results.B_residual.valid_count,numel(results.B_residual.valid));
    fprintf('Elapsed %.3fs. Failures are recorded; NaNs are not corrected automatically.\n',results.runtime_s);
    fprintf('Physical FWHM is not coarse-grid bin spacing; MATLAB output needs local validation.\n');
end
function sha=git_revision(here)
    repo=fileparts(fileparts(here));
    [status,msg]=system(sprintf('git -C "%s" rev-parse HEAD',repo));
    if status==0,sha=strtrim(msg);else,sha='unavailable';end
end
