function [cfg,results] = main_v6b(cfg)
%MAIN_V6B V6b：零应变校准差分机理的可重复统计和消融验证。
% 输入 config_v6b(); 未修改 V1-V6a 核心数值算法。
% 默认8个受控随机重复和4个真实SSWT重复是快速检查，并非论文级统计。
    here=fileparts(mfilename('fullpath'));
    addpath(fullfile(fileparts(here),'v6'));
    if nargin<1||isempty(cfg),cfg=config_v6b();end
    if ~isfield(cfg,'v6b'),error('请使用 config_v6b()。');end
    if cfg.v6b.repeats<2||cfg.v6b.sswt_repeats<1|| ...
       cfg.v6b.repeats~=floor(cfg.v6b.repeats)|| ...
       cfg.v6b.sswt_repeats~=floor(cfg.v6b.sswt_repeats)
        error('repeats 必须 >=2，sswt_repeats 必须 >=1，且均为整数。');
    end
    tic_all=tic;
    truth=simulate_laser_sweep(cfg);
    results.version='V6b: paired calibration residual mechanism, zero strain';
    results.model_limitations=['Zero applied strain; unchanged Rayleigh scatterers and true TLS sweep ' ...
        'within pairs; equivalent strain proxy not validated via nonzero-strain forward response.'];
    results.correlation=run_v6b_correlation_mc(cfg,truth);
    results.sswt=run_v6b_independent_sswt(cfg,truth);
    results.components=run_v6b_components(cfg,truth);
    results.spatial=run_v6b_spatial_gauge(cfg,truth);
    results.truth=truth;
    results.cfg=cfg;
    results.matlab_version=version();
    results.git_commit=v6b_git_rev(here);
    results.runtime_s=toc(tic_all);
    fprintf('\n====== V6b | zero-strain inter-scan error mechanism ======\n');
    fprintf('Controlled: %d trials x %d rho; SSWT independent: %d trials\n', ...
        cfg.v6b.repeats,numel(cfg.v6b.rho_values),cfg.v6b.sswt_repeats);
    fprintf('rho  valid/trials  diffMHz(mean)  gauge(rad,common)  false proxy(ue,common)  CI95(ue)\n');
    C=results.correlation;
    for i=1:numel(C.rho_target)
        s=C.summary;
        fprintf('%.2f  %3d/%-3d       %7.3f         %9.5f           %8.5f       [%.4f %.4f]\n', ...
            C.rho_target(i),s.n_success(i),C.repeats, ...
            s.mean_diff_MHz(i),s.mean_gauge_rad(i),s.mean_proxy_microeps(i), ...
            s.proxy_CI95_microeps(i,1),s.proxy_CI95_microeps(i,2));
    end
    fprintf('Independent SSWT: %d/%d valid, mean proxy %.5f ue, 95%% bootstrap [%.4f %.4f]\n', ...
        nnz(results.sswt.valid),results.sswt.repeats,results.sswt.mean_proxy_microeps, ...
        results.sswt.proxy_CI95_microeps(1),results.sswt.proxy_CI95_microeps(2));
    D=results.components.decomposition;
    fprintf('Differential SSWT decomposition: weighted mean %.4f MHz, slope %.3f ppm, residual %.4f MHz\n', ...
        D.weighted_mean_Hz/1e6,D.scale_ppm,D.nonlinear_weighted_rmse_Hz/1e6);
    fprintf('Warning: values above use ZERO-strain equivalent proxy; not yet validated strain sensitivity.\n');
    fprintf('Elapsed %.3f s; failures retained with reasons.\n',results.runtime_s);
    if cfg.v6b.save_results
        if ~exist(cfg.v6b.output_dir,'dir'),mkdir(cfg.v6b.output_dir);end
        save(fullfile(cfg.v6b.output_dir,'V6b_zero_strain_mechanism.mat'), ...
            'cfg','results','-v7.3');
        v6b_export_tables(results,cfg);
    end
    if cfg.v6b.make_plots,v6b_plot_results(results,cfg);end
end
function sha=v6b_git_rev(here)
    repo=fileparts(fileparts(here));
    [status,out]=system(sprintf('git -C "%s" rev-parse HEAD',repo));
    if status==0,sha=strtrim(out);else,sha='unavailable';end
end
