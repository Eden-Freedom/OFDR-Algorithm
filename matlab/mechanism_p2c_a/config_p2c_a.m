function cfg=config_p2c_a()
%CONFIG_P2C_A 辅助MZI理想解缠相位的可观测性数学演示。
% 此处频率为相对频率/扫频轨迹，不是192THz绝对光频。
% 本实验只构造线性积分算子，完全不依赖V6/V7或冻结试次。
    here=fileparts(mfilename('fullpath'));
    cfg=struct();
    cfg.p2ca.name='P2CA_AUX_MZI_IDENTIFIABILITY_2026_11_14';
    cfg.p2ca.dataset='math_only';
    cfg.p2ca.frozen_enabled=false;
    cfg.p2ca.n_frequency_bins=64;
    cfg.p2ca.dt_s=1e-6;
    cfg.p2ca.delay_1_bins=4;
    cfg.p2ca.delay_2_bins=5;
    cfg.p2ca.offset_phase_rad=0.34;
    cfg.p2ca.output_dir=fullfile(here,'output');
    cfg.p2ca.make_plots=true;
    cfg.p2ca.save_results=true;
end