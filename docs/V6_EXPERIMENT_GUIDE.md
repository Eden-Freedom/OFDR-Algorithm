# V6a 零应变双扫描：MATLAB 实验与复现指南

**研究目标**：检验 V5 的“单扫描 SSWT 光频残差造成复数相位偏差”是否能传递到 **参考与测量双扫描之间的 gauge 相位差**，进而在本零应变模型中形成**等效虚假应变代理量**。这属于论文假设 H1 的基线验证，不预设 SSWT+NUFFT 必然需要新算法，也不把相位误差直接包装成实验应变精度。

本次仅实现 **V6a 零应变控制**。不是 V6b 全面机理实验或 V6c 新校正算法；未来必须增加非零应变的相位灵敏度正演/验收、独立扫频错配、主信号噪声和更多次重复。

## 1. 一键运行

MATLAB R2020b+，不需要 Wavelet Toolbox 或第三方 NUFFT 库：

```matlab
!git switch main
!git pull --ff-only origin main
addpath('matlab/v6');
smoke_test_v6;
[cfg,results] = main_v6();
```

`smoke_test_v6` 使用较稀疏散射分布以加速，验证：

- oracle/oracle 零应变输出零；
- 完全相同 SSWT 残差（共模）输出零；
- 完全相关（ρ=1）的控制残差输出零；
- 控制误差的 RMS 和样本相关系数匹配目标；
- gauge 延迟与空间门控有效。

主程序 `main_v6()` 使用默认散射密度、独立辅助噪声和相关性实验；执行后输出控制台统计、3 张图、一个 `.mat` 和两份 `.csv`。

## 2. 物理模型与重要限制

- **零应变**：参考扫描和测量扫描的散射体位置与复系数完全相同。所有工况使用同一条真实 TLS 非线性扫频和同一份**无噪声、实值主干涉信号**。两个扫描之间不重新生成散射体或主探测噪声。
- **Rayleigh 近似**：用空间上固定位置的独立复高斯散射系数 `a_j` 表示静止瑞利散射结构，按 `s(t)=Re{Σ a_j exp(i 2π (2 n_g z_j/c) q_true(t))}` 合成。它是简化的多散射体冻结频率模型；不包括真实偏振、色散、激光线宽或相干衰落随时间变化的完整光场过程。
- **辅助校准**：参考和测量使用同一个真实辅助 MZI 干净信号，各自加入独立且有记录种子的 AWGN，经 **V2 自实现 CWT+SSWT** 恢复光频；默认辅助 SNR 25 dB。
- **空间重构**：对不同估计光频坐标调用 **V3 Gaussian Gridding NUFFT**；统一标称光频带宽和物理距离网格，按各自坐标计算 Hann 窗与 Voronoi 权重。不能偷偷用真值修正独立 SSWT 结果。
- **真实光频相同**是故意设置的控制变量。这个版本**不检验**真实参考/测量两次独立激光扫描轨迹或扫频跨度错配。
- **零应变等效微应变代理量**：仅在局部 gauge 相位幅值较小、未跨越 π 的近似下，通过 `lambda_ref/(4*pi*n_eff*(1-p_e)*L_g)` 换算得到。`n_eff` 是有效相折射率近似参数，与重构用的群折射率 `n_g` 物理上不同。**尚未通过已知非零应变前向模型验证比例系数/符号，不能称为实测应变精度**。

## 3. 两次扫描和 gauge 处理的定义

定义参考 `r`、测量 `m` 的 NUFFT 复空间迹线为 `R_r(z)`、`R_m(z)`：

```text
C(z)          = R_m(z) * conj(R_r(z))
phase(z)      = angle(C(z))
gauge_phase   = angle(C(z + Lg) * conj(C(z)))
false_epsilon = gauge_phase * lambda_ref / (4*pi*n_eff*(1-p_e)*Lg)
```

当真实应变为零时，`false_epsilon` 应为零。实际 gauge 长度为 `round(Lg/dz)*dz`，控制台和 `metrics.gauge_length_actual_m` 均保存**实际**长度，而不是假设任意要求的 Lg 与距离网格完全对齐。

*零应变小误差*实验采用两端复比值的主值相角计算 gauge 差分（避免无条件跨散射衰落点进行全局相位展开）。若误差超过 π，局部相位可能缠绕，程序输出 `near_wrap_count`；不得把当前主值结果继续当作有效的大应变解调。

门控：采用 oracle 空间谱在 ROI 内的**中位幅度 × 0.25**作为三条迹线共同的绝对幅度阈值。只有 oracle、参考和测量在 gauge 两端均超过阈值时才计入。报告有效位置比例；低于 15% 则记为无效。该门控以真值轨迹作基准，是**可控机制验证的 oracle 门控**，不是未来部署在未知光纤上的算法。

## 4. 工况及如何区分机制

