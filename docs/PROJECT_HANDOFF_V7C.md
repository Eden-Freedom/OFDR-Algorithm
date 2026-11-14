# OFDR-Algorithm 项目交接与下一对话启动说明（截至 V7c smoke 失败）

> **建议新对话第一步先读这个文件，然后查看对应 MATLAB 源码。**
>
> 仓库：https://github.com/Eden-Freedom/OFDR-Algorithm
>
> 当前重大阻塞：**V7c 的 smoke_test_v7c 两个开发试次全失败（0/2）**。还没有 V7c 的性能结论，也**绝不应**先运行 V7c 的 100 次冻结测试。原始代码在试次内 catch 失败，只在末端触发 assert。本次已加入显式异常 ID、原因、堆栈报告的诊断补丁；请重新运行并提供日志。

## 1. 用户与协作方式

- 中文交流，用户正在系统学习 OFDR（光频域反射仪）的 SSWT（同步压缩小波变换）与 NUFFT（非均匀快速傅里叶变换），目的是**通过可复现 MATLAB 仿真寻找能够发表论文的科学问题与可验证算法改进**。
- 用户在 Windows 的 MATLAB 中从 GitHub 拉取代码，**助手负责**给出严谨实验设计、详细中文注释的 .m 代码、逐图解释文档、GitHub 版本管理；用户自行运行，并把图、日志回传。
- **分析风格**：先结论，再公式与物理含义，再数字证据与局限，区分“数学公式自检 / 仿真样本 / 多试次统计 / 真实硬件验证”；严格陈述是否是研究假设、还是已验证结论。不虚构 MATLAB 实机结果，不宣称已有论文创新性。
- 每次改动优先复用既有数值核，不破坏历史版本。配套 `docs/<VERSION>_EXPERIMENT_GUIDE.md` 和 `docs/<VERSION>_FIGURE_READING_GUIDE.md`，写明横纵轴、单位、对比方法、数据字段、实验可证伪性、失败条件。必要时增加 `PRE_REGISTERED_PROTOCOL`。
- 每个实验坚持：配对试次、以 trial 而不是像素为 bootstrap 单位、共同有效空间掩码、记录 valid fraction、失败率、随机种子；防止 oracle 真值信息进入真实算法拟合，防止把真实应变相位校正掉。
- 不要仅以光频 RMSE、峰宽或者单次复相位偏差评价应变算法；主指标是**真实非零应变 Core RMSE、未应变持出区虚假应变 RMS、Gauge 相位、有效位置比例和失败率**。
- 冻结盲测种子不能用于调参；任何受盲测结果影响的新算法需新增协议和新的外部测试种子。

## 2. 项目结构与历史结果

| 版本 | 已实现的内容 | 关键结果/地位 |
|---|---|---|
| V1 | 非线性 TLS、辅助 MZI 和主 OFDR 信号模型 | 原始未校准 FFT 峰展宽/错位 |
| V2 | 手写 STFT、Morlet CWT 与 SSWT 拍频估计和光频轨迹重建 | SSWT 光频轨迹 RMSE 约 1.710 MHz（当前模型；拍频 RMSE 不代表积累光频 RMSE） |
| V3 | 非均匀频率下 Gaussian gridding NUFFT | 真值坐标下 NUFFT vs 选定直接 NUDFT 比较，数值验证 |
| V4 | SSWT 轨迹接 NUFFT 复谱重构 | 光谱峰接近真值；单次复谱误差与真实应变误差不同 |
| V5 | 光频误差比例/残差传递与细距离网格 | 单峰功率 FWHM 粗 1.5955 mm，细 1.1781 mm；比例误差关系；固定位置单扫相位影响 |
| V6a | 零应变双扫描瑞利散射 | 独立 SSWT 残差产生非零 Gauge 相位与虚假应变代理；共模残差可相消 |
| V6b | 36 次配对相关性和误差分解 | ρ=0/0.5/0.9/1 时零应变代理均值 2.611/1.831/0.918/0 με；较强扫描间相关性通常对应更小的差分误差 |
| V6c | 物理非零应变（散射体位移+弹光相位）、双扫 NUFFT+Gauge 解调 | 5 με Oracle 恢复均值 5.0148 με，Core RMSE 0.0908 με；36 次 Core RMSE 平均 Oracle 0.1094 vs SSWT 0.2241 με |
| V6d | 36 次非零应变真值误差分量消融 | no_diff/ramp/nonlinear/full Core RMSE 0.2077/0.2132/0.2166/0.2240 με；静止区非仿射分量影响突出（真值分解仅诊断） |
| V7 | 静态上游参考段相位拟合 SAPC vs Static affine | 36 次配对 SAPC vs affine 平均 Core RMSE 改善 0.004816 με，CI95 [0.002056,0.007740]；26/36 胜 |
| V7b | 固定 V7 超参的 **100 次新种子盲测**，17 组物理条件预览 | SAPC vs affine Core 改善 0.003482 με，CI95 [0.001994,0.005146]；65/100 胜；持出静止区改善 0.006594 με，CI95 [0.003756,0.009199]；有效率变化 -0.010 个百分点；35 次退化 |
| V7c | 预先冻结的阻塞式空间 CV + 自适应 α 混合 SAPC | **实现已提交，但用户的 smoke_test_v7c 0/2，尚未验证任何性能** |

