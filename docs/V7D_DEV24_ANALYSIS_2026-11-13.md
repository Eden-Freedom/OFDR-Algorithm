# V7d-PF：24 次开发集实机复盘（2026-11-13）

> 数据：用户在 Windows MATLAB 上使用 `research/v7d-pf-candidate-feasibility` 分支、最新提交 `d1f29f4` 运行完整24次开发集，提供3幅截图和命令行日志。本文件记录**开发试次的已观察事实**，不是V7d独立冻结测试，也没有证明论文创新。未改变任何V7d算法、门限、种子或历史代码。

## 一、最重要结论

- 24/24成功、程序失败率0/24。与此前2次smoke使用同一开发种子起点，总分母是24而非26。
- `changed_decision_count=0/24`。原V7c和新V7d的选择全部相同；alpha分布均为 `[15,0,1,2,6]` 对应 `[0,.25,.5,.75,1]`。
- 24次均没有完整额外修正峰值 `E>0.8MHz`，因此**没有覆盖V7d为解决V7c提前拒绝而设计的核心边界情形**；新算法本次未观察到增量作用。
- 在24个成功trial上，V7d与V7c的Core、Holdout、有效Gauge比例全部逐trial相等，vs V7c 的core/holdout mean gain=0、bootstrap CI95=[0,0]、0胜0负24平。这是样本内的计算同一性，**不是统计等效或非劣效试验**。
- 相对Affine和Full SAPC的Core、Holdout配对CI95均跨零；不能声称新方法在当前开发条件下有稳定精度优势。

## 二、七方法平均数值

| 方法 | Core RMSE (με) | Holdout RMS (με) | 平均有效Gauge比例 |
|---|---:|---:|---:|
| Oracle | 0.108762 | 0.012067 | 0.9159 |
| Raw SSWT | 0.217178 | 0.285317 | 0.9083 |
| Smoothed SSWT | 0.367300 | 0.512267 | 0.9021 |
| Static affine | 0.213230 | 0.279150 | 0.9087 |
| Full SAPC | 0.212063 | 0.276473 | 0.9082 |
| V7c CV-SAPC | 0.212824 | 0.278930 | 0.9083 |
| V7d-PF | 0.212824 | 0.278930 | 0.9083 |

**七方法共同有效位置比例**：`mean_common_valid=0.4848`。注意 0.4848 是所有七方法有效Gauge掩码逐元素相交后的比例，而 `mean_valid` 每项大约为0.90；交集远小于任一单一方法的可测比例。由于Core/Holdout是七方法共同有效子集，配对比较在相同位置上公平，但可能对衰落、相位不稳定位置产生严重的选样效应，不能直接视为全部空间位置的性能。不应不经单独协议就修改主统计的mask；可在独立新实验中设计并报告pairwise common mask敏感性、有效Gauge丢失机制和完整Gauge覆盖。此前V7c为六方法mask，历史均值不能直接横向比较。

## 三、配对统计：V7d对四个基线

| 基线 | Core gain (με) | Core 95%CI | Core胜负平 | 最差单次退化(με) | Holdout gain (με) | Holdout 95%CI |
|---|---:|---|---|---:|---:|---|
| Raw SSWT | +0.004354 | [0.000681,0.008106] | 19/5/0 | 0.018397 | +0.006387 | [0.003047,0.009911] |
| Static affine | +0.000406 | [-0.002302,0.002943] | 5/4/15 | 0.021258 | +0.000220 | [-0.002236,0.002556] |
| Full SAPC | -0.000761 | [-0.002874,0.001334] | 7/11/6 | 0.015796 | -0.002457 | [-0.005855,0.000841] |
| 原V7c | 0 | [0,0] | 0/0/24 | 0 | 0 | [0,0] |

单位为微应变με；gain定义为基线RMSE-V7d RMSE，正数表示V7d较好。CI为trial-level配对bootstrap（2000次），失败trial仍要计入总试次的失败率。均值受当前物理条件与共同有效mask影响；Raw的正收益不能替代与Affine/Full SAPC/原V7c的关键比较。

相对Static affine：`mean_valid_gain=-0.00037862`（相当于 **-0.037862个百分点**），其置信区间 `[-0.00079509,-0.000018931]`；当前绝对损失小于原预设 0.5 个百分点限制，但不能在跨场景上保证。对V7c的有效比例变化为0。

## 四、三张MATLAB图逐图判读

### Figure 1｜平均误差与配对CI

- 上图横轴：Raw SSWT、Affine、Full SAPC、V7c、V7d-PF；纵轴：Core strain RMSE（με，越低越好）。V7c和V7d柱高一致，不能因此推断未知场景的等效性。
- 下图横轴：C/A、H/A、C/Full、H/Full、C/V7c、H/V7c；C=受应变Core，H=未应变Holdout；纵轴：配对RMSE改善（με，越大越好）。四条相对Affine/Full的CI都跨零，相对V7c的两个点及区间恰好为零。图示CI没有替代退化分布、失败率或空间覆盖率。

