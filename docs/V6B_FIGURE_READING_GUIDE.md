# V6b 五幅图该怎么看？——以发现可发表问题为目标

适用入口：`smoke_test_v6b; [cfg,results]=main_v6b();`。先运行[实验指南](V6B_EXPERIMENT_GUIDE.md)，再根据该文读图。

**统一原则：** 实际光纤零应变；Gauge 相位 RMS 的单位 rad，是物理相位评价量；虚假应变 µε 目前只是基于简化系数的 **equivalent proxy**，必须等待非零应变前向/解调自检。

## Figure 1：跨试次的 rho 效应和统计不确定性

三个子图按顺序：两次误差的 RMSE (MHz)、共同有效位置的 gauge 相位 RMS (rad)、虚假应变代理 RMS (με)，横轴都是 **扫描间校准残差相关系数 rho**。

**假设：** ρ 升高，差分误差趋于零，而 gauge 相位/虚假应变趋于零。

**你应该读取：** `results.correlation.summary.mean_diff_MHz`, `mean_gauge_rad`, `mean_proxy_microeps`, `proxy_CI95_microeps`, `n_success`, `matched_failure_rate`。线条是不同 trial 的平均，不是同一段光纤的连续变化；误差条是 trial 重采样的 bootstrap 95% 区间。必须报告 trial 数和失败率。

**可以说：** 若配对条件下的趋势在足够多 trial 中稳定，单扫 RMSE 一样时扫描间相关性仍与误差有关。

**不能说：** 有相关性就意味着某个已实现算法提高了实际应变精度；ρ 是实验注入参数，不是一个可凭空控制的实际硬件按钮。

## Figure 2：同一差分 RMSE，也可能有不同 gauge 相位

上图横轴为扫描间光频 RMSE (MHz)，下图为**去仿射非线性残差 RMS** (MHz)，纵轴均为共同有效位置下的 gauge phase RMS (rad)。每个点是一个完整的独立试次，颜色代表 ρ。

**假设：** 如果非仿射残差结构解释力更高，下面的点云可能更紧密。反之可能均值/比例项主导。

**操作：** 比较相同的 trial 和空间掩码；进一步对 `results.correlation.diff_weighted_mean_MHz`, `diff_scale_ppm`, `diff_nonlinear_rmse_MHz` 做联合回归，避免仅凭散点“更集中”宣布因果。

**不能说：** 相关散点是因果校正方案；本图只是诊断，需消融与独立种子验证。

## Figure 3：SSWT 误差分量消融

横轴四组：No diff、Anchored ramp、Anchored nonlinear、Full diff；三个纵指标为差分光频 RMSE、gauge 相位 RMS、等效虚假应变 RMS。

**假设：** 如果主要由非线性项造成噪声，Anchored nonlinear 的 gauge 误差应接近 Full diff；如果 ramp 占主导则相反。消融后两项叠加并不一定等于两项 RMS 简单相加。

**需要读取：** `results.components.decomposition.scale_ppm`, `nonlinear_weighted_rmse_Hz`, `sum_check_max_error_Hz`, `results.components.gauge_rmse_rad`, `case_valid`。

**最重要的警告：** 分解时用了真实光频；它不是可直接用于现场数据的“新算法”，不能把删除其中一个真值分量当成论文性能改进。

## Figure 4：空间与 gauge 长度依赖

上图：横轴为距离段中心 (m)，纵轴为实际 gauge 长度 (mm)，颜色是 gauge phase RMS (rad)。下图相同坐标，颜色为有效 gauge 百分比。

**假设：** 误差可能随距离和 gauge 变化，但不预设单调性，因为随机瑞利相干衰落/差分滤波都影响测得的相位。

**需要读取：** `results.spatial.distance_bands_m`, `gauge_actual_mm`, `gauge_rmse_rad`, `false_proxy_rmse_microeps`, `valid_fraction`, `failure_reason`。

**不能说：** 单个随机散射实现的热图就是距离依赖的普适规律。应对多个独立光纤实例和噪声 seed 重复该扫描。

## Figure 5：真实独立 SSWT 配对重复

上图每个 trial 的参考/测量单扫光频 RMSE 与两次扫描差分 RMSE；下图同时显示 gauge 相位 RMS（左轴）与有效率（右轴）。

**研究问题：** 当误差由真实 CWT/SSWT/积分流程产生（而不是人工正交注入）时，是否也出现类似的差分规律？

**需要读取：** `results.sswt.reference_rmse_MHz`, `measurement_rmse_MHz`, `diff_rmse_MHz`, `gauge_rmse_rad`, `valid_fraction`, `failure_rate`。

**注意：** 真实独立 SSWT 两端的单扫 RMSE 不一定相等，不能与控制注入组直接宣称“同等条件下算法更好”。若出现失效/相位绕回，不能把其结果静默剔除后只报好的 trial。

## 最后：如何从图走向科研创新

1. **机理确认**：rho=1 共模抵消；rho<1 经多试次仍显著引起 gauge 相位；分量消融可解释影响。
2. **创新切入**：设计仅使用辅助 MZI 的信息、未应变静态参考区或无监督跨扫描约束的估计器，减少最有害的差分残差分量。
3. **下游真实任务**：用独立的非零应变 forward model 验证恢复的应变 RMSE、P95、失效率；不能停留在虚假应变 proxy。
4. **既有方案对照**：包含 SEFR 类双扫对齐、平滑 SSWT、传统相位方法、当前完整 NUFFT 处理链，避免把已经有人做过的“扫频非线性校正”当作创新。

**若 H1 在多散射随机重复后不成立，也应报告这一否证结果，调整假设而非人为选择有利随机种子。**
