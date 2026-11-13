# V6b：零应变双扫描残差机理与统计鲁棒性实验指南

> 承接 V6a（零应变、同一真实扫频、同一静止光纤、无主测量噪声）；本阶段是**机理确认**，不是“已经解决应变相位误差”。代码：`matlab/v6b/`。
> 原理参考：[研究路线](PHASE_STRAIN_RESEARCH_ROADMAP.md) | [V6a 逐图指南](V6_FIGURE_READING_GUIDE.md) | [V6b 逐图指南](V6B_FIGURE_READING_GUIDE.md)。

## 1. 针对 V6a 已有实测数据的判断

V6a 报告：oracle/oracle、共模 SSWT、rho=1 的 gauge 相位≈0；独立 SSWT 的双扫描光频差 RMSE=1.45000 MHz、gauge 相位 RMS=0.047289 rad、零应变等效代理 RMS=0.519102 με；控制误差 rho=0、0.5、0.9 的代理 RMS 分别约为 1.839、1.765、1.152 με。

当前证据支持“扫描间不一致可产生差分相位”，**但 V6a 每个相关条件只有一组样本**，无法判断统计显著性、散射衰落结构及 gauge 长度的影响。代理 με 未经过非零应变正演标定，不能称作已证实的真实应变测量误差。

## 2. V6b 验证四个可证伪问题

1. **H1 重复性**：两个扫描的单扫光频误差 RMS 相同（1.71 MHz），但相关性 rho 改变时，是否稳定改变 gauge 相位与虚假应变代理？在同一 trial 内，**共用一段 Rayleigh 散射体、原始主信号、参考误差**，仅改变测量误差；不同 trial 变更独立随机种子。
2. **H2 结构性**：比较总扫描间误差 RMSE 与加权去仿射残差 RMS，哪一个更能解释 gauge 相位？把真实双扫描 SSWT 差分误差拆为 **锚定线性坡度** 与 **锚定非线性**，测试单独的相位效应。
3. **H3 距离/gauge**：固定同一差分误差、同一 Rayleigh 实现，改变 gauge 长度和评分距离段；区分真实相位敏感性与有效位置变化。
4. **H4 独立 SSWT**：除可控注入外，直接重复两次独立辅助噪声的 SSWT 校准；两条误差 RMS **不人为强制相等**。

所有实验是**零应变**，真实 TLS 扫频和静态光纤不变，主干涉仪噪声关闭，因此能够隔离校准坐标不一致的影响。

## 3. MATLAB 运行

在 GitHub 仓库根目录：

```matlab
!git pull --ff-only origin main
addpath('matlab/v6b');

smoke_test_v6b;         % 先验证共模抵消、rho、分量重建、空间矩阵

[cfg,results] = main_v6b(); % 快速验证：8 次控制随机重复+4 次独立 SSWT 重复
```

准备**论文级探索**可调整：

```matlab
cfg=config_v6b();
cfg.v6b.repeats=30;
cfg.v6b.sswt_repeats=30;
cfg.v6b.bootstrap_reps=2000;
cfg.v6b.verbose=false;
[cfg,results]=main_v6b(cfg);
```

30 次仍然属于第一轮，判断跨散射/跨条件稳健性时可扩展 100 次和多个独立配置。低样本数的 bootstrap 置信区间仅用于调试，不是论文级显著性证据。

无额外 Wavelet Toolbox 或第三方 NUFFT：仍调用 V2 的 Morlet CWT/SSWT、V3 自写 Gaussian NUFFT、V6a Rayleigh 与 gauge 解调。

## 4. 四组实验与数据定义

### A. 配对多随机种子相关性实验

`run_v6b_correlation_mc(cfg,truth)`

- 每个 trial 生成一条新静态复 Rayleigh 散射体谱，**相同 trial 内所有 rho 共用**；
- 每对误差首样本锚定为零，分别归一化到 1.71 MHz 的单扫 RMS；原始/测量误差的实际 Pearson 相关系数记录在 CSV；
- 相同 trial 内，各个 rho 的相位结果**统一评估在所有有效 rho 都通过的共同 gauge 点掩码**上，另行保存各组原始通过率；
- 不对通过门限的空间像素做独立 bootstrap：**trial 才是重复统计单位**；
- 每个 rho 给出均值、重复数、失败率和试次级 bootstrap 95% 区间；
- 记录核相位接近 ±π 的计数，避免把相位绕回当作低误差。

**必查字段：**
`results.correlation.rho_target`、`empirical_rho`、`diff_rmse_MHz`、`common_gauge_rmse_rad`、`common_false_proxy_rmse_microeps`、`common_valid_fraction`、`summary.proxy_CI95_microeps`、`failure_reason`。

### B. 真实独立 SSWT 重复

`run_v6b_independent_sswt(cfg,truth)`

