function cfg = config_v2()
%CONFIG_V2 V2 动态光频校准实验参数：以 V1 光学仿真为基础。
% 单位约定：频率 Hz、时间 s、光频 Hz、波长 m；绘图时才换算 kHz/fm。
% V2 仍使用 V1 中相同的辅助 MZI 信号，而不修改物理模型。
    v2_dir = fileparts(mfilename('fullpath'));
    v1_dir = fullfile(fileparts(v2_dir), 'v1');
    if exist('config_v1', 'file') ~= 2
        addpath(v1_dir);
    end
    cfg = config_v1();

    % 分析带 [25,80] kHz 包住了 V1 辅助拍频真实范围约 [43,58] kHz。
    cfg.sswt.f_min_Hz          = 25e3;
    cfg.sswt.f_max_Hz          = 80e3;
    cfg.sswt.voices_per_octave = 24;     % CWT 的对数尺度密度
    cfg.sswt.morlet_omega0     = 6;      % 复 Morlet 母小波无量纲中心角频率
    cfg.sswt.padding_sigmas    = 8;      % 使用对称镜像边界，抑制 FFT 环绕误差
    cfg.sswt.freq_bin_Hz       = 100;    % SSWT 重分配网格宽度（非物理分辨率）
    cfg.sswt.threshold_rel     = 0.025;  % 低幅值系数不参与瞬时频率估计
    cfg.sswt.track_search_Hz   = 1800;   % 相邻时间点脊线搜索频带
    cfg.sswt.refine_band_Hz    = 500;    % 用同一脊线附近的 CWT 相位导数细化频率
    cfg.sswt.smooth_points     = 9;      % 轻微平滑脊线，1 表示关闭
    % CWT 解析小波的边界相位会受镜像延拓影响，默认用内侧拍频二次外推。
    % 对真正的突然启动/停止扫频，应设为 false，并单独分析边界效应。
    cfg.sswt.edge_extrapolate  = true;
    cfg.sswt.edge_sigma        = 6;
    cfg.sswt.edge_fit_s        = 0.75e-3;

    % 基础 MATLAB 实现的 STFT 基线：不调用 spectrogram()。
    cfg.stft.window_length     = 512;
    cfg.stft.hop_length        = 32;
    cfg.stft.nfft              = 2048;

    % V2 绘图输出与 V1 分开，默认仅显示在 MATLAB 窗口中。
    cfg.plot.enabled          = true;
    cfg.plot.save_png         = false;
    cfg.plot.v2_output_dir    = fullfile(v2_dir, 'output');
end
