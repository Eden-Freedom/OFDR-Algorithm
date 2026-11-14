# P2b 第一轮 MATLAB 实机 Smoke 验收（2026-11-14）

> 用户在 `research/p2b-common-sensitivity-20261114` 分支上的真实 MATLAB 日志。**本文件只是2个预设开发试次的功能/机制初查，不是正式12次开发统计、冻结盲测或论文创新验证。** 这里无算法参数、种子或物理模型的变更。

## 一、验证状态

- `which main_p2b -all` 和 `which p2b_run_trial -all` 均解析到 `matlab/mechanism_p2b/` 正确文件。
- `[P2b math unit] PASS`：方向导数、平方误差、协议锁、冻结锁。
- `[P2b summary unit] PASS`：完整trial配对、CI、符号、失败分母与零成功分支。
- P2b端到端 `Successful 2/2, failures 0 (0.00%)`；`[P2b smoke] PASS`，并未运行冻结测试。
- 开发2次共同有效ROI均值89.10%；平均共同Core Gauge 501.5；共模光频误差RMS均值0.980015 MHz。
- 零应变 `g_RMS=0`，α=.5和1的C实际与预测均为0，体现相同主波形+相同坐标的数学不变量（不代表仪器零噪声）。

## 二、用户实际数值（两个开发试次的均值）

单位：`C_actual`、`C_pred`、`MAE`、`gain` 是 `(με)^2`；`g_RMS` 是 `με/α`。α均未参与求导（导数来自±0.05）。

| 应变(με) | α | 实际 C | 预测 C | 模型 MAE | 零效应预测 MAE | 相对零预测的配对MAE gain |
|---:|---:|---:|---:|---:|---:|---:|
| 0 | .5 | 0 | 0 | 0 | 0 | 0 |
| 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| 1 | .5 | .00157707 | .00157360 | .00000346411 | .00157707 | .00157360 |
| 1 | 1 | .00625198 | .00622006 | .0000319182 | .00625198 | .00622006 |
| 5 | .5 | .00261473 | .00261712 | .0000122793 | .00261473 | .00260245 |
| 5 | 1 | .01294920 | .01294950 | .000125474 | .01294920 | .01282370 |
| 10 | .5 | .00132077 | .00131411 | .00000872745 | **.00230928** | .00230055 |
| 10 | 1 | .01035630 | .01034360 | .0000700538 | .01035630 | .01028630 |

**关键提醒**：10με、α=.5 的 `mean C_actual` 为0.00132077，`mean |C_actual|` 为0.00230928，二者不同意味着至少有一个trial的C为负。不可将“均值正”误读为“每个trial正”。该设置的符号一致率报告为2/2，表示模型与实际各自的试次符号一致，不代表实际C全部正。

**预设首要结局（5με、α=1）**：两次开发试次的 `C_actual` 平均0.0129492、`C_pred` 平均0.0129495；`model MAE=0.000125474`，相对空预测 `C=0` 的 `MAE=0.0129492`，平均配对收益0.0128237；模型优于零基线2/2、符号一致2/2。**n=2非常少，任何CI都是极不稳定的两点重复抽样结果，不作显著性或泛化解释。** 均值十分接近不等于各trial都无误差，必须保留MAE。

导数诊断（应变0、1、5、10με）：`g_RMS=[0,0.078016,0.12411,0.12378]` με/α；由h=.05和.10所得导数差RMS分别为`[0,0.00025694,0.00026969,0.00022645]` με/α。只有2次开发实现，不能得出全局线性结论。

## 三、科研判断与限制

当前代码路径、冻结锁和数学/统计组件已通过实机Smoke；两次新开发试次中，小扰动一阶方向导数预测在 α=.5、1 处接近已知C，特别是预设5με/α=1。但这仅是**局部先导数值现象**，不是严格外部盲测。预测器使用真实qtrue和Oracle残差r0，不能视为可部署的辅助MZI校准方法。

所见α方向光频残差RMS约0.98 MHz，不能单凭一个尺度认定全系统物理应变范围与扫描漂移泛化。现有主探测器无噪声、真实TLS扫频共用、原V6c离散散射结构，均需在下一阶段提出额外物理测试。

## 四、下一步：严格使用预定12次开发集

在同一分支MATLAB仓库根目录运行：

```matlab
!git pull --ff-only
addpath('matlab/mechanism_p2b');
clear config_p2b p2b_assert_protocol p2b_run_trial p2b_run_trials
clear p2b_summarize main_p2b
rehash
cfg=config_p2b();
cfg.p2b.development_repeats=12; % 包含已运行smoke的2个试次
cfg.p2b.frozen_enabled=false;
cfg.p2b.run_frozen_test=false;
cfg.p2b.allow_frozen_test=false;
cfg.p2b.make_plots=true;
cfg.p2b.save_results=true;
[cfg,results]=main_p2b(cfg);
r=results.development;s=r.summary;
j=find(abs(s.strains_microeps-5)<1e-12);
v=find(abs(s.test_alpha-1)<1e-12);
fprintf('成功 %d/%d；失败 %d (%.2f%%)\n',s.n_success,s.n_total,s.n_failure,100*s.failure_rate);
fprintf('主终点 5με α=1: actualC=%.8g, predC=%.8g, modelMAE=%.8g, nullMAE=%.8g (με²)\n', ...
 s.mean_C_actual(j,v),s.mean_C_pred(j,v),s.mean_abs_error(j,v),s.mean_null_abs_error(j,v));
fprintf('配对 MAE 收益 %.8g [%.8g %.8g] (με²)\n', ...
 s.mean_abs_gain_vs_zero(j,v),s.gain_CI95(j,v,1),s.gain_CI95(j,v,2));
fprintf('模型较好 %d、较差 %d；最差退化 %.8g (με²)\n', ...
 s.n_prediction_better(j,v),s.n_prediction_worse(j,v),s.worst_abs_loss_regression(j,v));
disp(r.failure_id(~r.success));disp(r.failure_reason(~r.success));
```

本阶段无需新建不同种子或重调h；如有失败保留分母、原始错误栈与CSV，不可因为预测良好就跳过trial。输出 `matlab/mechanism_p2b/output/P2B_DEVELOPMENT_results.mat`、`P2B_DEVELOPMENT_trials.csv`。五张图的横纵轴与局限见 `docs/P2B_FIGURE_READING_GUIDE_2026-11-14.md`。

**这批Smoke中的两个试次是12次开发的前2次，禁止另计2个独立样本。冻结测试仍然禁用。**
