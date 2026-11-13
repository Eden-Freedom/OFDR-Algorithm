# OFDR Algorithm Learning Lab

用于学习 **OFDR（Optical Frequency Domain Reflectometry，光频域反射仪）** 信号生成、SSWT 扫频校准以及 NUFFT 非均匀采样重构的 MATLAB 仿真项目。

> 正确缩写为 **OFDR**。仓库已统一为 `OFDR-Algorithm`。

## 最新研究代码 V6d + V7（尚待 MATLAB 本地运行验证）

- **V6d**：真实非零应变下、36 次配对试验的真值诊断消融（共模、线性坡度、非仿射、完整差异）；真值**只用于分解诊断和评价，不能用于部署校正**。[操作指南](docs/V6D_EXPERIMENT_GUIDE.md) · [逐图阅读](docs/V6D_FIGURE_READING_GUIDE.md)。
- **V7 原型 SAPC**：只在预先确定的上游静止参考段拟合校准坐标的低维非仿射修正；受应变 core 与下游静止段都是不参与拟合的测试区域。包含简单平滑与静态 affine 基线。[操作指南](docs/V7_EXPERIMENT_GUIDE.md) · [逐图阅读](docs/V7_FIGURE_READING_GUIDE.md)。

```matlab
addpath('matlab/v6d'); smoke_test_v6d; [cfg6d,res6d]=main_v6d();
addpath('matlab/v7');  smoke_test_v7;  [cfg7,res7]=main_v7();
```

**研究边界：** 这些源码还没有经过用户本地 MATLAB 运行验证；V7 不是已经取得性能提升的算法，不自动构成论文新颖性。当前的两次**真实扫频轨迹相同**、主探测噪声关闭，必须在严格无真值拟合的约束下检验跨种子、不同扫频和持出静态段效果。

## 最新版本 V6c：真实非零应变的前向与解调验证（源码待 MATLAB 验收）

**新研究关口**：通过真实输入的 0/1/2/5/10/20 με 轴向应变场，使同一 Rayleigh 散射体在参考/测量扫描中拥有不同的载波往返相位与群时延；对比真值光频、共模 SSWT 和独立 SSWT 下的应变 RMSE，而不再只输出零应变下的等效应变代理。

- [V6c MATLAB 实验操作与物理模型](docs/V6C_EXPERIMENT_GUIDE.md)
- [V6c 逐图分析指南](docs/V6C_FIGURE_READING_GUIDE.md)

```matlab
addpath('matlab/v6c');
smoke_test_v6c;          % 必须先通过真实 0/5 με 验收
[cfg,results]=main_v6c();
```

**重要：** V6c 除了 raw gauge 相位还可启用 9 bin 复 phasor 平均，显式增加空间支持尺度；报告精度时必须一并报告该尺度、门控有效率及 oracle 参考误差，不能把平滑后的精度当作同样空间分辨率下的算法改进。

## V6a 零应变双扫描及相位传递验证

在保留 V1–V5 原算法的基础上，V6a 使用**同一真实光频轨迹、同一静止瑞利散射体实现和完全相同的主干涉信号**，比较 oracle/oracle、严格共模 SSWT、独立辅助噪声 SSWT 和相同单扫 RMSE/不同扫描间相关性的控制残差。

- [V6a 代码与运行指南](docs/V6_EXPERIMENT_GUIDE.md)
- [V6a 逐图阅读及指标说明](docs/V6_FIGURE_READING_GUIDE.md)
- [面向相位应变的论文研究路线](docs/PHASE_STRAIN_RESEARCH_ROADMAP.md)

```matlab
addpath('matlab/v6');
smoke_test_v6;
[cfg,results]=main_v6();
```

**研究边界：** V6a 的“零应变等效虚假应变”来自一个尚未经过非零应变正演验证的相位灵敏度换算；它用于验证校准误差→双扫描 gauge 相位的传递，不等于已经验证的真实应变测量精度。V6c 开始开展实际施加已知非零应变的物理模型校验。


## V6b：双扫描残差机理和统计验证

V6a 的零应变共模与独立 SSWT 实验已由使用者在 MATLAB 中运行。V6b 接续实现**多随机种子配对 ρ 实验、共同有效 gauge 掩码、bootstrap 置信区间、SSWT 残差分量消融、距离×gauge 矩阵和独立 SSWT 重复**。

```matlab
addpath('matlab/v6b');
smoke_test_v6b;
[cfg,results]=main_v6b();
```

[实验指南](docs/V6B_EXPERIMENT_GUIDE.md) · [逐图阅读与论文假设](docs/V6B_FIGURE_READING_GUIDE.md)。默认少量重复仅供运行确认，不能视为论文级统计。指标仍是**零应变等效代理**，不是已校准的非零应变测量精度。

## 开发进度

