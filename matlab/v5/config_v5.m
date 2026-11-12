function cfg = config_v5()
%CONFIG_V5 光频校准误差传递研究配置，继承 V1-V4，不修改历史模块。
% 所有物理量使用 SI 单位。P0/P1 为默认入口，完整矩阵按需调用。
    here=fileparts(mfilename('fullpath'));
    addpath(fullfile(fileparts(here),'v4'));
    cfg=config_v4();
    cfg.plot.enabled=false;
    cfg.v4.plot_enabled=false;
    cfg.v5.output_dir=fullfile(here,'output');
    cfg.v5.save_results=true;  % .mat 包含真值、输入信号、完整轨迹和图数据
    cfg.v5.make_plots=true;
    cfg.v5.single_z_m=1.25;
    cfg.v5.phase_rad=1.2;
    cfg.v5.fine_halfwidth_m=4e-3;
    cfg.v5.fine_step_m=0.02e-3;
    cfg.v5.convergence_step_m=0.01e-3;
    cfg.v5.direct_block_size=128; % 避免 N×K 直接矩阵过大
    cfg.v5.scale_distance_m=[.25 .5 1 1.5 2 2.4 2.7];
    cfg.v5.scale_ppm=[-100 -30 -10 -3 -1 0 1 3 10 30 100];
    cfg.v5.sswt_gamma=[0 .25 .5 1 2 4 8];
    cfg.v5.error_rmse_MHz=[0 .1 .3 1 1.71 3 10];
    cfg.v5.error_types={'quadratic','periodic_1','periodic_2', ...
        'periodic_5','periodic_10','correlated_short','correlated_long', ...
        'boundary_start','boundary_end'};
    cfg.v5.random_seed=2026;
    cfg.v5.diagnostic_weight_mode='fixed';
    cfg.v5.full_weight_mode='full';
    cfg.v5.do_error_families=false; % 全误差族运行成本较高，独立命令运行
    cfg.v5.do_snr=false;            % 30次×7档，单独运行
    cfg.v5.do_doublet=false;
    cfg.v5.snr_dB=[5 10 15 20 25 30 40];
    cfg.v5.snr_repeats=30;
    cfg.v5.smooth_points=[9 41 81];
    cfg.v5.delay_error_ppm=[-100 -30 0 30 100];
    cfg.v5.beat_bias_Hz=[-1 0 1];
    cfg.v5.doub_gap_mm=[.5 1 1.5 2 3 6];
    cfg.v5.doub_amp_ratio=[1 .3];
    cfg.v5.doub_phase_rad=[0 pi/2 pi];
    cfg.v5.doublet_valley_dB=3; % 本实验自定义阈值，非通用分辨率判据
    cfg.v5.position_limit_m=.1e-3;
    cfg.v5.fwhm_growth_limit=.05;
    cfg.v5.phase_limit_rad=.1;
end
