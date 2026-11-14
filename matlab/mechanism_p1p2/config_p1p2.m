function cfg=config_p1p2()
%CONFIG_P1P2 新实验机制研究配置：与V6c共享物理核，不修改旧版本。
% 本实验使用新的开发随机种子；冻结评估被程序层面禁止。
    here=fileparts(mfilename('fullpath'));
    addpath(fullfile(fileparts(here),'..','v6c'));
    cfg=config_v6c();
    cfg.v6c.make_plots=false;
    cfg.v6c.save_results=false;
    cfg.v6c.run_mc=false;
    cfg.v6.make_plots=false;
    cfg.v6.save_results=false;
    cfg.p1p2.protocol='P1P2_MECHANISM_DEV_2026-11-14_A';
    cfg.p1p2.output_dir=fullfile(here,'output');
    cfg.p1p2.phase='development';
    cfg.p1p2.frozen_enabled=false;
    cfg.p1p2.repeats=8;              % 机制探索，不称论文级样本量
    cfg.p1p2.strain_microeps=[0 1 5 10];
    cfg.p1p2.scatter_seed_base=311001001;
    cfg.p1p2.aux_ref_seed_base=321001001;
    cfg.p1p2.aux_meas_seed_base=331001001;
    cfg.p1p2.scatter_stride=173;
    cfg.p1p2.aux_stride=191;
    cfg.p1p2.min_common_roi_fraction=.20;
    cfg.p1p2.min_common_core=15;
    cfg.p1p2.min_common_static=15;
    cfg.p1p2.bootstrap_reps=2000;
    cfg.p1p2.bootstrap_seed=20261114;
    cfg.p1p2.p1_sample_bins=80;
    cfg.p1p2.p1_scat_repeats=4;
    cfg.p1p2.p1_scat_levels=[0 1 2];  % 1.5/0.75/0.375mm嵌套网格
    cfg.p1p2.p1_strain_microeps=5;
    cfg.p1p2.run_p1_direct=true;
    cfg.p1p2.run_p1_density=false;    % 首次验证：P1密度实验独立调用，免覆盖数据
    cfg.p1p2.run_p2=true;
    cfg.p1p2.make_plots=true;
    cfg.p1p2.save_results=true;
    cfg.p1p2.verbose=true;
end