### V7b 17 条泛化预览（每个条件仅 12 次，不应过度推断）

SAPC 相比 Static affine 的 mean Core RMSE gain（με），gain>0 为改善：

- SNR 15/25/35 dB：+0.04934（11/12 有效）、−0.00248、−0.00069
- 静态段 [0.55,0.98] / [0.62,0.85] / [0.78,1.02] m：+0.00073 / −0.00157 / +0.00058
- 应变 0/1/5/10/20 με：+0.00367/+0.00303/+0.00684/+0.00394/+0.00227
- Gauge 5/10/20 mm：+0.01034/+0.00419/+0.00366
- TLS ripple 0.060/0.120/0.200：+0.00489/+0.00612/+0.00364

这些结果支持研究 **在何种条件下需要回退简单仿射校正**，但不证明已有可部署的可信度估计器。

## 3. 当前 V7c 的目标和限制

**研究问题**：在保证非零应变物理信号不被削弱的情况下，能否使用已知上游静止段内部的阻塞交叉验证和可辨识性门控，减少固定 SAPC 的退化风险，并且保持/提高 Core 与持出区精度？

- Reference 与 measurement 的**实际 TLS 光频轨迹相同**（这不等于已验证不同真实轨迹的频带失配场景）。
- 主探测噪声关闭；有固定的合成 Rayleigh 散射背景。
- 训练仅允许已知的上游静止段。受应变区、下游静止持出区以及真实光频只用于独立评价，不进入模型拟合。
- 基线：Raw SSWT、Smoothed SSWT、Static affine、Full SAPC、CV-SAPC，Oracle 作理想参照。
- 低维修正：`q_corrected = q_affine + alpha * (q_sapc - q_affine)`，`alpha∈[0,.25,.5,.75,1]`。
- V7c 协议 ID：`V7C_CV_SAPC_2026-11-13_B`。冻结的关键配置见 `matlab/v7c/config_v7c.m`、`matlab/v7c/v7c_assert_protocol.m`、`docs/V7C_PRE_REGISTERED_PROTOCOL.md`。
- V7c **目前没有运行成功的 MATLAB 样本**，不能得出“CV-SAPC优于 SAPC”的科研结论。

## 4. 紧急阻塞：V7c smoke 0/2

用户 MATLAB 原始输出：

```text
========== V7c | DEVELOPMENT =========
Successful 0/2 | failures 2 (100.00%) | non-affine accepted NaN%
V7c actual elapsed time 0.40s. Samples with failures remain in the denominator.
Restrictions: known static upstream, common physical TLS sweep, detector noise OFF.
Development and frozen testing must NEVER use the same sample seeds.
错误使用 assert
至少一个试次失败：检查 failure_reason
出错 smoke_test_v7c (第 10 行)
```

