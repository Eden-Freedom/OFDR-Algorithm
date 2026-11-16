# P2c-A2 MATLAB运行与两张新图阅读指南

> 完成P2c-A秩验证之后，运行新的**无随机数**任务相关零空间示例。新代码尚未经用户MATLAB实机验证；下列预期数值来自理论式及非MATLAB独立代数检查，不是假装取得的MATLAB结果。

## 1. 切换新分支（不要覆盖本地改动）

在OFDR-Algorithm仓库根目录执行：

```matlab
!git fetch origin
!git switch --track origin/research/p2ca-task-relevant-nullmode-20261115

addpath('matlab/mechanism_p2c_a');
clear p2ca_task_relevant_nullmode smoke_test_p2ca_task_relevance
clear p2ca_plot_task_relevance run_p2ca_task_relevance
clear p2ca_plot_results
rehash

% 确认独立入口
which run_p2ca_task_relevance -all

% 先测试代数恒等关系、冻结锁与随机状态
smoke_test_p2ca_task_relevance
```

若本地已存在分支：`!git switch research/p2ca-task-relevant-nullmode-20261115` 后 `!git pull --ff-only`。如有本地未提交更改，先保存，禁止强制重置。

## 2. smoke PASS后运行示例并画图

```matlab
r=run_p2ca_task_relevance();
disp(r);

% 可选：重新绘制经YScale修复后的旧Figure1（不会重新跑随机试次）
cfg=config_p2c_a();
cfg.p2ca.save_results=false;
cfg.p2ca.make_plots=true;
[cfg,ranks]=main_p2c_a(cfg);
```

数学演示保存至 `matlab/mechanism_p2c_a/output/P2CA_TASK_RELEVANCE_MATH_ONLY.mat`，不覆盖原`P2CA_MATH_ONLY_results.mat`。`p2ca_plot_results.m`在新分支显式设置奇异值图Y轴对数尺度；仅修复显示，不更改矩阵秩数值。

预期的数学相位量级：单4-bin辅助盲模态最大约0，第二5-bin辅助最大约0.062832 rad，主单点2-bin相位最大约0.062832 rad；两个相同扫频共同扰动、共同DC偏置和主4-bin盲情形均≈0。须以真实MATLAB输出为准。

## 3. Figure 4：两个单调扫描与不同延迟的主/辅响应

上图横轴为频率时间格序号k（0-based），纵轴为无量纲`x=νΔt`。两条扫频均严格单调，细小周期分量肉眼可能难以分辨，但计算中确实不相同。

下图横轴为辅助4-bin和主2-bin都完整的公共观测时刻`t/Δt`；纵轴为测量减参考的干涉相位差(rad)。4-bin辅助（盲）≈0；2-bin主点反射延迟（敏感）出现非零相位；4-bin主点反射对照亦≈0。**纵轴不是应变με**。

只有在`A_aux δx≈0`而`A_main δx≠0`时，才构成辅助-only光频误差可观测性不足且下游主相位受影响的反例。此处虽模拟双扫描，但完全没有真实Rayleigh或应变解调。

## 4. Figure 5：差模扰动与共同扰动

横轴为公共观测时刻`t/Δt`，纵轴为同一主点反射的测量-参考相位差(rad)。差模盲扰动只出现在测量扫描时，相位非零；完全相同的扰动出现在两次扫描时，相位为0。

必须认识：这只是具有相同静态点反射路径的确定性干涉相位模型，不能直接断言真实应变`ε=0`时的Core伪应变RMSE必然等于此相位或直接换算成με。

## 5. 科研退出条件

若上述两幅图与理论相符，则说明辅助零空间并非一律无害或有害，**重要的是它与主通道观测算子及双扫描差异的交集**。下一步先设计辅助+主联合可观测性模型和真实输入限制，之后才开启无真值Hilbert/SSWT强基线与Rayleigh随机仿真，冻结集始终保持锁定。