### Figure 2｜逐试次结果

- 上图横轴：V7c Core RMSE（με）；纵轴：V7d Core RMSE（με）；虚线 y=x。全部24个成功trial都在对角线上。
- 下图横轴：trial 1..24；纵轴：V7c Core RMSE - V7d Core RMSE（με）。每个点均为0。MATLAB在常数数据下自动扩展纵轴到约±1με，不代表实际出现±1με波动；建议后续图题直接说明 `24/24 identical`。
- 结论：目前新约束未造成有效决策/结果差异。局限：没有E超限trial，难以判断旧硬门限提前回退机制是否被改善。

### Figure 3｜α分布与E覆盖

- 上图横轴：α=[0,.25,.5,.75,1]，纵轴成功trial数。两组都是[15,0,1,2,6]；α=0是退回Affine，不是没有校正。
- 下图横轴：完整SAPC相对Affine的额外修正峰值E（MHz）；纵轴：V7d选择的α；颜色：V7d对V7c的Core配对增益（με），全部为0；虚线E=0.8 MHz。可见所有24次E<0.8，无一触及新机制最重要的设计边界。
- 局限：该图只能表示样本覆盖率与alpha决策，没有E超限样本就没有评价边界策略优劣的直接统计信息；不可以循环挑种子直至挑出有利试次并当作冻结测试。

## 五、研发方向与优先级

1. **不再把原V7d-PF的24次试验当成功案例**。该结果表明在现有物理条件上没有增量效应，但没有覆盖目标边界，故不宜贸然进入预留的100次冻结集。
2. **先作只读机制覆盖审计**：从保存的 `results.development` 中统计E分布、距0.8MHz阈值余量、V7c/V7d折内CV执行、α候选资格、共同Gauge分数；不运行新随机试次。
3. **若设计下一组目标机制暴露实验**：事先固定物理压力条件（如辅助干涉仪噪声、训练段长度、扫频非线性等）及全新开发种子，保留本轮24次完整主结果。对照因子必须正交、预先登记，禁止根据Core真值选取有利试次；新条件的结果只属开发机理实验。
4. **校正理论目标**：区分①候选早退风险、②静态段CV预测与受应变区收益的失配、③共同有效Gauge选择偏差，避免同时改变多个机制导致归因不清。
5. 新一轮独立盲测前审计代码与物理信息流，预先声明失败率、共同Gauge和trial bootstrap。冻结集仍锁定；不宣称工程泛化或论文创新性。

## 六、已保留的开发结果路径

- `matlab/v7d/output/V7d_DEVELOPMENT_results.mat`
- `matlab/v7d/output/V7d_DEVELOPMENT_trials.csv`
- 原三幅图由 `v7d_plot_results` 提供；截图与原日志由用户提供，仓库目前记录数值而未自动上传图片。

本文件只记录用户MATLAB实际输出；GitHub端没有运行MATLAB，也没有修改V7d算法或本批种子。

## 七、只读MATLAB覆盖率审计（新增工具，尚未实机验证）

新增 `matlab/v7d/v7d_audit_coverage_dev.m` 和对应合成数据单元测试 `smoke_test_v7d_coverage_audit.m`。它们不会重跑物理随机试次，也不会使用冻结种子。只从已保存MAT中检查 `E` 实际最小、最大值和经验95分位、alpha变更数、有效候选数量、两折CV是否完成、失败率以及共同Core/Holdout Gauge数量。

在**已创建的 V7d-PF 分支**和MATLAB仓库根目录执行：

```matlab
!git pull --ff-only
addpath('matlab/v7d');
clear v7d_audit_coverage_dev smoke_test_v7d_coverage_audit
rehash
smoke_test_v7d_coverage_audit
[T,d]=v7d_audit_coverage_dev();
disp(d);
disp(T(:,{'trial','E_MHz','E_margin_MHz','alpha_v7c','alpha_v7d','changed','full_nonaffine_count','fold_nonaffine_count_if_CV_executed','common_valid_fraction'}));
writetable(T,fullfile('matlab','v7d','output','V7d_DEV24_COVERAGE_AUDIT.csv'));
```

注意：工具尚未在用户MATLAB实机运行，不能把 `smoke_test_v7d_coverage_audit` 已通过作为事实；若报错应先提交原始ID、Reason、Stack。若输出 `0/24 E超限、0/24 alpha变化`，只说明本批物理条件没有观察到目标事件，不可认为已经充分验证V7d规则。对 `fold_nonaffine_count_if_CV_executed` 的NaN要区分“CV没有执行”与“候选不可行”，不能将NaN当成0个可行候选。
