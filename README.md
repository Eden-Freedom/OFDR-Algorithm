# OFDR Algorithm Learning Lab

用于学习 **OFDR（Optical Frequency Domain Reflectometry，光频域反射仪）** 信号生成、SSWT 扫频校准以及 NUFFT 非均匀采样重构的 MATLAB 仿真项目。

> 正确缩写为 **OFDR**。仓库已统一为 `OFDR-Algorithm`。

## 开发进度

| 版本 | 内容 | 状态 |
|---|---|---|
| V1 | TLS 非线性扫频、辅助 MZI 和主 OFDR 离散反射信号生成 | 已由使用者本地运行并确认三幅图正常 |
| V2 | 自行实现 CWT、SSWT、脊线提取和光频恢复 | 源码已提交；使用者已在 MATLAB 本地生成三组图，量化指标仍可继续评估 |
| V3 | 直接 NUDFT 与 Gaussian Gridding NUFFT | 源码已完成；等待本地 MATLAB 运行验证 |
| V4 | SSWT + NUFFT 联合性能对照 | 规划中 |

完整设计方案见 [docs/SIMULATION_PLAN.md](docs/SIMULATION_PLAN.md)；V1 请读 [V1 实验指南](docs/V1_EXPERIMENT_GUIDE.md)，V2 请读 [V2 实验指南](docs/V2_EXPERIMENT_GUIDE.md)，V3 请读 [V3 实验指南](docs/V3_EXPERIMENT_GUIDE.md)。

## V3 运行方法：已知真实光频坐标下的 NUFFT 重构

**V3 只独立验证 NUFFT，不使用 V2 的 SSWT 估计结果。** 这是为了把算法数值近似误差与光频校准误差分开。采用自实现 Gaussian Gridding Type-1 NUFFT，配套直接 NUDFT 数值参考、普通 FFT 和插值 FFT 基线。

```matlab
addpath('matlab/v3');
smoke_test_v3;
[cfg,truth,signals,results,metrics] = main_v3();
```

V3 生成图 7（高斯核网格化）、图 8（OFDR 全谱和 0.450/0.456 m 双峰）、图 9（NUFFT 与抽样的直接 NUDFT 数值误差），默认另外生成图 10（小规模性能基准）。自检包含无噪声均匀/非均匀坐标、FFT/NUDFT 一致性和物理峰位。

主要参数都在 `matlab/v3/config_v3.m` 中：

```matlab
cfg=config_v3();
cfg.v3.alpha=2;
cfg.v3.kernel_width=12;
cfg.v3.density_mode='voronoi';  % 或 'none'
cfg.v3.window='hann';          % 或 'none'
cfg.v3.show_benchmark=false;   % 可跳过小规模耗时评估
main_v3(cfg);
```

**重要：** V3 NUFFT 的密度补偿属于可选的光频积分近似，对照 NUDFT 的采样权重必须完全一致。V3 的数值误差不等同于理论空间分辨率；将 SSWT 光频轨迹接到 NUFFT 是 V4。

更多解释见 [V3_EXPERIMENT_GUIDE.md](docs/V3_EXPERIMENT_GUIDE.md)。V3 代码已进行独立数值公式核验，但未在本环境中直接执行 MATLAB，需用户本地运行并反馈。

## V2 运行方法：SSWT 扫频轨迹校准

V2 沿用 V1 的辅助 MZI 信号，并且新增**从原理编写的复 Morlet CWT、SSWT 重分配、脊线精细化、光频与波长恢复**。提供自行编写的 STFT 和 CWT 作为对照；V2 **尚不包括 NUFFT**。

在仓库根目录运行（不需要 `cwt` / `wsst` / `spectrogram` 工具箱函数）：

```matlab
addpath('matlab/v2');
smoke_test_v2;  % 优先运行：无噪声纯音与 V1 模型回归测试
[cfg,truth,signals,results,metrics] = main_v2();
```

V2 生成图 4（STFT / CWT / SSWT 时频图）、图 5（拍频残差）、图 6（光频和波长恢复误差），打印各方法的拍频 RMSE、光频 RMSE、波长 RMSE (fm) 和耗时。第一版频率范围为 25–80 kHz、24 scales/octave、SSWT 频率网格 100 Hz。若研究更密的尺度，可执行：

```matlab
cfg=config_v2();
cfg.sswt.voices_per_octave=36;
cfg.aux.snr_dB=15;
main_v2(cfg);
```

细节、参数扫描和限制见 [V2_EXPERIMENT_GUIDE.md](docs/V2_EXPERIMENT_GUIDE.md)。拍频 RMSE 忽略前后各 5% 采样点以减小变换边界影响；波长 RMSE 是全扫频计算，以保留积分累积误差。**波长 fm 误差不等于 OFDR 空间分辨率。**

**运行状态说明**：V2 算法已进行独立数值公式交叉检查，但不能代替真实 MATLAB 运行验证。请在本地先执行 `smoke_test_v2`，发现版本兼容问题可直接反馈报错行。

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