| 工况 key | 两条输入光频坐标 | 核查目的 |
|---|---|---|
| `oracle_oracle` | 都为真实 `q_true` | 检查物理无变化时解调链应为零 |
| `common_sswt` | 两条均为同一份参考 SSWT 轨迹 | 完全共模误差的代数消除（必要自检，不是实测证明） |
| `independent_sswt` | 同一真实 TLS，但两组独立辅助噪声的 SSWT 结果 | 在相同物理主信号下测试算法噪声产生的差分相位 |
| `rho_100` / `rho_090` / `rho_050` / `rho_000` | 锚定后单扫 RMS 均为 1.71 MHz、经验相关性约 1/0.9/0.5/0 的平滑注入误差 | 检查相同单扫 RMSE、不同扫描间残差差导致的不同虚假应变 |

控制误差只改变**重构坐标**，主数据不重新生成。`rho` 是误差轨迹的经验 Pearson 相关系数，并不意味着真实 SSWT 残差就是该平稳随机模型。两种实验必须分开报告。

无效光频坐标（非严格递增、出 `[0,1)`）会被原接口拒绝并在该工况中记录错误，不排序/裁剪/重归一化。`near_wrap_count` 非零时，应把对应相位结果标为需要更强的解缠算法验证。

## 5. 输出和必读字段

### 日志

每行输出：`diff-RMSE(MHz)`、`gauge-phase(RMS rad)`、`false-strain(RMS ue)`、`valid(%)`。这三个指标的任务不同，不能相互替代。

### 结果结构体

```matlab
results.cases.oracle_oracle.metrics.false_strain_rmse_microeps
results.cases.common_sswt.metrics.false_strain_rmse_microeps
results.cases.independent_sswt.metrics.false_strain_rmse_microeps
results.cases.independent_sswt.metrics.gauge_phase_rmse_rad
results.cases.independent_sswt.diff_coordinate_rmse_MHz
results.cases.rho_000.metrics.false_strain_rmse_microeps
results.cases.rho_100.metrics.false_strain_rmse_microeps
results.cases.rho_000.metrics.valid_fraction
results.controlled.rho_empirical
results.calibration.reference.q_rmse_MHz
results.calibration.measurement.q_rmse_MHz
```

`results.cases.<name>.metrics` 还包含 `false_strain_bias_microeps`, `false_strain_p95_abs_microeps`, `valid_gauge`, `near_wrap_count`, `z_gauge_mid_m`, `raw_phase_rad`, `gauge_phase_rad`, `equivalent_false_strain_microeps` 等完整矢量。

默认输出目录 `matlab/v6/output/`：

- `V6a_zero_strain.mat`：配置、真实光频、共享主信号、复散射体、两组辅助信号与种子、每种重构的谱、门控、相位与等效应变数组。
- `V6a_case_metrics.csv`：各组 RMSE/偏差/P95/有效率/失败原因。
- `V6a_correlation_metrics.csv`：目标和实际 ρ、误差 RMSE、gauge 相位 RMS、虚假应变代理 RMSE。
- `V6a_Figure1_paired_residuals.png`、`V6a_Figure2_gauge_phase_and_strain.png`、`V6a_Figure3_correlation_vs_false_strain.png`。

详细的逐图读数和**允许/禁止结论**：[V6_FIGURE_READING_GUIDE.md](V6_FIGURE_READING_GUIDE.md)。

## 6. 首轮验收条件与可能的失败

1. `smoke_test_v6` 通过；oracle / common / rho=1 的 gauge 相位 RMS 和虚假应变代理量应接近零。若非零，优先排查**不同主信号、距离网格错位、重复输入变换、门控不一致**。
2. `rho=0` 的差分光频坐标 RMS 应为正，经验 ρ 近零；其虚假应变不强制预设数值或单调增幅，由真实仿真决定。若完全没有效应，检查强度、gauge 与动态范围；不能为了验证假设修改真值。
3. 报告每组 ROI 的有效 gauge 样本数、比例和相位接近缠绕的数量。
4. 同一随机种子重复运行应复现结果；同时报告散射体种子、辅助噪声种子和注入种子。
5. 若相关性曲线不严格单调，不得直接宣称 H1 已成立；首先重复独立随机种子与散射实现，再用配对统计评估。
6. 一组数据不构成显著性证据。**V6a 不宣称找到创新算法**；后续 V6b 需要重复 ≥30 次、扫描 gauge/距离/SNR，V6c 才比较新校正方法与文献基线。

## 7. 快速改参

```matlab
cfg=config_v6();
cfg.v6.inject_rms_MHz=3;         % 更大的控制校准误差
cfg.v6.rho_values=[1 0.9 0.5 0]; % 改变扫描间相关性
cfg.v6.gauge_length_m=0.020;     % 20 mm gauge；转换系数随实际长度改变
cfg.v6.aux_snr_dB=15;            % 改变两次 SSWT 的辅助信号噪声
cfg.v6.scatter_seed=2611;       % 换一个固定的散射体实现
[cfg,results]=main_v6(cfg);
```

**不要只比较等效应变数值**：不同 gauge 长度改变空间平均尺度、相位差和应变换算系数，需要同时报告有效率、相位 RMSE 与局部相干衰落状况。
