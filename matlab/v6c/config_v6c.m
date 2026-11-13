function cfg = config_v6c()
%CONFIG_V6C V6c: 非零应变 Rayleigh 双扫描前向/反演实验（基础 MATLAB）。
% 继承 V1-V6b 计算核，不修改旧版本。单次 1-20 ue 保持 gauge 相位不过 pi。
    here=fileparts(mfilename('fullpath'));
    addpath(fullfile(fileparts(here),'v6b'));
    cfg=config_v6b();
    cfg.v6b.save_results=false;cfg.v6b.make_plots=false;
    cfg.v6.save_results=false;cfg.v6.make_plots=false;
    cfg.v6c.output_dir=fullfile(here,'output');
    cfg.v6c.save_results=true;
    cfg.v6c.make_plots=true;
    cfg.v6c.strain_microeps=5;
    cfg.v6c.strain_sweep_microeps=[0 1 2 5 10 20];
    cfg.v6c.strain_start_m=1.08;  % 应变区边界（不等于散射体位移）
    cfg.v6c.strain_end_m=1.62;
    cfg.v6c.transition_m=0.025;  % 两侧余弦缓变区，防止不真实的应变跳变
    cfg.v6c.integration_step_m=0.0001;
    cfg.v6c.group_photoelastic_factor=0.78; % group OPL 扫频项的教学近似
    cfg.v6c.forward_block_size=64;
    cfg.v6c.gauge_wrap_guard_rad=0.80*pi; % 真值相位超此范围时不得用 wrapped gauge 测量
    cfg.v6c.core_margin_m=0.008;
    cfg.v6c.phase_avg_bins=9; % 复 gauge phasor 9 bin 邻域平均；显式扩展空间响应，必须与未平滑指标并报
    cfg.v6c.static_margin_m=0.05;
    cfg.v6c.minimum_core_valid_fraction=0.25;
    cfg.v6c.run_mc=false;
    cfg.v6c.mc_repeats=8;   % 初跑；论文级研究应 >=30 且多散射随机种子
    cfg.v6c.mc_scatter_seed_stride=109;
    cfg.v6c.mc_aux_seed_stride=127;
end
