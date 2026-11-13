# V7c MATLAB 运行指南：CV-SAPC 自适应可信度门控

## 研究目的

V7b 的 100 次冻结试验表明固定 SAPC 相对 Static affine 的平均 Core 改善约 0.003482 με（95% CI [0.001994,0.005146]），但 **35/100 次退化**。V7c 检查**上游静态段内部的跨空间区块相位一致性是否能帮助拒绝过校正**，而不是进一步增加多项式或正弦阶数。

**路径**：`matlab/v7c`。沿用 V1–V7b 的数学核，V7c 新增独立模型选择、配对评分与图表；不会覆盖 V7/V7b 结果文件。

## 运行顺序

MATLAB 当前目录设置为仓库根目录，然后：

```matlab
addpath('matlab/v7c');
smoke_test_v7c;

% 第一阶段：24 次开发集（默认，不是盲测）
cfg = config_v7c();
[cfg, dev] = main_v7c(cfg);

% 第二阶段：冻结规则及开发自检确认后，才执行完全不同种子的100次测试
cfg = config_v7c();
cfg.v7c.run_development = false;
cfg.v7c.run_frozen_test = true;
[cfg, test] = main_v7c(cfg);

% 第三阶段：17组物理条件预览（独立组种子；不要用作测试集调参）
cfg = config_v7c();
cfg.v7c.run_development = false;
cfg.v7c.run_conditions = true;
[cfg, cond] = main_v7c(cfg);
```

100 次测试预计比 V7b 慢，因为额外执行 2 折 × 2 基线的子集拟合与多个验证坐标 NUFFT。仅保存已完成的结果，不会异步执行任务。

## 算法主要步骤

1. 与 V7 同一条真值物理光纤和两次辅助 MZI，得到参考 SSWT、测量 SSWT；分别重构 Oracle（只评分）、raw、smooth、affine、full SAPC。
2. 从已知上游静态段切成固定的两块验证区，其余区拟合该折的 affine 和 SAPC，**25 mm 保护带**保证 gauge 起点中点不重叠。
3. 将每折拟合系数施加到原始光频坐标，计算验证 gauge 相位 RMS，比较 α∈{0,.25,.5,.75,1}。
4. 如果交叉验证改进量、Jacobian 满秩、数据 Hessian 条件数和新增修正幅度同时通过预注册门槛，则用相同 α 混合**完整训练段**的 affine/SAPC 校正；否则只用 affine。
5. 在受应变 Core 区和下游静止持出区按与 V7 一样的 gauge、相位平均及**六方法共同掩码**评分。所有失败都在 CSV 中保留。

**绝不**使用参考/测量的真实光频轨迹、真实应变值、受应变区或下游持出区的相位来选择 α。`truth` 对象作为既有物理距离网格/NUFFT 参考模型参数传入，并在 Oracle 组用于最终评分；门控逻辑不访问 `truth.nu_offset_Hz`。

## 主要结果字段

```matlab
% 使用 test（冻结测试的 main_v7c 返回值）
s = test.frozen_test.summary;
s.mean_core                   % 顺序：oracle,raw,smoothed,affine,fullSAPC,CV-SAPC
s.mean_holdout                % 六方法下游静态区 RMS
s.mean_valid                  % 六方法有效位置比例
s.comparisons(2).core_gain_mean      % CV-SAPC vs affine
s.comparisons(2).core_gain_CI95
s.comparisons(2).holdout_gain_CI95
s.comparisons(2).wins
s.comparisons(2).losses
s.comparisons(2).worst_regression
s.comparisons(3).core_gain_CI95      % CV-SAPC vs full SAPC
s.selection_alpha_counts             % α=0,0.25,0.5,0.75,1 的人数
s.fallback_rate
r = test.frozen_test;
r.cv_gain_fraction;
r.data_hessian_rcond;
r.extra_peak_MHz;
r.fallback_reason;
```

输出文件：`matlab/v7c/output/V7c_development_results.mat`、`V7c_frozen_test_results.mat`、`V7c_conditions_results.mat`（按运行模式分别保存）、`V7c_DEVELOPMENT_trials.csv`、`V7c_FROZEN_TEST_trials.csv`、`V7c_conditions.csv` 等。**注意：在同一种模式重复运行仍会覆盖对应 MAT/CSV**；应在每轮结果出炉后复制并归档、记录 Git commit SHA 和参数协议。

## 已知限制与实验安全边界

- 基于先验已知的上游静止参考段；其可用性在实际分布式应变传感中并不总有保证。
- 真实参考与测量 TLS 轨迹相同，主探测噪声关闭；现有结果不能宣称已覆盖双扫描真实光频跨度不一致。
- 若低 SNR 下大量试次失败，必须记录失败比例；不得只比较成功样本条件均值。
- 内部 CV 只反映静态段内的相关空间样本，不能保证在受应变区域泛化。若观察到测试退化，必须如实归档。
- 本地必须先通过 `smoke_test_v7c`；本仓库没有 MATLAB 运行环境，静态检查不能替代 MATLAB 运行结果。