每次采用不同辅助探测噪声种子，重新执行完整 Morlet CWT/SSWT/脊线/积分。记录参考及测量单扫 RMSE、两次差值 RMSE、gauge 相位、代理 με、有效率和失败原因。与注入数据的条件分布不一定相同，**不能当作“控制方法优于 SSWT”实验**。

### C. 误差分量消融：不利用真值进行实际修正

`run_v6b_components(cfg,truth)` 与 `v6b_decompose_error.m`

以固定的真值窗/密度权重进行加权最小二乘：

\[
\Delta e(t)=b+\epsilon(q(t)-\bar q_w)+r(t).
\]

由于重建前要减去首样本，**单独加入一个绝对常数偏置会被锚定抵消**；不可把统计均值 `b` 与可以直接注入的绝对光频偏置混淆。

实际消融只注入两项：
- 锚定坡度：\(e_{\rm ramp}(t)=\epsilon[q(t)-q(t_0)]\)
- 锚定非线性：\(e_{\rm nl}(t)=r(t)-r(t_0)\)

它们相加必须重构出**同一条锚定差分误差**。比较 no difference / ramp only / nonlinear only / full difference 的 gauge 相位 RMS、有效率和等效代理量，不能直接相加不同分支的 RMS 作为总结果。

**重要：** 该分量分解使用真实光频，仅用于机制诊断，不是能够部署的校正算法，也不是创新方法已取得效果。

### D. 距离与 gauge 长度矩阵

`run_v6b_spatial_gauge(cfg,truth)` 在相同的 rho=0 误差对、同一散射实现下，扫描以下 gauge 长度：5、10、20、40 mm，和 0.50–2.30 m 内的六个距离段。

各距离段使用同一次完整 ROI 的幅度阈值，不在每段重新归一化。报告 gauge 相位 RMS、代理 με 和有效位置百分比。由于瑞利相干衰落，不应强行预设峰宽/应变 RMS 随距离必然单调增加。

## 5. 输出文件、统一有效性约定

默认位于 `matlab/v6b/output/`：

- `V6b_zero_strain_mechanism.mat`：配置、版本、真实轨迹、逐试次结果、例子中的真实/估计误差与谱、全部失败原因；
- `V6b_correlation_trials.csv`：每次 trial×rho 的指标，含随机种子、共同有效位置和失败原因；
- `V6b_correlation_summary.csv`：trial 层均值、bootstrap CI、失败率；
- `V6b_independent_SSWT_trials.csv`：真实独立 SSWT 配对；
- `V6b_component_ablation.csv`：误差分量消融；
- `V6b_distance_gauge_matrix.csv`：空间/量测长度矩阵；
- `figures/v6b_fig1_*.png` 至 `v6b_fig5_*.png`：五幅图。

不允许将 NaN 失败组当成 0；所有未通过有效性检查的工况必须进入失败率统计，报告 CI 的有效 trial 数。默认 8 个重复 **不足以证明论文级稳健性或显著性**。

## 6. 图和指标与科研结论的对应

| 研究假设 | 主要图 | 主指标 | 暂可支持什么 | 下一关 |
|---|---|---|---|---|
| H1 差分残差相关性 | Figure 1,2 | matched-mask gauge phase & CI | 机制是否可重复 | 不同 TLS 扫频和主噪声 |
| H2 差分结构 | Figure 2,3 | 加权分量、分支 gauge 相位 | 哪一类结构更有影响 | 无真值校正约束是否可辨识 |
| H3 距离/gauge | Figure 4 | phase RMS + 有效率 | 适用范围和相干衰落作用 | 非零应变前向模型 |
| H4 实际 SSWT | Figure 5 | 独立 q RMSE、gauge RMS | 独立辅助噪声下能否复现 | 与强基线和实测数据比较 |

## 7. 继续创新开发的决策门槛

只要“差异误差导致虚假应变”而不提出新有效算法，**仍不构成论文主要创新点**。后续需要：
1. 建立已知非零应变的 Rayleigh 前向物理模型，验证相位符号与灵敏度（包括有效相折射率、弹光项、轴向位移）；
2. 在非零应变+零应变控制中复现相同关系，输出真正的应变 RMSE (με)；
3. 在不利用真值光频/受应变测试区的前提下提出相位保真校准或双扫参考约束；
4. 与原始 SSWT、平滑 SSWT、参考/测量同步等光频重采样（SEFR）、已有相位预测/残余噪声抑制路线公平对照；
5. 不同种子和噪声下统计显著改进，充分报告失败样本和复杂度。

SEFR 参考：Chen 等，*Optics Letters* 49, 7134–7137 (2024)，DOI [10.1364/OL.548127](https://doi.org/10.1364/OL.548127)。其已经研究双阶段扫频非线性与频带错配下的 OFDR 相位/应变精度，不能宣称“首次发现双扫相关误差”。

**注意：V6b 源代码尚须 MATLAB 本机运行验收。本文件描述的是实验设计和程序功能，不是已经获得的 V6b 统计结果。**
