# V7c 每张图怎样看（论文研究专用）

每一幅图都必须检查 **Core RMSE、未训练的下游静止区、有效率、试次失败率**；研究算法好坏不能只看训练相位。

## Figure 1：冻结/开发集下六方法的误差与置信区间

- 上图横轴：Raw SSWT / Static affine / Full SAPC / CV-SAPC；纵轴：非零应变 Core RMSE (με)，越小越好。Oracle 与平滑基线的数值另看 `summary.mean_core`。
- 下图：CV-SAPC 相对 affine 和 full SAPC 的 **Core、Holdout** 配对改善 (με)，误差条是 trial 级 bootstrap CI95。点及整条区间在 0 上方才提供平均改善的统计证据。
- 读日志：`summary.comparisons(2)` 是相对 affine，`comparisons(3)` 是相对 **full** SAPC。不能把后者当作原始 SSWT。
- 成功条件：与 affine 的 Core 和 Holdout 改善 CI95 下界均 >0、有效 gauge 比例无超额损失；与 full 的收益是证明门控的**增量价值**所需的独立比较。
- 失败判据：某指标变好但持出区恶化、CI 跨 0、失败数增加或退化极值扩大。

## Figure 2：逐试次的收益和失效

- 上图横轴是该试次 Static affine Core RMSE (με)，纵轴 CV-SAPC Core RMSE (με)。点在 y=x 下方，说明该次门控方法更好；反之更差。
- 下图横轴是**上游内部留出区**相位 RMS 改善百分比，纵轴是**真正受应变 Core** 相比 affine 的改善 (με)。颜色表示 α，α=0 是回退 affine。
- 如果验证区改善大、实际 Core 却恶化，说明“CV 分数预测下游精度”的假设在该试次失败；这是有价值的反例。**不得使用这些失败点重调本批测试阈值**。

## Figure 3：可辨识性与回退比例

- 上图横轴是未正则化 Hessian 的 `rcond(J'J)`（越大一般越好辨识），纵轴是 Core 改善 (με)。不能从散点相关直接断言因果，需要对条件数阈值做全新种子消融。
- 下图是混合权重 α 的 trial 计数（0/0.25/0.5/0.75/1）。α=0 不代表“无校正”，而是**仍采用 Static affine**；这是对真实应变更稳健的尝试，但可能丢失有益非仿射校正。
- 必须同时看 `fallback_reason`, `cv_folds_ok`, `failure_reason`, `data_hessian_rcond`, `extra_peak_MHz`, `summary.selection_alpha_counts`。优化失败绝不能转为“成功且误差=0”。

## 若启用物理条件泛化

- 查看 `V7c_conditions.csv`，分别对 SNR、上游静态段、应变幅度、Gauge 长度与共同 TLS 扫频 ripple 做比较；每组至少 30 次才适合稳定地报告趋势。
- 在 SNR 15 dB 这样的困难条件，报告 `n_valid/repeats`，不能只对有效试次结果做宣传。
- 各条件种子不同，**不能将条件之间的差值直接归因于唯一物理因素**；如需严格估计单一因素的影响，应改为跨条件相同随机种子的因子实验。

## 论文创新性边界

当前 V7c 是静态参考段 + 内部空间 CV + 自适应非仿射混合的研究性原型。即使试次结果优秀，也尚不等于它相对于现有双扫描对齐、RPN/相位预测、自适应正则化算法拥有确定原创性。还需要补充相位真实灵敏度、探测噪声、扫描起止频带失配、无静态参考段的外推及真实仪器实验。
