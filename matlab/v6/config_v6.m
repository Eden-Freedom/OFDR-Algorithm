function cfg = config_v6()
%CONFIG_V6 V6a 零应变双扫描：共模/差模校准残差对 gauge 相位的传递。
% 本轮两次扫描严格使用同一真实 TLS 扫频、同一静止光纤和同一主信号。
% 不引入主探测噪声或实际施加应变，隔离光频校准坐标误差的效应。
    here=fileparts(mfilename('fullpath'));
    for j=1:5
        addpath(fullfile(fileparts(here),sprintf('v%d',j)));
    end
    cfg=config_v5();
    cfg.plot.enabled=false;
    cfg.v4.plot_enabled=false;
    cfg.v5.make_plots=false;
    cfg.v5.save_results=false;
    cfg.v3.show_benchmark=false;
    cfg.v6.output_dir=fullfile(here,'output');
    cfg.v6.save_results=true;
    cfg.v6.make_plots=true;
    cfg.v6.scatter_z_min_m=0.35;
    cfg.v6.scatter_z_max_m=2.55;
    cfg.v6.scatter_step_m=0.0015;
    cfg.v6.scatter_block_size=64;
    cfg.v6.scatter_seed=2601;
    cfg.v6.aux_seed_ref=2602;
    cfg.v6.aux_seed_meas=2603;
    cfg.v6.aux_snr_dB=25;
    cfg.v6.inject_seed_ref=2604;
    cfg.v6.inject_seed_independent=2605;
    cfg.v6.error_corr_window_ms=0.5;
    cfg.v6.inject_rms_MHz=1.71;
    cfg.v6.rho_values=[1,0.9,0.5,0];
    cfg.v6.gauge_length_m=0.010;
    cfg.v6.roi_m=[0.50 2.30];
    cfg.v6.amplitude_gate_fraction=0.25; % 相对 oracle 空间迹线的中位幅值
    cfg.v6.lambda_ref_m=1550e-9;
    cfg.v6.phase_index=1.468;           % 近似有效相折射率，与 n_g 分开记录
    cfg.v6.photoelastic_p=0.22;         % 用于等效微应变换算的简化参数
    cfg.v6.minimum_valid_fraction=0.15;
end
