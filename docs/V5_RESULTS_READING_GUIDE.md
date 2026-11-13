# V5 图像阅读与结果判读指南（论文导向）

> 配套代码：[matlab/v5](../matlab/v5)；实验源方案：[V5_CALIBRATION_ERROR_PROPAGATION_PLAN.md](V5_CALIBRATION_ERROR_PROPAGATION_PLAN.md)。
> 本文依照用户于 2026-11-13 提供的 **V5 MATLAB 实际运行图像和控制台输出**。图中近似读数不是源码自动导出的精确统计量。

## 0. 开始之前：三类量不可以混为一谈

1. **光频坐标误差**：e_q(t)=q_hat(t)-q_true(t)，单位 MHz；其均值、比例斜率、非仿射残差具有不同的物理效应。
2. **单次重建相位误差**：与理想坐标参考相比，在固定物理距离处的复响应相位差，单位 rad。V5 Figure E 当前属于此类。
3. **应变解调相位误差**：**参考扫描与测量扫描之间**的相位差，再做空间 gauge-length 差分，最后换算微应变。V5 尚未建立此类量。

因此“Figure E 有 −1 rad 相位误差”**不能**直接读成“应变测量产生 −1 rad 的误差”；需要先仿真两次扫描及实际应变解调器。

## 1. 每张图的速读表

| 图 | 横坐标 | 纵坐标 | 必须比较 | 当前观察 | 不能得出 |
|---|---|---|---|---|---|
| Figure A | Distance (mm) | 相对于**真实参考峰**归一化的复谱幅值 | 真值坐标黑线 vs SSWT 坐标绿线；粗/细 FWHM | 曲线接近重合；粗 1.5955 mm → 细 1.1781 mm | 不能把粗网格差异归因于 SSWT |
| Figure D | 注入比例误差 ε (ppm) | 相对理想重建峰的增量位移 (mm) | 不同距离彩线 vs 黑色点线理论 −εz | 77/77 通过；误差随距离增大 | 不代表相位或应变精度 |
| Figure E-上 | SSWT 残差倍率 γ | 幅度谱相对 L2 | γ=0/1/2/4/8，是否单调退化 | γ=8 约 0.16，近似增长 | 不代表应变相位已经验证 |
| Figure E-中 | γ | 固定真实位置的相位差 (rad) | γ 增大后偏差是否线性；fixed/full 两支 | γ=8 约 −1 rad | **不是参考-测量双扫描相位差** |
| Figure E-下 | γ | 相对理想单峰 FWHM 变化 (%) | 是否超过量化/收敛误差 | γ=8 约 −0.03%，几乎不变 | 小的负值不是“分辨率提高” |
| Figure B | 扫频时间 (ms) | 光频坐标误差 (MHz) | 原始 SSWT 残差 vs 加权仿射拟合 | 用于诊断平均分量/比例分量/残差 | 不能只凭曲线直接解释应变 |

旧版 Figure D 没有标出七条颜色各代表哪个距离。**本次绘图更新已为七个距离添加图例**，实线为仿真、同色点线为理论；准确数值仍应从 results.B_scale.distances_m 与 scale_ppm 等结果数组读取。

## 2. Figure A — 测量仪器（数值网格）先要可靠

**研究问题：** 细网格是否足以测量小于 0.1 mm 的峰位置/峰宽变化？

- 模型：无噪声 1.25 m 单反射点，光频 Hann 窗、Voronoi 密度权重。
- 横坐标：1246–1254 mm；纵坐标：幅值除以真值坐标参考峰的峰值。由于使用同一个参考峰归一化，**可以比较峰高差异**；但肉眼重合不能排除小的相位误差。
- 粗网格功率 FWHM = **1.5955 mm**；0.02 mm 和 0.01 mm 细距离网格 FWHM 均约 **1.1781 mm**。
- 两个细网格的 FWHM 差仅 **0.0438 μm**。细网格解决的是**测量分辨/插值偏差**，不是提高光学系统的物理分辨率。
- NUFFT 与直接 NUDFT 的全谱相对 L2 误差 = **3.535×10^-5**，是重构数值近似底限的一个测量。

