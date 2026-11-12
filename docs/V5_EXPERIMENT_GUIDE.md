# V5 MATLAB 实验指南：光频校准误差传递

完整源方案见 [V5_CALIBRATION_ERROR_PROPAGATION_PLAN.md](V5_CALIBRATION_ERROR_PROPAGATION_PLAN.md)。本实现严格沿用 V1 的冻结频率信号模型、V2 的 SSWT、V3 的 Gaussian Gridding NUFFT 与 V4 的光频锚定接口；不改写旧版本算法。**本交付仅完成源码编写、静态检查和独立数值公式核验，V5 MATLAB 程序尚需本地实机运行验证。**

## 1. 入门：优先任务 P0 / P1

MATLAB R2020b 或更高版本，在仓库根目录依次执行：

```matlab
!git pull --ff-only origin main
addpath('matlab/v5');
smoke_test_v5;
[cfg,ctx,results] = main_v5();
```

`main_v5` 默认依次进行：

1. **实验 A (P0)**：默认 1.25 m 无噪声单峰，真实光频+Hann+Voronoi：全空间 NUFFT 与直接 NUDFT 比较；原始 0.8178 mm 距离网格和 0.02、0.01 mm 局部网格的峰宽、峰位收敛；同时重新测 SSWT 单峰。
2. **实验 B 比例误差 (P1)**：±1/3/10/30/100 ppm 和 0，7 个反射距离 0.25–2.7 m；固定真实主信号、只改核坐标；对照 `z/(1+epsilon)`。
3. **实验 B SSWT 残差倍率 (P1)**：0、0.25、0.5、1、2、4、8 倍真实 V2 残差，固定真实主信号，记录峰位、功率 FWHM、局部及全谱复数/幅度误差、固定真值位置的相位、幅度与权重差异。
4. **实验 D 诊断（单次）**：拍频误差与累计积分，首端/中段/末端贡献，光频误差的加权平均、线性斜率（ppm）、去仿射残差 RMS；外推开关、脊线平滑、仅恢复时辅助时延误差、拍频系统偏置。

> P0 参考：上一个版本在约 0.8178 mm 粗距离网格上测得的 FWHM 约 **1.5955 mm**，但论文方案的 0.02 mm 直接求和核验值约 **1.1781 mm**。V5 先复核这一差异，而不把 1.5955 mm 当作物理极限。细距离网格不改变系统分辨率，只降低测量的网格量化偏差。

P0 的测试使用 `v5_direct_z.m`，直接计算任意物理距离的傅里叶求和；**不是将频域信号零填充后声称提升物理分辨率**。测试会检查 0.02mm 与 0.01mm 的功率半高宽差值；未收敛不得判定 10 μm 峰宽变化为可信结果。

## 2. 全部实验入口

```matlab
cfg=config_v5();
cfg.v5.make_plots=false;       % 可关闭绘图以缩短批量执行时间
cfg.v5.save_results=true;      % 保存 .mat 与 PNG 所需数据

% P0 + P1 默认（含 D 的单次积分/边界诊断）
[cfg,ctx,results] = main_v5(cfg);

% B/C：同时生成相同原始 RMSE 与相同去仿射残差 RMS 两套误差族；固定真值权重与完整处理的对照
B_families = run_B_error_families_v5(ctx);

% D：辅助信号 SNR 5–40 dB；每档默认30次，完整主信号固定无噪声
D_snr = run_D_snr_v5(cfg);

% E：0.5–6mm 双峰间距 × 幅度比 × 相位差
E_doublet = run_E_doublet_v5(ctx);
```

亦可先设置 `cfg.v5.do_error_families=true; cfg.v5.do_snr=true; cfg.v5.do_doublet=true;` 后统一运行 `main_v5(cfg)`，**但默认不执行大矩阵**，避免单次初学仿真非常耗时。

首次 D-SNR 建议先检查短跑：`cfg.v5.snr_repeats=3;`；确认没有 MATLAB 错误后恢复预设 30 次，关键条件可以提高至 100 次。默认 D-SNR 实验保存 `matlab/v5/output/D_snr_trials/` 每个 trial 的设置、种子、真实/估计轨迹、辅助信号和关键谱指标；失败试次也存原因并计入失败率。

## 3. 关键物理约定

