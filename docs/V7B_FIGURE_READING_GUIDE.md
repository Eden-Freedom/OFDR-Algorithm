# V7b 逐图判读：从统计改善到可辨识性/泛化风险

所有图中的 **Core** 是已知应变平台区域；**Holdout** 是下游未受应变、未用于拟合的参考段；**Training** 是上游静止段。核心对照 **SAPC vs Static affine**，而非只与原始 SSWT 比。

## Figure 1：是否真正胜过简单仿射校正？

上图横轴是 Raw SSWT / Affine / SAPC，纵轴是 Core strain RMSE (με)，越小越好。它展示的是**不同方法的均值**，并非独立试次的配对检验。下图横轴分别为 Core 对 raw、Core 对 affine、Holdout 对 raw、Holdout 对 affine；纵轴是 `Baseline RMS − SAPC RMS` (με)，**正值**表示 SAPC 改善，误差棒是 trial bootstrap CI95。

**必须读** `results.blind.summary.comparisons(2).core_gain_CI95` 和 `holdout_gain_CI95`；同时读试次失败率及有效 gauge fraction。若 Core CI 在零之上、Holdout CI 跨零，则不能声称跨区域泛化成立。

## Figure 2：哪些试次更差？是否只是过度拟合？

上图：横轴 Static affine Core RMSE (με)，纵轴 SAPC Core RMSE (με)；低于 y=x 为 SAPC 改善，高于 y=x 为退化。每点是一**次完整光纤+辅助信号随机试次**，不是每个距离像素。

下图：横轴上游训练段 gauge 相位 RMS 减小量 (rad)，纵轴 Core RMSE 改善 (με)。如果横轴明显大于零、纵轴却小于零，意味着“训练拟合变好而应变结果退化”的过拟合候选现象。**这只是关联，不证明因果。**

必看：`results.blind_diagnostics.worse_indices`、`train_improvement_rad`、`trial_gain_microeps`、`holdout_gain_microeps`。退化实验不能删除。

## Figure 3：拟合不稳定/可辨识性候选因素

上图：横轴 Hessian 的**倒条件数** `rcond(H)`（对数尺度，越小可能越病态），纵轴 SAPC 相对 affine 的 Core RMSE 改善。下图：横轴 SAPC 最大校正量 (MHz)，纵轴 Core 改善。低条件数、很大的校正量或低训练点数若与退化共同出现，提示约束算法可能需要可信度门控。

必须对比胜/负试次上的：`train_count`、`hessian_rcond`、`beta_l2_MHz`、`max_correction_MHz`、`diff_rmse_MHz`、`aux_ref_rmse_MHz`、`aux_meas_rmse_MHz`。这些诊断量不能用于修改当前盲测超参数，否则就会污染独立测试集。

## Figure 4：哪些物理条件可能导致失效？（需启用 conditions）

横轴是 17 个**不同物理条件标签**，纵轴是 `Affine Core RMSE − SAPC Core RMSE` (με)；大于零支持在该条件下提升，小于零说明均值退化。当前柱形图只是初步可视化，判断是否稳定须读取每组 `results.conditions.runs{k}.summary.comparisons(2).core_gain_CI95`、失败率、持出区和有效率。

17 组分为 SNR、静态训练段、真实应变、gauge、TLS 波动幅度。**不同物理组的随机种子不同**，不应用相邻柱子的高低直接推导因果关系；需要进一步的受控相同散射体比较或重复试验。

## 可以与不能推出的论文结论

| 可以支持（在符合条件时） | 不能支持 |
|---|---|
| 100 次全新合成试次中，SAPC 相比 affine 的配对增益与风险分布 | 已有实物仪器级应变精度改善 |
| 非仿射优化可能遭遇可辨识性或泛化问题 | Hessian rcond 与误差之间相关就证明它是因果机制 |
| 较短参考段或较低 SNR 下出现适用边界 | 算法适用于任意双扫描 TLS 轨迹和频带错配 |
| 训练相位改善不保证 Core / Holdout 改善 | 可仅凭训练指标选择参数后重复当作盲测报告 |

后续研究方向：根据这里观察到的风险设计**可信度约束、回退仿射**的 V7c，但必须在另一个独立随机种子空间验证，不能使用 V7b 的正式测试数据完成调参后再报告同一批的验证结果。
