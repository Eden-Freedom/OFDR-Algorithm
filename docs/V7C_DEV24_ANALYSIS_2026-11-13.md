# V7c 24 次开发集：实机统计、逐图判读及下一步诊断

> 数据来源：用户在 Windows MATLAB 上执行的 24 次开发集；已提供三张 MATLAB 截图和完整命令行日志。此文为 **开发集事后研究记录，不是冻结验证**。GitHub 端未执行 MATLAB。保持 V7C_CV_SAPC_2026-11-13_B 协议和种子不变。

## 一、实验结果与科研结论

- 全部试次成功：24/24；本次程序失败率 0/24（不表示真实总体失败率=0）。
- 非仿射接受 11/24 (45.83%)；回退 affine 13/24 (54.17%)。
- alpha=[0,.25,.5,.75,1] 对应 [13,0,2,1,8]，仅 3 次部分混合，其余 21 次等效于纯 affine 或 full SAPC。
- 上述 24 次包含先前 smoke 的 2 个开发种子，统计分母是 24 而非 26。
- 预注册的两个关键目标都未满足：相对 affine 的 Core 与 Holdout 成对 bootstrap CI95 均跨 0；相对 full SAPC 的平均增益为负且 CI95 跨 0。不能声称 CV-SAPC 有已证实的泛化优越性，也不能证明其总体必然更差。

### 六方法平均误差（单位：με）

| 算法 | Core RMSE | 下游 Holdout RMS |
|---|---:|---:|
| Oracle（仅用于评分） | 0.11231 | 0.01190 |
| Raw SSWT | 0.22599 | 0.28687 |
| Smoothed SSWT | 0.36734 | 0.50930 |
| Static affine | 0.22096 | 0.27749 |
| Full SAPC | 0.21852 | 0.27413 |
| CV-SAPC | 0.21939 | 0.27668 |

平均六方法 Gauge 有效率：[0.9088, 0.9008, 0.8963, 0.9008, 0.9008, 0.9009]。CV 相比 affine 的有效率变化 +7.5723e-05，即 +0.00757 **百分点**，在预注册的损失上限以内。

### 配对统计（gain > 0 代表 CV-SAPC 更好；单位：με）

| 对照 | Core gain mean | Core CI95 | Core 胜/负/平 | Holdout gain mean | Holdout CI95 |
|---|---:|---|---|---:|---|
| vs Raw SSWT | +0.006600 | [+0.002649,+0.011541] | 18/6/0 | +0.010189 | [+0.003386,+0.018863] |
| vs Static affine | +0.001571 | [-0.000195,+0.004311] | 5/6/13 | +0.000813 | [-0.001671,+0.003220] |
| vs Full SAPC | -0.000867 | [-0.004533,+0.002197] | 9/7/8 | -0.002554 | [-0.012393,+0.003836] |

95% CI 为基于 trial 的 2000 次 bootstrap，非像素级 bootstrap。24 次来自同一预设物理条件，不可据此说明真实硬件场景或其他参数条件的泛化。

## 二、三张 MATLAB 图的科研判读

### Figure 1
上图横轴 Raw SSWT、Static affine、Full SAPC、CV-SAPC，纵轴为非零应变 Core RMSE（με，越低越好）。Full SAPC 与 CV-SAPC 接近；上图不显示 Oracle 和 Smoothed SSWT。下图横轴依次为 Core vs affine、Core vs SAPC、Holdout vs affine、Holdout vs SAPC，纵轴为 CV 相对基线的配对 RMS 改善（με）；误差条为 trial bootstrap CI95。四个区间全部跨零，因此不符合事先冻结的双指标成功判据。不能只看均值柱高。

### Figure 2
上图横轴 affine Core RMSE（με），纵轴 CV-SAPC Core RMSE（με），点在 y=x 以下才表示 CV 试次改善。5 胜/6 负/13 平；13 个平局对应 alpha=0 的回退。11 个非仿射接受试次相对 affine 为 5 胜/6 负，故接受门控不保证 Core 获益。下图横轴是上游阻塞式 CV 的**最佳候选**相位 RMS 减少（%），纵轴是独立评分 Core gain vs affine（με），颜色代表 alpha。多个内部 CV 正改善点的实际 Core gain 为负，说明上游验证相位分数并非完美的应变区收益代理；约 19% CV gain 对应一处较大的正 Core gain，可能影响均值。注意横轴不一定代表最终采用 alpha 的性能（门控可能拒绝候选而回退）。

