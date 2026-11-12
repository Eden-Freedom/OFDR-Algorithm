function cfg = config_v1()
%CONFIG_V1 V1 OFDR 仿真的参数配置（统一使用 SI 单位）。
%   改动采样率、扫频带宽或反射距离后，请运行 validate_v1 检查拍频混叠。
%   此文件不依赖任何额外 MATLAB 工具箱。

    cfg.const.c_m_s = 299792458;  % 真空光速，m/s

    % 1550 nm -> 1549 nm 对应光频逐渐增大（并非波长逐渐增大）。
    cfg.laser.lambda_start_m = 1550e-9;
    cfg.laser.lambda_end_m   = 1549e-9;
    cfg.laser.duration_s     = 20e-3;
    cfg.laser.ripple_a       = 0.12;  % 周期性扫频速率变化
    cfg.laser.drift_b        = 0.04;  % 缓慢变化的扫频速率漂移
    cfg.laser.ripple_cycles  = 2;     % 扫频过程中的扰动周期数

    cfg.acq.N     = 8192;  % 单次扫描中等时间间隔采样的点数
    cfg.acq.fs_Hz = cfg.acq.N / cfg.laser.duration_s;

    % 这里的 delay_s 是“有效总时延”，已包含采用的光路单/双程因素。
    cfg.aux.delay_s     = 8e-9;
    cfg.aux.amplitude   = 1.0;
    cfg.aux.phase_rad   = 0.35;
    cfg.aux.snr_dB      = 25;

    cfg.fut.group_index = 1.468;
    cfg.fut.z_m         = [0.450; 0.456; 1.250; 2.400];
    cfg.fut.amplitude   = [0.65; 0.45; 0.30; 0.16];
    cfg.fut.phase_rad   = [0.20; -0.45; 1.20; 0.70];
    cfg.main.snr_dB     = 30;

    cfg.sim.add_noise   = true;
    cfg.sim.random_seed = 2026;

    cfg.plot.enabled    = true;
    cfg.plot.save_png   = false;
    cfg.plot.output_dir = fullfile(fileparts(mfilename('fullpath')), 'output');
end
