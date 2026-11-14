# P1–P2 MATLAB 操作步骤：先核查数值核，再做可证伪的共模/差模消融

## 1. 获取独立研究分支

在包含顶层README.md的仓库根目录，先保存本地未提交的工作，然后在MATLAB执行：

```matlab
!git fetch origin
!git switch --track origin/research/p1p2-common-differential-20261114
addpath('matlab/mechanism_p1p2');
which main_p1p2 -all
which p2_run_trial -all
```

本地已有分支时改用 `!git switch research/p1p2-common-differential-20261114` 与 `!git pull --ff-only`；不得覆盖已有本地改动。

## 2. 第一关：代数与P1/P2端到端smoke

```matlab
clear config_p1p2 p1p2_assert_protocol
clear p1_oracle_nudft_check p1_nested_scatter
clear p2_run_trial p2_run_trials p2_summary main_p1p2
clear smoke_test_p1p2 smoke_test_p1p2_math
rehash
smoke_test_p1p2
```

预期分别打印 `[P1P2 algebra unit] PASS`、`[P1 NUDFT]...`、`[P1P2 smoke] PASS`。2/2是功能自检，不允许解读为统计结论。如失败，保持所有trial在分母，发出failure_id、failure_reason和完整堆栈，不要跳过smoke运行开发集。

## 3. 第二关：嵌套散射模型自检

```matlab
smoke_test_p1_density
```

预期2/2并报告有限的Oracle Core和Raw RMSE；这不是统计收敛证明。如失败，不直接放弃物理核查或挑有利随机种子。

## 4. 两项smoke通过之后：机制开发与数值核查

```matlab
cfg=config_p1p2();
cfg.p1p2.repeats=8;
cfg.p1p2.p1_scat_repeats=4;
cfg.p1p2.run_p1_direct=true;
cfg.p1p2.run_p1_density=true;
cfg.p1p2.run_p2=true;
cfg.p1p2.save_results=true;
cfg.p1p2.make_plots=true;
[cfg,results]=main_p1p2(cfg);
disp(results.p2.summary);
disp(results.p2.failure_id(~results.p2.success));
disp(results.p2.failure_reason(~results.p2.success));
disp(results.p1_density.failure_id(~results.p1_density.success));
disp(results.p1_density.failure_reason(~results.p1_density.success));
```

本阶段P2试次数包含smoke所用的最初2个新开发种子。保存 `matlab/mechanism_p1p2/output/P1P2_DEVELOPMENT_results.mat`、`P2_DEV_trials.csv` 与全部绘图、命令行日志；默认只保存MAT/CSV，不自动导出图窗PNG。如需存档，可按图窗名称使用 `exportgraphics(gcf,fullfile(...),'Resolution',180)`，并记录Git SHA。

## 5. 科研审查清单

- 先看P1 NUDFT复谱误差大小，比较已知数值误差容限，不仅看‘代码可运行’。
- 再看嵌套散射密度随步长缩小是否收敛，不能把不同随机散射场的一次波动当成离散误差。
- P2检查零应变00/10不变性、非零应变C/D/I相互作用、raw和9-bin的差异、跨试次有效率及失败率。
- 牢记I单位是(με)^2且可为负；不能直接将`M11-M10-M01+M00`称为占比百分数。
- 即使P2看到明确作用，也不等于可从辅助MZI实际观测识别这个作用；下一阶段必须做无真值的独立估计、强基线与未见条件外推。

## 6. 禁止事项

不运行V7c/V7d冻结集，不修改旧历史源码，不按应变真值选择算法校正系数，不在结果展示中删除失败trial；禁止把单一实现或8次开发CI当作论文显著性证据。