**操作：** 对比 results.A.coarse_metrics.fwhm_m、results.A.reference_fwhm_m、results.A.sswt_fwhm_m、results.A.fwhm_convergence_m、results.A.nufft_vs_nudft_full_relative_l2。发表前还需检查单峰在更复杂错误形状和噪声条件下是否仍稳定，必要时增加拟合/收敛测试。

## 3. Figure D — 先验证比例误差的可预测性

**横坐标：** ε，光频比例误差（ppm，1 ppm=10^-6）。**纵坐标：** 峰位置相对真值坐标重建的**增量**（mm）。

模型：
$$
\widehat q=(1+\epsilon)q,\quad z_{\rm estimated}\approx\frac{z}{1+\epsilon},\quad
\Delta z\approx-\epsilon z.
$$

- ε>0 → 估计距离偏小；ε<0 → 估计距离偏大。
- 反射点越远，同样 ppm 造成的绝对定位偏差越大。
- 你输出的 77/77 表示七个距离乘以十一个比例档的坐标有效性全部通过。
- 最大理论与数值偏差 **10 μm**；主要需要与局部峰搜索所用的 **0.02 mm 细网格步长**比较：半格是 10 μm。不能据此声称解析模型存在10 μm物理偏差。

**必读字段：**
- results.B_scale.distances_m (m)
- results.B_scale.scale_ppm (ppm)
- results.B_scale.predicted_offset_m、results.B_scale.incremental_error_m (m)
- results.B_scale.valid 与 failure_reason

**科学结论范围：** 这验证了已知的光频刻度—距离刻度关系，是后续算法测距正确性的控制实验，**不是独立创新点**。

## 4. Figure E — 最值得延伸的研究线索

实验按
$$
\widehat q_\gamma=q_{\rm true}+\gamma\,(q_{\rm SSWT}-q_{\rm true})
$$
改变送入重构的坐标，保持**真实主干涉信号不变**。

- **上图：幅度谱相对 L2**：对完整相位/幅度谱的幅值逐点比较。γ=8 约0.16；γ=0 为理想基准。重点看是否存在非线性拐点和失效门槛，而不是只关注数值越小越好。
- **中图：固定距离处相位差**：γ=8 约−1 rad；说明坐标残差引发了可观的复数响应相位变化。当前值来自 run_B_residual_scale_v5 的 **full** 分支，使用估计坐标重算窗与密度权重，属于综合处理效应；**不是应变差分相位**。
- **下图：功率 FWHM 相对增长**：γ=8 约 −0.03%；远小于相位变化的视觉尺度。负号表示极小的收窄测量值，不表示校准可以提高物理带宽分辨率；需继续确认网格收敛。

**必须同时读** results.B_residual.metrics_full 与 metrics_fixed 两组：前者估计坐标同时改变核相位、Hann 窗和 Voronoi 权重，后者固定真值窗和权重，只更改傅里叶核坐标。固定权重是机制验证的 **oracle 实验**，不能充当可部署校正算法。

关键字段：
- results.B_residual.gamma
- results.B_residual.estimated_rmse_MHz
- results.B_residual.metrics_full{i}.full_magnitude_relative_l2
- results.B_residual.metrics_full{i}.fixed_location_phase_delta_rad
- results.B_residual.metrics_full{i}.fwhm_growth
- results.B_residual.metrics_fixed{i}
- results.B_residual.valid / failure_reason
- results.B_residual.weighted_theory_ratio / actual_fixed_ratio

**要进一步追问：** 固定权重的复响应比是否服从
$$
\frac{\widehat R(z)}{R_{\rm true}(z)}
\approx\left\langle\exp\!\left[-i\frac{4\pi n_gz}{c}e_q\right]\right\rangle_w ?
$$
若不服从，需要区分负频率泄漏、频率坐标非线性、有限窗、配准/位置变化等原因。

