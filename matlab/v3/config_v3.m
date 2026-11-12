function cfg = config_v3()
%CONFIG_V3 V3 教学实验：已知 TLS 真实扫频坐标 -> NUFFT 空间谱。
% 使用 V1 生成同一组辅助/主干涉信号；V3 不使用 SSWT 的估计轨迹。
% 单位：Hz、m、s。无需 Wavelet/Signal Processing Toolbox。
    here = fileparts(mfilename('fullpath'));
    v1 = fullfile(fileparts(here),'v1');
    if exist('config_v1','file') ~= 2, addpath(v1); end
    cfg = config_v1();

    cfg.v3.alpha = 2;                   % NUFFT 均匀网格过采样倍数 K/N > 1
    cfg.v3.kernel_width = 8;            % Gaussian gridding 核支持的网格点数
    cfg.v3.density_mode = 'voronoi';    % 'voronoi' 或 'none'，均与 NUDFT 一致
    cfg.v3.window = 'hann';             % 光频域加窗：'hann' 或 'none'
    cfg.v3.nudft_probe_stride = 64;     % 直接 NUDFT 稀疏验证的基线步长
    cfg.v3.nudft_peak_halfbins = 24;    % 对每个真反射点附近增加密集验证点
    cfg.v3.show_benchmark = true;       % N <= 2048 的独立运行耗时实验
    cfg.v3.benchmark_sizes = [256,512,1024,2048];
    cfg.v3.benchmark_repeats = 2;
    cfg.v3.plot_enabled = true;
    cfg.v3.save_png = false;
    cfg.v3.output_dir = fullfile(here,'output');
end
