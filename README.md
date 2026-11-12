# OFDR Algorithm Learning Lab

用于学习 **OFDR（Optical Frequency Domain Reflectometry，光频域反射仪）** 信号生成、SSWT 扫频校准以及 NUFFT 非均匀采样重构的 MATLAB 仿真项目。

> 仓库名称沿用 `OFRD-Algorithm`；光频域反射仪的正确缩写是 **OFDR**。

## 开发进度

| 版本 | 内容 | 状态 |
|---|---|---|
| V1 | TLS 非线性扫频、辅助 MZI 和主 OFDR 离散反射信号生成 | 源码已准备，等待 MATLAB 本地执行验收 |
| V2 | 自行实现 CWT、SSWT、脊线提取和光频恢复 | 规划中 |
| V3 | 直接 NUDFT 与 Gaussian Gridding NUFFT | 规划中 |
| V4 | SSWT + NUFFT 联合性能对照 | 规划中 |

完整设计方案见 [docs/SIMULATION_PLAN.md](docs/SIMULATION_PLAN.md)；首次运行建议参照 [docs/V1_EXPERIMENT_GUIDE.md](docs/V1_EXPERIMENT_GUIDE.md)。

## V1 运行方法

建议使用 **MATLAB R2020b 或更新版本**。V1 仅使用基础 MATLAB 函数，不需要额外工具箱。

在 MATLAB 中，将当前文件夹设置为仓库根目录，然后执行：

```matlab
addpath('matlab/v1');
main_v1;          % 生成真实信号、打印检查结果并绘图
smoke_test_v1;    % 无噪声数学自检
```

也可以进入 `matlab/v1/` 文件夹后直接输入 `main_v1`。

### 图像输出

- 图 1：TLS 光频偏移、波长、扫频速率及相邻样本光频间隔。
- 图 2：辅助 MZI 拍频信号、真实瞬时拍频轨迹。
- 图 3：主 OFDR 干涉信号，以及**未校准普通 FFT** 的空间反射谱。

要保存 PNG 图片，在 `matlab/v1/config_v1.m` 中设定 `cfg.plot.save_png = true;`，默认输出至 `matlab/v1/output/`（该目录已被 `.gitignore` 排除）。

### 参数修改

编辑 `config_v1.m`：

- `cfg.laser.ripple_a`、`cfg.laser.drift_b`：扫频非线性。
- `cfg.aux.delay_s`：辅助 MZI 的有效总时延。
- `cfg.fut.z_m`：光纤中的反射点位置（m）。
- `cfg.fut.amplitude`、`cfg.fut.phase_rad`：反射干涉幅度和相位。
- `cfg.aux.snr_dB`、`cfg.main.snr_dB`：噪声设置。
- `cfg.sim.add_noise`：开启/关闭噪声。

修改参数后，`validate_v1` 会检查扫频轨迹单调性和各个拍频是否满足奈奎斯特采样条件。如果报错，应减小最远反射距离、减小扫频速率或增加采样率，而不是忽略报错。

## V1 模型边界

使用冻结频率/短延迟近似：`cos(2*pi*tau*(nu(t)-nu_start) + phi)`。它足以教学展示扫频非线性造成的拍频变化和 FFT 反射峰展宽，但暂不包含瑞利散射、偏振、激光相位噪声、检测器带宽和精确延迟光场相位。V1 的普通 FFT **不是** SSWT 或 NUFFT 校正结果。

该项目是教学与科研原型，不能将仿真结果直接视为对论文实验指标的复现。

## 参考文献

1. H. Dang et al., *Dynamic wavelength calibration based on synchrosqueezed wavelet transform*, Optics Express 30 (2022). https://doi.org/10.1364/OE.477771
2. Z. Ding et al., *Note: Improving spatial resolution of optical frequency-domain reflectometry against frequency tuning nonlinearity using non-uniform fast Fourier transform*, Review of Scientific Instruments 83 (2012). https://doi.org/10.1063/1.4729376