## 5. Figure B 和日志中的 0.819 Hz

当前 MATLAB 输出：
- **SSWT 拍频平均偏差**：约 0.819 Hz（需区分全程与中央90%统计）。
- **累计光频误差末端**：约 2.0357 MHz。

辅助 MZI 模型给出：
$$
e_q(T)=\frac{1}{\tau_a}\int_0^T e_f(t)\,dt.
$$

若仅有持续 0.819 Hz 偏差、T=20 ms、τ_a=8 ns，预计末端约为 **2.05 MHz**，与 2.0357 MHz 同量级。真实偏差并非常数，且扫描最后一个样本略早于20 ms，所以两者不必完全相同。

**必须看**：
- results.D.baseline.q_error_Hz：完整光频误差。
- results.D.baseline.q_decomposition：加权平均偏差、比例斜率（ppm）、去仿射残差。
- 相关拍频累计积分、首端/中段/末端积分贡献。

**注意**：光频的“首样本锚定前绝对常数偏置”会被坐标接口去掉；但起点为零、后来积累到近2 MHz 的误差**不能**按这种方式消除。

## 6. 目前数据真正支持、尚不能支持的论断

| 可以写进实验记录 | 现在不能写成论文结论 |
|---|---|
| P0：细网格显著修正了粗网格的 FWHM 估计 | SSWT 已达到理论最优空间分辨率 |
| P1：比例坐标误差造成距离尺度误差，符合 εz 规律 | 这条已知公式本身是创新 |
| P1：当前残差倍率提高会明显改变固定位置相位 | 实际应变精度按相同比例下降 |
| V5：在固定本次信号/模型下，峰宽对残差倍率不敏感 | 任意 OFDR/任意噪声下峰宽都不敏感 |
| V2/V4：SSWT 与 NUFFT 已实现很好的幅度谱重构 | 单一扫频的复相位误差就是虚假应变 |

## 7. 今后每个图必须配的“科研阅读说明”模板

任何新增实验图必须在对应 MD 中写出：

1. **研究问题/假设**：本图要证实或推翻什么？
2. **横/纵轴及单位**，控制变量与真正改变的变量。
3. **图例与基线**：真实坐标、估计坐标、单扫描或双扫描、固定或重算权重。
4. **对应公式与数据字段**：哪一列是准确的统计数值，哪些只是图像近似？
5. **预期趋势与失败判据**：如果不符合理论，优先排查什么？
6. **允许的结论与不允许的结论**：切忌跨越物理量。
7. **与论文创新点的联系**：只是基础验证、暴露问题、机理证据，还是验证新方法？
8. **复现命令及输出路径**：参数、随机种子、.mat/CSV 文件。
9. **统计量与不确定度**：样本数量、重复次数、置信区间、失败率、网格误差底限。

对所有图片建议在 MATLAB 绘图中同时做到：**图例标出距离与误差大小、真实参考/实验组颜色固定、数值指标直接写在标题或字幕、不同物理量不拼在同一坐标轴**。

## 8. 复现命令

在仓库根目录：

    addpath('matlab/v5');
    [cfg,ctx,results] = main_v5();

选取直接结果：

    fprintf('Fine FWHM = %.6f mm\n',results.A.reference_fwhm_m*1e3);
    fprintf('Grid convergence = %.4f um\n',results.A.fwhm_convergence_m*1e6);
    fprintf('Scale scan valid = %d/%d\n',results.B_scale.valid_count,numel(results.B_scale.valid));

默认保存在 matlab/v5/output/V5_baseline_P0_P1.mat，CSV 汇总在相同 output 目录；不能只保存 PNG。

**下一阶段应当转向真正的双扫描相位差与应变 RMSE；详细研究假设见 [PHASE_STRAIN_RESEARCH_ROADMAP.md](PHASE_STRAIN_RESEARCH_ROADMAP.md)。**
