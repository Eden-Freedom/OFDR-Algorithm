function [cfg,results] = main_v6(cfg)
%MAIN_V6 V6a 零应变双扫描：共模抵消、差模残差、相关性、真实独立 SSWT。
% 从仓库根目录执行：addpath('matlab/v6'); [cfg,results]=main_v6();
%
% 重要限定：只模拟零应变、同一真实 TLS 轨迹、同一光纤/主信号，
% 无主探测噪声与扫描频段错配；等效应变换算系数尚未经过非零应变校验。
% 所以“虚假应变”指标仅为模型诊断，不等同于实际 OFDR 应变精度。
    here=fileparts(mfilename('fullpath'));
    for j=1:5
        addpath(fullfile(fileparts(here),sprintf('v%d',j)));
    end
    if nargin<1||isempty(cfg),cfg=config_v6();end
    total=tic;
    truth=simulate_laser_sweep(cfg);
    [s,scatter]=v6_rayleigh_signal(cfg,truth);
    cal_ref=v6_estimate_aux(cfg,truth,cfg.v6.aux_seed_ref);
    cal_meas=v6_estimate_aux(cfg,truth,cfg.v6.aux_seed_meas);
    controlled=v6_controlled_residuals(cfg,truth.N,truth.fs_Hz);
    oracle=v6_reconstruct_trace(cfg,truth,s,truth.nu_offset_Hz);
    cases=struct();order={};
    [cases,order]=add_case(cases,order,'oracle_oracle',truth.nu_offset_Hz,truth.nu_offset_Hz);
    [cases,order]=add_case(cases,order,'common_sswt',cal_ref.q_est_Hz,cal_ref.q_est_Hz);
    [cases,order]=add_case(cases,order,'independent_sswt',cal_ref.q_est_Hz,cal_meas.q_est_Hz);
    for j=1:numel(controlled.rho_target)
        rho=controlled.rho_target(j);
        label=sprintf('rho_%03d',round(rho*100));
        e1=controlled.e_ref_Hz;
        e2=controlled.e_meas_Hz{j};
        [cases,order]=add_case(cases,order,label,truth.nu_offset_Hz+e1,truth.nu_offset_Hz+e2);
    end
    results.version='V6a: paired zero-strain phase / equivalent strain proxy';
    results.model_warning=['Zero strain; same true sweep, frozen-frequency real interference, ' ...
        'fixed synthetic Rayleigh scatterers; equivalent strain sensitivity not validated by nonzero-strain forward model.'];
    results.truth=truth;
    results.main_signal_clean=s;
    results.scatterers=scatter;
    results.calibration.reference=cal_ref;
    results.calibration.measurement=cal_meas;
    results.controlled=controlled;
    results.oracle=oracle;
    results.cases=cases;
    results.case_order=order;
    results.runtime_s=toc(total);
    results.matlab_version=version();
    results.config=cfg;
    results.seeds=[cfg.v6.scatter_seed,cfg.v6.aux_seed_ref,cfg.v6.aux_seed_meas, ...
                   cfg.v6.inject_seed_ref,cfg.v6.inject_seed_independent];
    results.git_revision=local_git_revision(here);
    fprintf('\n============= V6a | Paired zero-strain OFDR =============\n');
    fprintf('Same physical main signal: YES | Applied strain: ZERO | main noise: OFF\n');
    fprintf('Scattering points=%d | z=[%.2f,%.2f]m | fs=%.1fkHz\n', ...
        numel(scatter.z_m),min(scatter.z_m),max(scatter.z_m),truth.fs_Hz/1000);
    fprintf('Gauge requested=%.3f mm, actual=%.3f mm; ROI=[%.2f, %.2f]m\n', ...
        1e3*cfg.v6.gauge_length_m,1e3*cases.oracle_oracle.metrics.gauge_length_actual_m, ...
        cfg.v6.roi_m(1),cfg.v6.roi_m(2));
    fprintf('Aux SSWT coordinate RMSE: reference %.4f MHz; measurement %.4f MHz\n', ...
        cal_ref.q_rmse_MHz,cal_meas.q_rmse_MHz);
    fprintf('Case                 diff-RMSE(MHz)  gauge-phase(RMS rad)  false-strain(RMS ue)  valid(%%)\n');
    for j=1:numel(order)
        c=cases.(order{j});
        fprintf('%-21s %13.5f %20.6f %22.6f %9.1f',order{j}, ...
            c.diff_coordinate_rmse_MHz,c.metrics.gauge_phase_rmse_rad, ...
            c.metrics.false_strain_rmse_microeps,100*c.metrics.valid_fraction);
        if ~c.valid, fprintf('  INVALID: %s',c.failure_reason);end
        fprintf('\n');
    end
    fprintf('All strain values are ZERO-strain equivalent proxy only; not validated true strain sensitivity.\n');
    fprintf('Elapsed %.3f s (including two CWT+SSWT calibrations).\n',results.runtime_s);
    if cfg.v6.save_results
        if ~exist(cfg.v6.output_dir,'dir'),mkdir(cfg.v6.output_dir);end
        save(fullfile(cfg.v6.output_dir,'V6a_zero_strain.mat'),'cfg','results','-v7.3');
        v6_export_metrics(cfg,results);
    end
    if cfg.v6.make_plots, v6_plot_results(cfg,results); end

    function [map,names]=add_case(map,names,key,qref,qmeas)
        c=struct();c.q_ref_Hz=qref(:);c.q_meas_Hz=qmeas(:);
        c.error_ref_Hz=qref(:)-truth.nu_offset_Hz(:);
        c.error_meas_Hz=qmeas(:)-truth.nu_offset_Hz(:);
        c.diff_coordinate_Hz=c.error_meas_Hz-c.error_ref_Hz;
        c.diff_coordinate_rmse_MHz=sqrt(mean(c.diff_coordinate_Hz.^2))/1e6;
        c.valid=false;c.failure_reason='';
        try
            c.ref=v6_reconstruct_trace(cfg,truth,s,qref);
            c.meas=v6_reconstruct_trace(cfg,truth,s,qmeas);
            c.metrics=v6_demodulate_zero_strain(cfg,c.ref,c.meas,oracle);
            c.valid=c.metrics.valid;
            c.failure_reason=c.metrics.failure_reason;
        catch ME
            c.metrics=empty_metrics();
            c.failure_reason=ME.message;
        end
        map.(key)=c;
        names{end+1}=key;
    end
end
function m=empty_metrics()
    m.valid=false;m.valid_fraction=0;
    m.gauge_phase_rmse_rad=NaN;
    m.false_strain_rmse_microeps=NaN;
    m.false_strain_bias_microeps=NaN;
    m.false_strain_p95_abs_microeps=NaN;
end
function sha=local_git_revision(here)
    repo=fileparts(fileparts(here));
    [status,out]=system(sprintf('git -C "%s" rev-parse HEAD',repo));
    if status==0,sha=strtrim(out);else,sha='unavailable';end
end