- 相对光频 `q=nu(t)-nu(t0)`，估计坐标由 `prepare_frequency_coordinates_v4` 中的 **首点锚定**和**独立标称带宽**得到，绝不用真实轨迹拟合 SSWT 结果。
- 注入规则仅为 `qhat=q+e`；主干涉信号使用 `q` 生成，**同一配对比较中不重新生成或重新加噪**。
- 等 RMS 比较有两种明确标注的评分模式：`raw` 是锚定后的原始采样 RMSE 相同；`residual` 是**加权去仿射残差 RMS 相同**，同时保留各自的真实原始 RMSE、加权均值和比例误差。两种模式不能混为同一条件。
- 现有 NUFFT 要求 `0<=u<1` 且严格递增。越界、非单调、无效峰宽、无法得到双峰判据，一律记录失败原因，不进行排序、裁剪或强行归一化。
- 全部物理距离用 `z=k*c/(2*ng*bandwidth)`。P0 的局部细网格用真实物理距离 `z` 直接求和，非零填充。
- FWHM 严格为 `|R(z)|^2` 的半功率宽度；**距离 bin、FWHM 与双峰可分辨间隔是三类不同指标**。
- 90% 能量宽度是**同一局部物理距离窗内**的 5%～95% 累计功率分位跨度；`edge_fraction` 监控窗边裁剪，不应与旧 V4 整段正距离范围的能量宽度无说明地比较。
- 峰位在已知真值附近评估，属于**位置辅助检测**。双峰判据为两峰各自邻域存在局部极大值且谷底低于较弱峰 3 dB（可调），不是通用或盲检分辨率标准。
- “固定权重”分支固定真实光频对应的 Hann 和 Voronoi，**仅用于相位传递机制诊断，不是可部署算法**；“完整处理”分支按估计坐标重算窗和权重，才代表当前处理流程。
- 所有幅度谱均用统一参照；保留未对齐复数 L2、固定真实位置相位差及峰位移动后的响应，不通过逐谱归一化或相位配准人为变好。

## 4. 代码文件

| 文件 | 功能 |
|---|---|
| `config_v5.m` / `main_v5.m` | 配置与 P0/P1 总入口 |
| `v5_setup.m` / `v5_single_signal.m` | V1/V2 真值与辅助估计、无噪声主干涉信号 |
| `v5_direct_z.m` / `v5_spectrum.m` | 任意物理距离 NUDFT 与固定/完整权重的 NUFFT |
| `v5_peak_metrics.m` / `v5_compare_spectrum.m` | 细网格功率 FWHM、90%能量宽度、相位及 L2 |
| `v5_error_decomposition.m` / `v5_inject_error.m` | 加权均值/比例/去仿射残差；等 RMS 不同形状的误差注入 |
| `run_A_fine_reference_v5.m` | P0 基准与网格收敛 |
| `run_B_scale_v5.m` | P1 比例误差×反射距离 |
| `run_B_residual_scale_v5.m` | P1 SSWT 残差倍率与固定权重消融 |
| `run_B_error_families_v5.m` | 等 RMS 误差形态及绝对偏置不变性 |
| `v5_beat_diagnostics.m` / `run_D_diagnostics_v5.m` | 拍频积分、边界贡献、平滑/时延/系统偏差对照 |
| `run_D_snr_v5.m` | 5–40dB 辅助信号的配对噪声试验、失败率 |
| `v5_detect_doublet.m` / `run_E_doublet_v5.m` | 双峰间距/强弱/相位与谷深判据 |
| `v5_calibration_requirements.m` | 分项研究阈值：位置、FWHM、核相位 |
| `v5_plot_results.m` / `v5_export_tables.m` / `smoke_test_v5.m` | 图 A-H（对应启用分支）、物理数值自检 |

## 5. 关键输出字段与示例阈值

```matlab
results.A.coarse_metrics.fwhm_m
results.A.step2.truth_metrics.fwhm_m
results.A.step3.truth_metrics.fwhm_m
results.A.step3.sswt_metrics.fwhm_m
results.A.fwhm_convergence_m
results.A.nufft_vs_nudft_full_relative_l2
results.B_scale.predicted_offset_m
results.B_scale.incremental_error_m
results.B_scale.valid
results.B_residual.metrics_full
results.B_residual.metrics_fixed
results.B_residual.failure_reason
results.D.baseline.q_decomposition.scale_ppm
results.D.baseline.edge_start_contribution_Hz
results.requirements
```

示例研究阈值来自方案：2.4 m 处定位增量不超过 0.1 mm，对应纯比例误差 \\(41.7\\) ppm 左右；若去仿射残差产生的核相位 RMS 不超过 0.1 rad，则 2.4 m 处残差光频 RMS 需约 \\(0.677\\) MHz 以下。**这两个阈值对应不同指标，不能混称单一“SSWT RMSE合格线”。**

## 6. 数据保存与回归测试

`main_v5` 默认保存 `matlab/v5/output/V5_baseline_P0_P1.mat`，包含完整参数、时间轴、真实/估计光频、拍频、主辅助信号、NUFFT 窗及权重、结果指标、实验运行时间和能够获取的 Git 修订 SHA；可从 `results` 的数据直接重新绘制。另有 `B_scale_summary.csv`、`B_sswt_gamma_summary.csv`（可用于 Excel/统计软件）。图像位于 `output/v5_figures/`。批量 SNR 的每次试验记录单独保存 `.mat`。

MATLAB 命令行：

```matlab
smoke_test_v5;
[cfg,ctx,results] = main_v5();
assert(results.A.fwhm_convergence_m < 0.005e-3);
```

**有待你在 MATLAB 实机确认的事项**：单峰粗细网格差异、NUFFT/NUDFT 数值误差、所有失败试次、SSWT 残差倍率大于 1 时的坐标有效性、真实 SNR 退化和双峰判据。该版本给出实验实现，不伪称已获得完整 V5 实验统计结果。科研使用时须根据自检/收敛结果决定是否执行更高密度网格或更宽的距离扫描。
