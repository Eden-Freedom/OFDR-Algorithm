function cfg = config_v4()
%CONFIG_V4 V4 联合仿真参数（兼容 V1/V2/V3 的原有独立模块）。
% V2 用 SSWT 估计瞬时拍频及光频轨迹；V3 的 Type-1 NUFFT 以该轨迹做横坐标。
% 这里不修改 V1/V2/V3 源码，保证历史版本可独立复现。
    here = fileparts(mfilename('fullpath'));
    v1 = fullfile(fileparts(here),'v1');
    v2 = fullfile(fileparts(here),'v2');
    v3 = fullfile(fileparts(here),'v3');
    addpath(v1,v2,v3);

    cfg = config_v2();
    v3cfg = config_v3();
    cfg.v3 = v3cfg.v3;
    cfg.v3.show_benchmark = false;    % V4 不重复跑 V3 的复杂度基准
    cfg.v3.plot_enabled = false;

    cfg.plot.enabled = false;         % V2 的独立作图在 V4 关闭
    cfg.v4.plot_enabled = true;
    cfg.v4.save_png = false;
    cfg.v4.output_dir = fullfile(here,'output');
    % 独立已知的 TLS 标称扫描带宽作为空间刻度，不在这里用 truth.u 修正估计轨迹。
    % 若估计坐标超出 [0,1)，显式报错；不得静默裁剪/借用真值归一化。
    cfg.v4.normalization = 'nominal';
    cfg.v4.include_stft_cwt = false;  % 增加 STFT/CWT→NUFFT 的算法消融实验
    cfg.v4.show_isolated_reflector = true;
    cfg.v4.isolated_reflector_index = 3; % 第三反射点位于 1.25 m
    cfg.v4.zoom_range_m = [0.430,0.475];
    % 可选鲁棒性参数扫描的默认配置；单次 main_v4() 不会自动执行批量实验。
    cfg.v4.snr_values_dB = [15 20 25 30];
    cfg.v4.snr_repeats = 3;
end
