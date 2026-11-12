# V1 本地 MATLAB 实验指南

## 第一次运行：建立物理直觉

在 MATLAB 的 Current Folder 选中仓库根目录，执行：

```matlab
addpath('matlab/v1');
[cfg, truth, signals, report] = main_v1();
smoke_test_v1();
```

**无需 Wavelet Toolbox、Signal Processing Toolbox 或额外 NUFFT 库。** V1 代码输出三张图：

1. **TLS 轨迹**：将非线性光频轨迹与理想线性轨迹比较，注意“等间隔时间采样”不意味着“等间隔光频采样”。
2. **辅助 MZI 拍频**：观察拍频值如何随激光瞬时调谐速率变动。理论关系是 `f_aux=delay_aux*dnu_dt`。
3. **主 OFDR 信号及未校准 FFT**：比较非线性导致的反射峰展宽与已知反射位置（竖直虚线）。这不是 NUFFT 的重构结果。

程序将在命令窗口打印扫描带宽、采样率、最大辅助拍频、最大主拍频、Nyquist、理论距离尺度及无混叠距离范围。

## 实验 1：把非线性调为零

在 `config_v1.m` 中设置：

```matlab
cfg.laser.ripple_a = 0;
cfg.laser.drift_b = 0;
cfg.sim.add_noise = false;
```

预期：扫频轨迹是一条直线、相邻光频采样差为常数、辅助 MZI 拍频恒定，未校准 FFT 的反射峰变得尖锐（仍可能有有限窗函数泄漏）。

## 实验 2：增大扫频非线性

将上面两个参数恢复，例如：

```matlab
cfg.laser.ripple_a = 0.20;
cfg.laser.drift_b = 0.05;
```

预期：扫频速率和辅助拍频的波动更加明显，未校准 FFT 的主干涉反射峰进一步展宽。修改参数后必须重新运行 `main_v1`，若最远反射点超过 Nyquist 会直接报错。

## 实验 3：修改光纤反射位置和幅度

所有反射点参数必须具有相同长度。示例：

```matlab
cfg.fut.z_m = [0.45; 0.46; 1.0];
cfg.fut.amplitude = [0.7; 0.5; 0.25];
cfg.fut.phase_rad = [0.2; -0.4; 1.0];
```

预期：反射信号的拍频随距离成比例变化，未校准 FFT 的峰值位置与宽度会随光纤位置不同而变化。

## 实验 4：对比不同 SNR

尝试 `cfg.aux.snr_dB = 15` 和 `cfg.main.snr_dB = 15`，观察时域噪声与空间谱噪声底。再设 `cfg.sim.add_noise=false` 区分“非线性展宽”与“噪声干扰”。

## 自检测试说明

`smoke_test_v1` 包含：

- 无噪声时观测值和真值一致；
- 辅助 MZI 相位差分与解析拍频的一致性；
- 在线性扫频时，每个单独反射点的 FFT 位置与理论距离误差不超过一个距离 bin；
- 固定随机种子后重新生成的带噪声信号完全一致。

> 提示：`smoke_test_v1` 检查的是模型内部数学一致性，并不代表真实仪器的端到端物理标定。

## 故障排查

- **Undefined function 'main_v1'**：当前路径不对，先 `addpath('matlab/v1')`。
- **超过奈奎斯特采样极限**：增加样本数 N（同时增大 fs）、减小反射距离、减小 MZI 时延，或减小光频扫描带宽/速率。
- **打不开或保存不了图片**：确认 MATLAB 有图形环境；或将 `cfg.plot.enabled=false` 后运行数据生成，在可绘图环境中再启用。
- **乱码**：保存文件为 UTF-8，MATLAB 命令窗口与绘图标签主要使用英文，关键解释在中文注释与文档中。
- **程序报维度不一致**：检查 `cfg.fut.z_m`、`cfg.fut.amplitude` 和 `cfg.fut.phase_rad` 是否长度相同。

## 下一版本将做什么？

V2 将从 `signals.aux` 出发实现复 Morlet CWT、瞬时频率估计、SSWT 同步压缩、脊线和积分恢复，并与 `truth.tuning_rate_Hz_s`、`truth.nu_Hz` 直接比较。V1 数据接口特意保存了全部真实答案，以便后续严格计算误差。
