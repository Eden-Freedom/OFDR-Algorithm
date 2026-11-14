# V7c Smoke Test 语法故障排查与复测记录（2026-11-13）

## 0. 本次状态

**已确认、已修复代码层面的语法错误；尚未取得 MATLAB 实机 smoke PASS 证据。** 该修复不改变 CV-SAPC 数学公式、模型超参数、随机种子、协议 ID、频率校正或应变评分定义。此处的“修复”仅指 GitHub 源代码中已知语法错误消除，不表示数值验证已经通过。

- 报错 ID：`MATLAB:m_improper_grouping`
- 根因位置：`matlab/v7c/v7c_run_trial.m`，原第 60 行
- 错误写法：`m=out.metrics{k];e=m.strain_error_microeps(core);`
- 修改后：`m=out.metrics{k};`；下一行 `e=m.strain_error_microeps(core);`
- 解释：`out.metrics` 是 cell，`{k}` 用于取出第 k 个方法的结果结构体。原代码的左花括号与右方括号不匹配。
- 错误调用栈：`smoke_test_v7c → main_v7c → v7c_run_trials → v7c_run_trial`。
- 两个开发 Trial 都在 MATLAB 解析阶段失败，原先的 0/2 **不是** CV-SAPC 的算法失效率，也不构成物理或统计结论。

## 1. 从本修复分支运行（仅开发阶段）

在 MATLAB 当前目录切换到本仓库根目录，先更新 Git 工作树（本地如有未提交修改，应先备份/提交，不要强制覆盖）：

```matlab
!git fetch origin
!git switch --track origin/fix/v7c-smoke-brace-20261113
% 如果本地已有同名分支，则使用：!git switch fix/v7c-smoke-brace-20261113
addpath('matlab/v7c');
which v7c_run_trial -all
clear v7c_run_trial v7c_run_trials smoke_test_v7c
rehash
smoke_test_v7c
```

注意：`which -all` 应以仓库的 `matlab/v7c/v7c_run_trial.m` 为准。如果 MATLAB 路径中有历史同名文件，先排查路径优先级，不能根据旧文件运行结果判断此次补丁。

**smoke 验收**：必须看到 2/2 成功、所有六方法 Core/Holdout 指标有限、`common_core_count >= 15`、`common_holdout_count >=15`、`valid_fraction(:,6)>0.2`、最终 `[V7c smoke] PASS`。2 次仅为功能自检，**不计算科研意义上的 CI 或性能证明**。

**如果仍失败**：保留 `failure_id`、`failure_reason` 和扩展堆栈，先查当前新错误；不得跳过 smoke 直接运行冻结测试。可用：

```matlab
cfg=config_v7c();
cfg.v7c.development_repeats=2;
cfg.v7c.run_frozen_test=false;
cfg.v7c.run_conditions=false;
cfg.v7c.make_plots=false;
cfg.v7c.save_results=false;
cfg.v7c.verbose=true;
[~,r]=main_v7c(cfg);
disp(r.development.failure_id);
disp(r.development.failure_reason);
```

## 2. 只有 smoke 通过后才运行开发集

```matlab
cfg=config_v7c();
cfg.v7c.development_repeats=24;
cfg.v7c.run_development=true;
cfg.v7c.run_frozen_test=false;
cfg.v7c.run_conditions=false;
cfg.v7c.verbose=true;
cfg.v7c.make_plots=true;
cfg.v7c.save_results=true;
[~,results]=main_v7c(cfg);
s=results.development.summary;
disp(s);
```

检查 `s.n_success/s.total`、`s.failure_rate`、`s.mean_core`、`s.mean_holdout`、`s.mean_valid`，以及 `s.comparisons(2)`（CV-SAPC vs affine）和 `s.comparisons(3)`（vs Full SAPC）的**配对 trial bootstrap CI95、胜负数、最坏退化**；同时核对 `s.selection_alpha_counts`、`s.fallback_rate`、`results.development.fallback_reason`、`results.development.cv_folds_ok`。

失败 trial 始终计入总试次分母。成功样本条件均值不能替代完整失败率。数据仅来自开发种子，不能宣称独立验证。

## 3. 三幅 MATLAB 图的判读提示

详细说明见 [V7C_FIGURE_READING_GUIDE.md](V7C_FIGURE_READING_GUIDE.md)。

- **Figure 1**：上图横轴为 Raw / affine / Full SAPC / CV-SAPC，纵轴为受应变 Core RMSE（με，越低越好）。下图横轴为相对 affine/full 的 Core 与下游静止 Holdout 配对比较，纵轴为 RMSE 改善（με），误差棒是 trial 级 bootstrap 95% CI；均值高于 0 但置信区间跨 0，不等于统计证实。检查有效率与失败率。
- **Figure 2**：上图横轴 affine Core RMSE、纵轴 CV-SAPC Core RMSE（με），点位于对角线下方表示该试次改善。下图横轴是静止训练段内部 CV 相位 RMS 改善百分比，纵轴是独立受应变 Core RMSE 改善（με），颜色为选择的 α。CV 改善未必预测 Core 改善。
- **Figure 3**：上图横轴为未正则化数据 Hessian 的倒数条件数，纵轴为相对 affine 的 Core 改善（με），颜色为 α；仅可作可辨识性关联诊断。下图横轴 α∈{0, .25, .5, .75, 1}，纵轴试次数；α=0 表示仍采用 affine 校正，**不是**不做校正。

## 4. 严格保持冻结边界

当前仍使用原 `V7C_CV_SAPC_2026-11-13_B` 协议。此次修复只改变 MATLAB 解析语法，不允许借此调整 α 网格、门限、训练区、保护带、正则化或测试种子。暂时**禁止**运行 `run_frozen_test=true` 的 100 次冻结测试，也不应因为过去看过 V7b 的结果而回头优化 V7b。

只有完成 2/2 smoke 与 24 次开发集、复核实现逻辑及冻结规则后，才能单独讨论是否进行 V7c 新种子盲测；若改变算法规则或见到冻结集后调整算法，必须升级协议并使用全新未接触的测试种子。

## 5. 证据等级

- **已证实**：GitHub 原文件有一个非法 `{k]` 索引符号；该语法错误能解释用户所见相同 failure ID 与堆栈。
- **已提交的修复**：修改为合法的 cell 索引 `{k}`。
- **未证实**：MATLAB 实机 smoke 通过、24 次开发集表现、门控可靠性、CV-SAPC 相对 Full SAPC 的改善，及任何论文创新性。
