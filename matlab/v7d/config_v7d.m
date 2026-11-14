function cfg=config_v7d()
%CONFIG_V7D V7d-PF：仅探索“逐候选可行性”，不更改已冻结的V7c。
% V7c原α网格、CV置信度、Gauss-Newton和物理仿真均继承。
% 本阶段只开放开发集；冻结种子虽预留，但在程序层面锁定。
    here=fileparts(mfilename('fullpath'));
    addpath(fullfile(fileparts(here),'v7c'));
    cfg=config_v7c();
    cfg.v7c.run_development=false;
    cfg.v7c.run_frozen_test=false;
    cfg.v7c.run_conditions=false;
    cfg.v7c.make_plots=false;
    cfg.v7c.save_results=false;
    cfg.v7d.protocol_id='V7D_PF_DEV_2026-11-13_A';
    cfg.v7d.output_dir=fullfile(here,'output');
    cfg.v7d.development_repeats=24;
    cfg.v7d.frozen_test_repeats=100;
    cfg.v7d.run_development=true;
    cfg.v7d.run_frozen_test=false;
    cfg.v7d.allow_frozen_test=false; % 需独立审查与正式冻结协议后才可解除
    cfg.v7d.bootstrap_reps=2000;
    cfg.v7d.bootstrap_seed=270131;
    cfg.v7d.verbose=false;
    cfg.v7d.make_plots=true;
    cfg.v7d.save_results=true;
    % 新的种子空间；不与V7b历史盲测和V7c开发/保留冻结种子重叠。
    cfg.v7d.dev_seed_base=[111001001 121001001 131001001];
    cfg.v7d.test_seed_base=[211001001 221001001 231001001];
    cfg.v7d.scatter_stride=149;
    cfg.v7d.aux_stride=163;
    % 以下数值按原V7c固定，不进行任何基于V7c开发真值的再调参。
    cfg.v7d.alpha_grid=cfg.v7c.alpha_grid;
    cfg.v7d.max_extra_correction_MHz=cfg.v7c.max_extra_correction_MHz;
    cfg.v7d.max_total_correction_MHz=cfg.v7.max_correction_MHz;
    cfg.v7d.cv_required_relative_gain=cfg.v7c.cv_required_relative_gain;
    cfg.v7d.cv_required_absolute_rad=cfg.v7c.cv_required_absolute_rad;
    cfg.v7d.min_data_rcond=cfg.v7c.min_data_rcond;
end