### Figure 3
上图横轴是未正则化 data Hessian 的 rcond（标有 ×10^-4），纵轴为 Core gain vs affine（με），颜色为 alpha。可见约 0.8–2.1×10^-4，多数高于预注册最小 rcond 3e-5；用户门控理由没有 Hessian/rank 回退。不能从此图推断条件数与实际应变误差有因果关联。下图横轴 alpha=[0,.25,.5,.75,1]，纵轴计数=[13,0,2,1,8]。alpha=0 表示使用 affine，不是未校正；alpha=1 等于 Full SAPC。

## 三、风险：极端试次与门控错误

- CV vs Full SAPC Core 平均 gain=-0.00086688 με；24 次合计约 -0.020805 με。
- 单次最坏退化 0.033498 με。
- **仅做敏感性分析**：如果暂时从均值中排除这个最坏试次，则剩余 23 次的均值约 +0.000552 με，符号反转；不能将此值用作主结果，更不可以删除试次。
- CV vs affine 5 胜、6 负、13 平，证明回退机制确实工作，但非仿射接受时不一定带来真实应变 Core 精度提升。
- 回退理由：CV accepted non-affine blend 11 次；CV selected affine 7 次；CV gain below predeclared trust threshold 5 次；non-affine correction size gate 1 次。

## 四、代码实现审计事项（未对冻结算法做修改）

已读取 v7c_cv_gate.m、v7c_fit_subset.m、v7c_run_trial.m、v6_reconstruct_trace.m 和 v7_static_phase_fit.m：

1. 校正器没有显式把 truth.nu_offset_Hz 用于 alpha 选择或模型拟合，受应变 Core 和下游 Holdout 的相位用于评分而非门控。
2. v6_reconstruct_trace.m 使用 truth.delta_nu_Hz 来确定空间距离网格。已进一步检查 simulate_laser_sweep.m 与 config_v1.m：**在当前固定合成模型中**，该带宽完全由预先配置的波长端点 lambda_start_m / lambda_end_m 与光速计算得到，不是由随机扫频残差估计出来；因此本次不能直接将其认定为 Oracle 泄漏。不过函数接口仍直接接收 truth，未来若考虑未知真实频带端点或双扫描带宽变化，就必须改成由独立可观测的标称参数构建距离网格，并进行信息流审计。当前尚不能宣称在所有扩展实验条件下均实现零泄漏。
3. v7c_cv_gate.m 和 v7c_fit_subset.m 的幅度阈值使用整个上游静止段（包括每折 CV 留出块）的幅度中位数。这不是直接使用验证相位标签，但意味着 CV 的样本有效性标准含有留出子段的信息；若论文要称严格的训练/验证隔离，则应审查这一转导式信息共享。
4. 25mm 的空间保护带不能消除同一 Rayleigh 场与全局 NUFFT 响应带来的样本关联。不能把 spatial blocked CV 等同独立测试集。

上述审计点不应在不变更协议的情况下偷偷改代码。若要调整算法或物理先验，需另建 V7d 协议和全新未接触的种子。

## 五、只读取现有 24 次 MAT，定位最差试次

新增 matlab/v7c/v7c_diagnose_development.m。只进行事后配对诊断，不重新运行模拟、也不触碰冻结测试。

    !git pull --ff-only
    addpath('matlab/v7c');
    [T,d] = v7c_diagnose_development();  % 自动载入 V7c_development_results.mat
    disp(T(T.trial == d.worst_vs_sapc_trial,:));
    writetable(T, fullfile('matlab','v7c','output','V7c_DEV24_DIAGNOSTICS.csv'));

也可使用现有内存中的 results 调用 [T,d]=v7c_diagnose_development(results)；不要读取冻结测试字段。重点查看最坏退化 trial 的 alpha、gate_reason、cv_gain_fraction、data_hessian_rcond、Core/Holdout 增益和有效率；参考留一敏感性输出，但完整 trial 结果必须保留。

## 六、阶段性决策

本开发集达成了功能验证，但未给出优于强基线的性能证据；暂不执行 V7c 的 100 次冻结测试。先完成离线逐试次诊断和物理输入审计，再决定是否（A）按原固定协议独立验证可能为阴性结果的 V7c，或者（B）归档 V7c 并提出带有独立新开发与冻结种子的 V7d。不得在已经查看的测试集反复挑选门控参数。