| 版本 | 内容 | 状态 |
|---|---|---|
| V1 | TLS 非线性扫频、辅助 MZI 和主 OFDR 离散反射信号生成 | 已由使用者本地运行并确认三幅图正常 |
| V2 | 自行实现 CWT、SSWT、脊线提取和光频恢复 | 源码已提交；使用者已在 MATLAB 本地生成三组图，量化指标仍可继续评估 |
| V3 | 直接 NUDFT 与 Gaussian Gridding NUFFT | 用户 MATLAB 运行已验证（相对 NUDFT 误差约 1.03e-5） |
| V4 | SSWT + NUFFT 联合性能对照 | 用户已在 MATLAB 本地运行验证（幅度谱相对误差约 0.92%） |
| V5 | 光频校准误差传递、细网格峰宽与误差注入 | 用户已在 MATLAB 中运行并给出 P0/P1 输出 |
| V6a | 零应变双扫描、瑞利散射相位、共模/差模误差、gauge 等效应变 | 已由使用者本地运行 |
| V6b | 36 次重复：扫描间误差相关性、消融与统计 | 已由使用者本地运行并提供结果 |
| V6c | 非零已知应变 Rayleigh 前向、真实应变恢复与 RMSE | 已由使用者 MATLAB 运行（36次） |
| V6d | 36次非零应变下的真值诊断配对消融 | 源码待 MATLAB 本地运行 |
| V7 | 静态锚段相位一致性校正原型（SAPC） | 源码待 MATLAB 本地运行及新颖性查验 |

V5 的原始实验方案：[V5_CALIBRATION_ERROR_PROPAGATION_PLAN.md](docs/V5_CALIBRATION_ERROR_PROPAGATION_PLAN.md)；V5 实现和步骤：[V5_EXPERIMENT_GUIDE.md](docs/V5_EXPERIMENT_GUIDE.md)。

## V5 运行方法：光频校准误差传递（最新阶段）

此阶段严格先做 P0/P1，已新增实验 A–E 各类入口、失败记录和 MATLAB 数据保存。核心数据采用**无噪声单反射点**与真实扫描光频生成；只修改重构坐标，避免以错误坐标重新生成主信号而抵消误差。

```matlab
addpath('matlab/v5');
smoke_test_v5;
[cfg,ctx,results] = main_v5();
```

高级实验见 V5 指南；30 次×多SNR 和双峰矩阵不会在默认入口自动运行。输出默认保存在 `matlab/v5/output/`，不提交 Git。**V5 尚未在 MATLAB 实机验证。**

完整设计方案见 [docs/SIMULATION_PLAN.md](docs/SIMULATION_PLAN.md)；V1 请读 [V1 实验指南](docs/V1_EXPERIMENT_GUIDE.md)，V2 请读 [V2 实验指南](docs/V2_EXPERIMENT_GUIDE.md)，V3 请读 [V3 实验指南](docs/V3_EXPERIMENT_GUIDE.md)，V4 请读 [V4 实验指南](docs/V4_EXPERIMENT_GUIDE.md)。

## V4 运行方法：SSWT 校准接入 NUFFT（最新阶段）

V4 使用 V2 从辅助 MZI 恢复的**估计光频轨迹**作为 V3 NUFFT 的非均匀坐标，使用 V1 的同一份主 OFDR 信号重构。与真实坐标 NUFFT、无校准 FFT、真值/SSWT 坐标插值 FFT 进行对照。

```matlab
addpath('matlab/v4');
smoke_test_v4;  % 基础物理和端到端回归检查
[cfg,truth,signals,results,metrics] = main_v4();
```

V4 产生 Figure 11（联合反射谱、双峰及孤立反射）、Figure 12（光频误差传播）、Figure 13（定量指标）。另可选择 `run_snr_sweep_v4();` 执行多 SNR 实验并产生 Figure 14。

```matlab
cfg=config_v4();
cfg.v4.include_stft_cwt=false; % 可选：避免 CWT/STFT 末端越界后的跳过警告
cfg.v3.kernel_width=12;
main_v4(cfg);
```

**重要：** V4 以仪器设置中的标称起止波长定义距离刻度，不能用真实 TLS 光频轨迹修正 SSWT 估计后再声称联合校准精度；若估计采样坐标超出 `[0,1)`，会明确报错而不是静默裁剪。

完整说明：[V4 实验指南](docs/V4_EXPERIMENT_GUIDE.md)。V4 尚未经过 MATLAB 实机运行验证，运行结果由用户本地检查。

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

**重要：** V3 NUFFT 的密度补偿属于可选的光频积分近似，对照 NUDFT 的采样权重必须完全一致。V3 的数值误差不等同于理论空间分辨率；将 SSWT 光频轨迹接到 NUFFT 已在 V4 实现。

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

## V7b：冻结参数泛化验证与失效机制

V7b 固定 V7 SAPC 的超参数，在100次全新随机试次中配对比较 SAPC 与 Static affine，记录训练条件数、最差退化和持出静止区表现。另提供17组预定义的 SNR、训练参考段、应变、Gauge 长度和 TLS 波动幅度条件扫描。代码尚待用户 MATLAB 本地运行验证。

- [V7b MATLAB 入口](matlab/v7b/README.md)
- [V7b 实验说明](docs/V7B_EXPERIMENT_GUIDE.md)
- [V7b 每幅图如何看](docs/V7B_FIGURE_READING_GUIDE.md)
- [V7b 冻结验证协议](docs/V7B_PRE_REGISTERED_PROTOCOL.md)
