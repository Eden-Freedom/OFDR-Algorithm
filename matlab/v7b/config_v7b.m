function cfg=config_v7b()
%CONFIG_V7B V7b SAPC 盲测、失效机理与物理条件泛化的预注册配置。
% 不根据盲测结果修改 V7 已经固定的基函数、迭代次数或正则化。
    here=fileparts(mfilename('fullpath'));
    addpath(fullfile(fileparts(here),'v7'));
    cfg=config_v7();
    cfg.v7.save_results=false;cfg.v7.make_plots=false;
    cfg.v7b.output_dir=fullfile(here,'output');
    cfg.v7b.save_results=true;cfg.v7b.make_plots=true;
    cfg.v7b.blind_repeats=100;  % 和历史 36 次不重合的独立试次
    cfg.v7b.run_blind=true;
    cfg.v7b.run_conditions=false; % 物理泛化矩阵需独立显式开启
    cfg.v7b.condition_repeats=12; % 预览级别；论文研究应在每个条件 >=30
    cfg.v7b.bootstrap_reps=2000;
    cfg.v7b.bootstrap_seed=271113;
    cfg.v7b.scatter_seed_base=10010001;
    cfg.v7b.aux_ref_seed_base=20010001;
    cfg.v7b.aux_meas_seed_base=30010001;
    cfg.v7b.scatter_stride=149;
    cfg.v7b.aux_stride=163;
    cfg.v7b.seed_group_stride=100000;
    cfg.v7b.analysis_id='V7B_FROZEN_2026-11-13_A';
    cfg.v7b.max_relative_valid_loss=0.005; % 0.5 percentage point
    cfg.v7b.verbose=false;
    cfg.v7b.conditions_snr_dB=[15 25 35];
    cfg.v7b.conditions_train_ranges_m=[0.55 0.98;0.62 0.85;0.78 1.02];
    cfg.v7b.conditions_strain_microeps=[0 1 5 10 20];
    cfg.v7b.conditions_gauge_mm=[5 10 20];
    cfg.v7b.conditions_ripple_a=[0.06 0.12 0.20];
end