**诊断事实**：在 `v7c_run_trials` 中，内层 `try/catch` 把异常保存到了 `out.failure_id{t}`、`out.failure_reason{t}`。末尾的 `assert` 只是二次失败。当前无法在尚未拿到这两个字段前确定根因，不能猜测是算法本身或训练 mask。

为了让问题易于诊断，GitHub 已添加补丁：`smoke_test_v7c` 开启 verbose，在失败时列印试次 ID 和 Reason；`v7c_run_trials` 在 verbose 下输出 `getReport(ME,'extended','hyperlinks','off')`，包括 MATLAB 调用堆栈。

运行（仓库根目录）：

```matlab
!git switch main
!git pull --ff-only origin main
addpath('matlab/v7c')
clear smoke_test_v7c v7c_run_trials
rehash
smoke_test_v7c
```

或者**无需补丁**，手动读取真实失败：

```matlab
cfg=config_v7c();
cfg.v7c.development_repeats=2;
cfg.v7c.run_frozen_test=false;
cfg.v7c.run_conditions=false;
cfg.v7c.verbose=true;
cfg.v7c.make_plots=false;
[cfg,r]=main_v7c(cfg);
disp(r.development.failure_id);
disp(r.development.failure_reason);
```

之后把完整异常 ID、Reason、堆栈发给新的对话，先修复并保证两个开发 trial 成功，然后运行 24 次开发集。**在修复完成和协议明确锁定前，不准运行 100 次冻结测试。**

如果修改 V7c 数学核或门控规则，需明确说明旧冻结协议变更，并保留全新的独立测试种子；不可以在已看结果的测试集上反复挑参。

## 5. 下一阶段工作顺序（给新对话的明确 TODO）

1. **第一优先：排查上述 V7c 0/2 原始 MATLAB 异常**；检查文件依赖与索引形状、CV 掩码、训练样本有效性，但不要在没有日志时猜原因。
2. 修复最小触发错误，GitHub 提交补丁、修改 smoke test、提供增量 MATLAB 运行命令；代码注释中文，保留 V7b 的冻结历史结果。
3. 运行 V7c 两次 smoke 和 24 次开发集，出具多方法配对 Core / 持出区 / 有效率 / 失败率、fallback 分布和内 CV 误差。
4. 仅当开发模型固定且通过功能检查，使用全新的 100 次冻结种子验证 CV-SAPC **相对 Full SAPC 与 Static affine 的 paired Core RMSE gain 及 trial bootstrap CI95**，统计退化/最差退化与持出性能。
5. 如 V7c 不优于强基线，则调查可信度指标与真实泛化改进的关系；不能仅提高训练拟合程度/增加基函数就宣称有效。
6. 后续扩展真实 TLS 参考/测量扫频不同、辅助 SNR、已知静态段长度、主探测噪声、Rayleigh 衰落及公平文献对照；候选论文创新仍待验证。

## 6. 新对话推荐第一条消息（可直接复制）

请继续我在 GitHub 上的 OFDR SSWT+NUFFT 相位敏感应变算法项目：
https://github.com/Eden-Freedom/OFDR-Algorithm

你必须先阅读 docs/PROJECT_HANDOFF_V7C.md、matlab/v7c/smoke_test_v7c.m、matlab/v7c/v7c_run_trials.m 和 config_v7c.m，再以中文、科研复现导向的风格继续。当前项目从 V1 发展至 V7c：V7b 100 次新种子盲测支持 SAPC 相比 Static affine 的小幅增益（Core +0.003482 με，CI95 [0.001994,0.005146]），但有 35/100 次退化。V7c 尝试引入静止段阻塞 CV 和自适应回退。然而我的 MATLAB smoke_test_v7c 输出 Successful 0/2, failures 2，末尾 assert 错误。请先帮助定位每个试次的原始 failure_id、failure_reason 与堆栈并修复，不要直接进入盲测，也不要编造 MATLAB 结果。排错后提交 GitHub，提供完整中文注释 MATLAB 代码和逐图实验指南。我们长期目标是找到可发表、可以公平对照的相位保真 OFDR 应变校正创新点；请始终区分假设、仿真证据和已验证成果。
