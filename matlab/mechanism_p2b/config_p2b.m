function cfg=config_p2b()
%CONFIG_P2B P2b 共模光频坐标方向灵敏度预测：新开发种子，不触及冻结试次。
% 四个应变水平、中心差分h=0.05(主预设)与0.10(步长诊断)，
% 未用于求导的alpha=0.5与1.0用于外推检验。
    here=fileparts(mfilename('fullpath'));
    addpath(fullfile(fileparts(here),'mechanism_p1p2'));
    cfg=config_p1p2();
    cfg.p1p2.run_p1_direct=false;
    cfg.p1p2.run_p1_density=false;
    cfg.p1p2.run_p2=false;
    cfg.p1p2.make_plots=false;
    cfg.p1p2.save_results=false;
    cfg.p2b.protocol_id='P2B_COMMON_SENSITIVITY_DEV_2026-11-14_A';
    cfg.p2b.phase='development';
    cfg.p2b.frozen_enabled=false;
    cfg.p2b.development_repeats=12;
    cfg.p2b.strain_microeps=[0 1 5 10];
    cfg.p2b.alpha_grid=[-0.10 -0.05 0 0.05 0.10 0.50 1.00];
    cfg.p2b.primary_h=0.05;
    cfg.p2b.secondary_h=0.10;
    cfg.p2b.test_alpha=[0.5 1.0];
    cfg.p2b.scatter_seed_base=411001001;
    cfg.p2b.aux_ref_seed_base=421001001;
    cfg.p2b.aux_meas_seed_base=431001001;
    cfg.p2b.scatter_stride=181;
    cfg.p2b.aux_stride=197;
    cfg.p2b.min_common_core=15;
    cfg.p2b.min_common_static=15;
    cfg.p2b.min_common_roi_fraction=.20;
    cfg.p2b.bootstrap_reps=2000;
    cfg.p2b.bootstrap_seed=20261115;
    cfg.p2b.output_dir=fullfile(here,'output');
    cfg.p2b.make_plots=true;
    cfg.p2b.save_results=true;
    cfg.p2b.verbose=true;
end