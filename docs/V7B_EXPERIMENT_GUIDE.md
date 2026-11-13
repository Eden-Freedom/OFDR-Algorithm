# V7b 实验操作指南：冻结 SAPC 泛化与失效分析

**状态**：代码已实现，需 MATLAB R2020b+ 本地运行和反馈。V7b 的结果不可由 V7 的 36 次历史数据推定。

## 1. 研究问题

V7 (36 次、5 με) 的历史结果：Static affine RMSE 0.2189 με、SAPC 0.2140 με，二者的 trial 级配对差均值 **0.004816 με**，bootstrap CI95 **[0.002056, 0.007740] με**；26/36 次改善。这是**探索/开发数据**，SAPC 的参数已根据开发阶段确定，不可再次作为独立盲测。

V7b 检查：

1. 固定 V7 算法和前处理参数，在**新的 100 次完整散射+辅助噪声试次**上是否仍改善 Core 与未参与拟合的静止区？
2. 哪些试次 SAPC 比 affine 更差？与训练段条件数、拟合相位下降、校正量、散射有效率和校准差异有何关联？
3. 当 SNR、静态段、应变、gauge、扫频调制幅度发生变化时，这些结果是否稳定？

### 不能作为新算法有效性证据的情形

训练段相位误差下降**不是**应变测量改善；失败试次不能删掉；不能把零主噪声仿真说成实物 OFDR；也不能宣称不同试次的结果相互独立像素。

## 2. 核心代码入口

文件位于 `matlab/v7b/`：

- `config_v7b.m`：固定模型、全新独立种子与条件网格。
- `v7b_assert_frozen.m`：阻止私自修改正则、步长、基函数、滤波窗等盲测参数。
- `main_v7b.m`：实验入口及保存。
- `v7b_run_trials.m`：复用 `run_v7_trial`，**V7 的优化/重构代码没有被改写**。
- `v7b_summarize.m`：trial 单位的配对 bootstrap、胜负和最大退化。
- `v7b_failure_diagnostics.m`：post-hoc 诊断，不能反馈调本次盲测参数。
- `v7b_run_conditions.m`：预先定义的物理条件矩阵。
- `v7b_export_csv.m`：每个 trial 的种子、成功/失败、完整输出和诊断。
- `v7b_plot_results.m`：3 张盲测图，条件扫描开启后第4张。
- `smoke_test_v7b.m`：冻结、随机种子、诊断输出的完整链路自检。

V7 的 `run_v7_trial.m` **只额外返回诊断字段**（如 `sapc_hessian_rcond`、`sapc_train_count` 和 `sapc_correction_peak_MHz`），无优化器数学逻辑改变。

## 3. 运行顺序

在仓库根目录：

```matlab
!git switch main
!git pull --ff-only origin main
addpath('matlab/v7b');
smoke_test_v7b;

% 主测试：冻结参数 + 100 次全新种子（首次可以设置为10次仅做技术预览）
cfg = config_v7b();
[cfg, results] = main_v7b(cfg);
```

注意首次技术预览和正式盲测的区别：

```matlab
% 技术预览（不得用于论文结论）
cfg = config_v7b();
cfg.v7b.blind_repeats = 10;
cfg.v7b.save_results = false;
cfg.v7b.make_plots = false;
[cfg, preview] = main_v7b(cfg);

% 正式：全部固定，独立运行100次，之后不准以这批数据调参
cfg = config_v7b();
[cfg, results] = main_v7b(cfg);
```

所有正式试次使用独立于 V7 历史的种子空间：散射以 10010001 为基点，参考辅助以 20010001 为基点，测量辅助以 30010001 为基点；stride 分别 149、163。随机源被 V6/V7 `rng(seed,'twister')` 明确控制。完整列表存 CSV。

> 严格学术意义上，开发人员可以看到本地仿真模型的代码，所以这里的「盲测」指**预先冻结参数并使用未参与开发的随机试次**，不是第三方双盲或外部实测验证。

## 4. 需要阅读的关键指标

