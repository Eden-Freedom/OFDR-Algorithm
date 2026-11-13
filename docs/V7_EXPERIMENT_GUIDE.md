# V7：Static-Anchor Phase-Consistency (SAPC) 校正器原型

**状态**：探索性、需 MATLAB 本地验收；不是原创性/性能提升声明，也不是完整 SEFR 复现。承接 V6b/V6c 的问题：扫描间校准不一致是否可以在不消除真实应变的前提下降低？

## 1. 方法原理和适用前提

- 使用 V2 SSWT 分别估计参考和测量扫描的光频坐标。
- **静态上游参考段**预先已知为 `[0.55,0.98] m`；应变区为 `[1.08,1.62] m`。SAPC 校正器只观察上游参考段两次 NUFFT 复迹线的 **gauge 相位差**，并不观察受应变区域数据。
- 对测量坐标施加低维函数：

  `q_meas_corrected(t) = q_meas_SSWT(t) + 1e6 * B(t)*beta`,

  `B=[x, x(1-x), sin(2*pi*x), sin(4*pi*x)]`, `x=(q_est-q_est(1))/(q_est(end)-q_est(1))`。

  系数 beta 的单位为 MHz；所有基函数在首样本为零，以固定本次扫描锚点。`static_affine` 基线只使用 B 的第一列。
- 利用静态段 gauge phasor 相位的平方残差加二次正则罚项，在**训练段**用阻尼 Gauss–Newton + 数值差分雅可比优化 beta；拟合过程中拒绝非单调或过大校正。
- 指标在真实应变 core 与**完全不参与拟合的下游静止 holdout 段 `[1.78,2.23] m`**上独立评分；训练、验证空间段不混用。
- 额外提供 `smoothed_sswt` 基线：只对辅助拍频做 81 点滑动平均后积分，避免把一般平滑收益误认成创新。

**限制（尤其重要）**：当前参考和测量扫描的真实 TLS 轨迹相同。若实机两次扫描有不同的真实扫频起止点、不同非线性、频带错配，就不能仅凭静态相位假设无条件“拉齐”所有坐标。本原型**要求预先知道不受应变的参考光纤段**；如果该假设不满足，校正可能消除真实变化。本原型使用历史 V6 的已知标称扫描带宽定义距离轴，不用真实误差对参数拟合，但其总体仿真仍是已知系统标称参数的简化模型。

## 2. 公平对照

| 方法 | 轨迹来源 | 是否接收应变真值/真实光频来拟合？ |
|---|---|---|
| Oracle | 理想光频 | 评分上限，非可部署 |
| Independent SSWT | 各次扫描独立 SSWT | 否 |
| Smoothed SSWT | 仅测量 SSWT 的辅助拍频加大滑动平均 | 否 |
| Static affine | 已知上游静态段、只拟合一个锚定比例项 | 否 |
| SAPC | 同一训练段、拟合四基非仿射模型 | 否 |

同一 trial 中五组使用同一散射体/原始主信号、相同物理应变、相同 9-bin 相位平均、共同有效掩码。**所有方法的 core 和独立静态测试段都不能用来拟合超参数**。

## 3. 运行

```matlab
!git pull --ff-only origin main
addpath('matlab/v7');
smoke_test_v7;
[cfg,results]=main_v7();  % 默认8次功能验收，不足以支持论文结论
```

如果自检通过且参数事先固定，进行 36 次配对测试：

```matlab
cfg=config_v7();
cfg.v7.repeats=36;
cfg.v7.bootstrap_reps=2000;
[cfg,results]=main_v7(cfg);
```

输出在 `matlab/v7/output/`：`V7_static_anchor_pilot.mat`、`V7_trial_results.csv`、`V7_method_summary.csv` 和 3 张 PNG。

**避免数据泄漏**：不能根据 Figure 1 的 Oracle RMSE 或受应变 core 分数调 `regularization`、`train_static_m`、`max_iterations` 或 basis。正式测试应把调参种子与锁定超参数后的测试种子分离；下游 holdout 若用于调参则需要再设新的从未观察过的测试段。

## 4. 必看指标与否定标准

- 核心 `results.summary.mean_core`：实际已知应变区域 Core RMSE (με)；是否明显低于 raw SSWT。
- `results.summary.mean_holdout`：下游未受应变、也没有参与拟合的虚假应变 RMS (με)；不能用训练段上的 loss 代替。
- `results.summary.mean_valid`：有效 gauge 比例；误差下降不能伴随大量位置被门控删除。
- `results.summary.paired_gain_sswt_vs_SAPC`、`paired_gain_CI95`：同一 trial 的原始 SSWT 与 SAPC 配对差值。CI 跨 0 或负数，则**不能宣称改进**。
- `results.train_phase_before/after`：训练段拟合是否下降，只是优化成功证据，不是传感效果证据。
- `results.failure_reason`：优化不可辨识、坐标非单调、训练段门控不足等必须计入失败率。

SAPC 当前只是一种**待证伪的静态锚段约束方案**；即使改善也要与文献中的参考段非线性补偿、SEFR 及动态配准方法查新和公平比较。

[逐图阅读](V7_FIGURE_READING_GUIDE.md) ｜ [V6d 机制消融](V6D_EXPERIMENT_GUIDE.md)
