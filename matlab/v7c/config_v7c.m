function cfg=config_v7c()
%CONFIG_V7C V7c: 训练区空间隔离交叉验证的可信度门控 SAPC (CV-SAPC)。
% 研究版本与 V7b 的百次测试种子严格隔离；默认只运行开发集。
    here=fileparts(mfilename('fullpath'));
    addpath(fullfile(fileparts(here),'v7b'));
    cfg=config_v7b();
    cfg.v7b.run_blind=false;cfg.v7b.run_conditions=false;
    cfg.v7b.make_plots=false;cfg.v7b.save_results=false;
    cfg.v7.make_plots=false;cfg.v7.save_results=false;
    cfg.v7c.output_dir=fullfile(here,'output');
    cfg.v7c.protocol_id='V7C_CV_SAPC_2026-11-13_B';
    cfg.v7c.run_development=true;   % 可调整/诊断的开发集，不是盲测
    cfg.v7c.run_frozen_test=false;  % 开发结论锁定后显式置 true
    cfg.v7c.run_conditions=false;   % 扩展物理扫描，单独运行
    cfg.v7c.development_repeats=24;
    cfg.v7c.frozen_test_repeats=100;
    cfg.v7c.condition_repeats=12;  % 仅预览；正式>=30
    cfg.v7c.bootstrap_reps=2000;
    cfg.v7c.bootstrap_seed=260131;
    cfg.v7c.verbose=false;cfg.v7c.make_plots=true;cfg.v7c.save_results=true;
    % 与 V7/V7b 已使用的散射及辅助随机种子不重合。
    cfg.v7c.dev_seed_base=[41001001 51001001 61001001];
    cfg.v7c.test_seed_base=[71001001 81001001 91001001];
    cfg.v7c.group_seed_stride=100000;
    cfg.v7c.scatter_stride=149;cfg.v7c.aux_stride=163;
    % 上游已知静态段内做两个空间阻塞验证；train 与 CV 之间有保护距离。
    cfg.v7c.cv_frac=[0.18 0.34;0.65 0.81];
    cfg.v7c.cv_guard_m=0.025;
    cfg.v7c.min_validation_gauges=15;
    cfg.v7c.min_training_gauges=30;
    cfg.v7c.alpha_grid=[0 0.25 0.5 0.75 1];
    % 预先设定：1.5% 且至少1e-5 rad 的 CV RMS 优势才启用非仿射校正。
    cfg.v7c.cv_required_relative_gain=0.015;
    cfg.v7c.cv_required_absolute_rad=1e-5;
    % 无正则 data Hessian 的独立可辨识性条件；不是 rcond(H+lambda I)。
    cfg.v7c.min_data_rcond=3e-5;
    cfg.v7c.max_extra_correction_MHz=0.8;
    cfg.v7c.max_valid_loss_fraction=0.005; % 0.5 pp
end
