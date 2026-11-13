# V6a 图像阅读指南：从光频差分残差到零应变虚假应变

> 原则：每张图都先问**是否确实没有应变**、**究竟哪一个变量被改变**、**何种相位被比较**、**是否有大量相干衰落位置被剔除**。这是 V6a 最重要的科研质量控制。

## 1. Figure 1 — 为什么必须比较两次扫描的残差差，而不是单扫 RMSE？

- **研究假设 H1**：参考/测量扫频的共模校准误差可能抵消，真正造成相位差的是不相同的部分。
- **上图横轴**：时间 (ms)；**纵轴**：各自 SSWT 估计相对于真实光频的相对坐标误差 (MHz)。蓝：参考扫描，橙：测量扫描。只有辅助 MZI 噪声种子不同；真实 TLS、FUT 和主信号相同。
- **下图横轴**：时间 (ms)；**纵轴**：`e_meas(t)-e_ref(t)` (MHz)。绿：严格共模 SSWT（理论为0），橙：两次独立噪声 SSWT，紫：控制注入 rho=0 的差分轨迹。
- **精确字段**：`results.cases.independent_sswt.error_ref_Hz`, `.error_meas_Hz`, `.diff_coordinate_Hz`, `.diff_coordinate_rmse_MHz`。
- **支持的结论**：即使单扫误差非零，只要两次误差严格相同，差分轨迹为零。
- **不能得出的结论**：单扫光频 RMSE 越小，虚假应变一定越小。需结合 Figure 2/3。

## 2. Figure 2 — 零应变时到底测出什么？（主图）

### 上图：Rayleigh 复空间迹线的幅度与门控

- 横轴：光纤位置 z (m)；纵轴：oracle 复空间谱幅度相对于 oracle 最大值的 dB。
- 参考横线：oracle ROI 中位幅度 × `amplitude_gate_fraction`（默认0.25）的相对幅度阈值。两次估计谱也须超过这个**同一绝对阈值**。
- 含义：瑞利散射存在空间衰落。在深衰落区域，相位不稳定，不能把相位跳变都归因为校准误差。
- 必看字段：`results.cases.<key>.metrics.valid_sites`、`valid_gauge`、`valid_fraction` 和 `near_wrap_count`。

### 中图：两次扫描的空间 gauge 相位差

- 横轴：gauge 中点位置 (m)；纵轴：`angle(C(z+L_g) conj(C(z)))`，单位 rad；`C(z)=R_m(z)conj(R_r(z))`。
- 同色曲线：共模 SSWT、独立 SSWT、控制 rho=0。**实际应变为零**，非零 gauge 相位即当前简化模型中的相位伪差。
- 注意：此图不是 V5 的单扫描固定位置相位，也不是对空间谱的一次相位展开。对相位跨 π 的情况必须另行处理，不可继续按小误差指标解释。

### 下图：相位对应的零应变等效虚假应变

- 公式：`eps_proxy = gauge_phase * lambda0 / [4*pi*n_eff*(1-p_e)*L_g_actual] * 1e6`，单位 με。
- **重要边界**：这只是基于相位灵敏度假设的数值转换。**非零应变的正演真值还没有建立**，目前只能称作“虚假应变代理量”，不能称为已经验证的真实应变解调准确度。
- 比较 `oracle_oracle`、`common_sswt`、`independent_sswt` 和 `rho_000` 的 gauge 相位 RMS、虚假应变 RMS、P95、有效率，不要只看单根曲线峰值。

## 3. Figure 3 — 相同单扫 RMS、不同扫描间误差相关性

- **操纵变量**：参考/测量的注入光频误差有相同的单扫采样 RMS（默认 1.71 MHz），但经验相关性设定为 ρ=1、0.9、0.5、0。
- **上图**：两次坐标误差之差的 RMS (MHz)。如果ρ越低，该值通常越大。
- **中图**：gauge 相位 RMS (rad)。这是直接物理相位读数，应先看它而不是只看换算后的 με。
- **下图**：等效虚假应变 RMS (με)，并在标题报告有效 gauge 百分比范围。
- **判断 H1**：检查随 ρ 降低，差分残差是否增加，并验证相位 RMS、等效虚假应变是否同向退化；如果没有，则必须保留否定结果并研究散射衰落、残差结构或 gauge 作用，而不是强行设定单调性。
- **关键字段**：`results.controlled.rho_target`、`.rho_empirical`，`results.cases.rho_000.diff_coordinate_rmse_MHz`、`.metrics.gauge_phase_rmse_rad`、`.metrics.false_strain_rmse_microeps`。
- **目前不能声称**：扫描间相关性改变导致某个确定的应变提升倍数，也不能称 ρ=0 为真实 SSWT 噪声的准确统计模型。

## 4. 研究论文中应该汇报的统计表

| 指标 | 从哪里读 | 为什么要同时报告 |
|---|---|---|
| 参考/测量单扫 q RMSE (MHz) | results.calibration.reference / measurement | 对照单扫校准水平 |
| 差分 q RMSE (MHz) | cases.<name>.diff_coordinate_rmse_MHz | 候选误差传递主因 |
| gauge phase RMS (rad) | cases.<name>.metrics.gauge_phase_rmse_rad | 相位链的直接输出 |
| 等效虚假应变 RMS / P95 (με) | false_strain_rmse / p95_abs | 应用层代理指标 |
| 有效 gauge 比例 (%) | valid_fraction | 防止仅保留最容易的散射位置 |
| 近缠绕位置数 | near_wrap_count | 判断是否已超出零应变小误差近似 |
| 共模 oracle 结果 | oracle_oracle / common_sswt / rho_100 | 确认基线能否严格归零 |

## 5. 本阶段能支持的论文结论边界

**允许**：在固定散射体、固定真实 TLS、无主噪声的简化模型中，研究不同双扫描校准残差对应的 gauge 相位伪差和转换后的等效应变代理量。

**不允许**：报告真正的绝对应变测量精度、声称发现新的应变校正算法、直接套用 V5 单扫描固定相位误差估算微应变，或把控制误差族当成真实 SSWT 随机过程。

**下一步 V6b**：添加独立扫频、已知非零微应变前向模型及 gauge 响应校验，在新散射种子/独立噪声种子上进行 ≥30 次重复。只有 V6b 验证后才适合设计和评价新的相位校准策略（V6c）。
