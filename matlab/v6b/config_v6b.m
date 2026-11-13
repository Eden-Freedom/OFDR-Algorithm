function cfg = config_v6b()
%CONFIG_V6B 零应变双扫描误差机理与重复试验配置。
% 默认是快速预览。论文级统计请将 repeats>=30，SSWT repeats>=30，
% 独立散射种子至少 5 组；报告失败率和全部配对随机种子。
    here=fileparts(mfilename('fullpath'));
    addpath(fullfile(fileparts(here),'v6'));
    cfg=config_v6();
    cfg.v6.make_plots=false;cfg.v6.save_results=false;
    cfg.v6b.output_dir=fullfile(here,'output');
    cfg.v6b.save_results=true;
    cfg.v6b.make_plots=true;
    cfg.v6b.repeats=8;             % 快速验证，不代表论文统计
    cfg.v6b.sswt_repeats=4;        % 两次真实 SSWT 的配对试验
    cfg.v6b.rho_values=[0 0.5 0.9 1];
    cfg.v6b.scatter_seed_stride=101;
    cfg.v6b.inject_seed_stride=103;
    cfg.v6b.aux_seed_stride=107;
    cfg.v6b.bootstrap_reps=600;     % 配对 trial 上的重采样，非像素级重采样
    cfg.v6b.bootstrap_seed=2991;
    cfg.v6b.gauge_mm=[5 10 20 40];
    cfg.v6b.distance_bands_m=[0.50 0.80; 0.80 1.10; 1.10 1.40; ...
                              1.40 1.70; 1.70 2.00; 2.00 2.30];
    cfg.v6b.verbose=true;
end