```matlab
s = results.blind.summary;
s.n_success
s.failures
s.comparisons(2).core_gain_mean         % affine 减 SAPC，>0 为改进，单位 με
s.comparisons(2).core_gain_CI95
s.comparisons(2).holdout_gain_mean      % 下游持出静止区改善，单位 με
s.comparisons(2).holdout_gain_CI95
s.comparisons(2).valid_gain_fraction_mean
s.comparisons(2).win_rate
s.comparisons(2).worst_regression

d = results.blind_diagnostics;
d.worse_indices                         % SAPC 相对 affine 退化的试次编号
d.predictors                            % 按顺序列出事后诊断量
d.better_mean                           % 改善试次的诊断均值
d.worse_mean                            % 退化试次的诊断均值
```

**主要判定**：SAPC vs affine 在未参与开发的 100 次试次中，Core 配对 CI95 下界 > 0；下游持出区 CI95 下界 > 0；有效率平均下降不超过预注册阈值 **0.5 个百分点**。还必须报告 SAPC 退化比例、最差退化和失败率，不能只报告均值。

此门槛是**研究评价标准**，不是可发表性保证；当某个条件不满足时，应认定目前未通过，而不是更换阈值。

### 失败与删失

`results.blind.success` 每一行对应一个试次；`failure_id`、`failure_reason` 保存错误类型和原始信息。`summary.failures` 始终以全部请求次数为分母，只有成功的配对试次参与均值和 CI；必须同时报告失败率，避免幸存者偏差。

## 5. 条件泛化实验（单独执行）

```matlab
cfg = config_v7b();
cfg.v7b.run_blind = false;          % 不重复已经完成的100次盲测
cfg.v7b.run_conditions = true;
cfg.v7b.condition_repeats = 12;    % 仅预览；正式每条件 >= 30
[cfg, resultConditions] = main_v7b(cfg);
```

条件包括：辅助 MZI SNR = 15/25/35 dB、上游静态训练段位置/长度 3 组、真实施加应变 = 0/1/5/10/20 με、gauge=5/10/20 mm、TLS 扫频波动幅度 `ripple_a`=0.06/0.12/0.20。共 **17 组**；组内方法共享相同散射和噪声试次，**组间使用不同种子**，因此不是跨条件的完美配对实验。结果应按每组单独报告。

特别限制：每次条件组的参考与测量扫描仍共用**同一条真实 TLS 轨迹**，改变 `ripple_a` 只测试不同绝对非线性程度，**尚未测试两个扫描具有不同真实 TLS 轨迹或频带错配**。这必须在后续版本再做，不能暗示已验证。

可单独修改 `cfg.v7b.condition_repeats = 30`，但不能修改冻结的算法参数。若需要验证独立真实扫描轨迹，应开发新的物理前向模型与配准基线。

## 6. 输出目录与字段

默认 `matlab/v7b/output/`：

- `V7b_frozen_results.mat`：保存 `cfg` 和 `results`，包含全部失败原因；
- `V7b_blind_trial_data.csv`：每试次的种子、Core/holdout/valid、Hessian rcond、训练点数、系数幅度等；
- `V7b_condition_XX.csv`、`V7b_condition_summary.csv`：泛化条件试次级与汇总数据；
- `figures/v7b_figure1_blind_comparison.png` 等：可视化。

所有图阅读方法见 [V7B_FIGURE_READING_GUIDE.md](V7B_FIGURE_READING_GUIDE.md)。统计 CI 使用整个 trial 作为 bootstrap 单位，未对相邻 gauge 位置做错误的独立重采样。

## 7. 实验结束后该做什么

- 若 SAPC 只有训练段改善、持出区不改善或有明显退化，应优先分析可辨识性和过拟合，不得立刻增加基函数追求高训练精度。
- 若 100 次独立种子上可重复胜过 affine，并在至少一组物理变化下仍成立，才考虑 V7c 的新约束方法/可信度门控；**新方法开发后须使用另一套全新随机试次**。
- 需要与已有扫频双扫描配准、相位预测、静态参考标定方法比较，并加入主干涉噪声与实测数据，才能进一步评价研究的论文竞争力。
