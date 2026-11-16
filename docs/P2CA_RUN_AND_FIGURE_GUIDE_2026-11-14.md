# P2c-A MATLAB操作与三张图逐图阅读

> 新代码已建立GitHub，但**尚未获得用户MATLAB实机结果**。这是不使用随机数、已知离散矩阵参数的数学结构审计，不是物理P2c新算法试验；无独立重复/95%CI/ROI/应变误差指标是因为本阶段根本没有随机光学信号、应变或Core评分。不要把“数学单元测试PASS”解释为算法优越性。

## 1. 获取独立研究分支

在OFDR-Algorithm仓库根目录执行以下命令；若本地有尚未提交的改动，先自行保存，严禁`git reset --hard`强制覆盖。

```matlab
!git fetch origin
!git switch --track origin/research/p2c-a-aux-mzi-identifiability-20261114
addpath('matlab/mechanism_p2c_a');

clear config_p2c_a p2ca_assert_protocol
clear p2ca_integral_matrix p2ca_numerical_rank
clear main_p2c_a p2ca_plot_results smoke_test_p2c_a_math
rehash

which main_p2c_a -all
smoke_test_p2c_a_math
```

若分支已经在本地存在，改用`!git switch research/p2c-a-aux-mzi-identifiability-20261114`、`!git pull --ff-only`。

Smoke是100%确定性代数测试：包括整数与非整数延迟积分矩阵、满窗条件、常光频相位、零均值周期模式、数值秩、未知相位offset与未知时延的反例、冻结锁和不消耗随机数的检查。测试失败时报告原始ID/Reason/Stack；不要因为秩不符合预期就调整时延来“凑结果”。

## 2. 单元测试通过后运行数学演示

```matlab
cfg=config_p2c_a();
cfg.p2ca.make_plots=true;
cfg.p2ca.save_results=true;

[cfg,results]=main_p2c_a(cfg);
disp(results);
```

MAT结果保存至`matlab/mechanism_p2c_a/output/P2CA_MATH_ONLY_results.mat`，原P2b开发数据完全不动。输出中将明确注明`MATH ONLY`。

## 3. Figure 1：奇异值、秩与理论不可观测方向

横轴：矩阵按从大到小排序的奇异值序号（不是物理频率）；纵轴：对应奇异值的对数纵轴。三条曲线分别为单延迟已知offset、单延迟未知offset（已去均值）、双延迟未知独立offset。

需要在命令行对照矩阵的`rank/nullity`；仅在图上看曲线最低点不能数出核空间维度，因为奇异值零无法放在对数轴。判断联合增加延迟消除多少周期盲方向、是否还剩绝对直流规范。

**注意**：这是64维有限维的无噪声秩，不等同于噪声条件下稳健反演；奇异值分布也取决于归一化、边界条件与采样窗。

## 4. Figure 2：两种不同但单延迟不可区分的扫频

上图横轴：频率时间单元索引0–63；纵轴：无量纲`x=ν·dt`（周期/格），两条不同扫频轨迹都严格单调。下图横轴：辅助相位观测时间`t/dt`，纵轴：改变扫频后解缠辅助相位的差（rad）。

对于时延4格，周期4的零和误差完全被积分抵消，差异在浮点零附近；时延5格则观测到非零相位差。说明第二个延迟可以增加信息，而不能简单归结为“算法去噪”。

## 5. Figure 3：未标定时延与线性扫频尺度的歧义

横轴：观测时刻`t/dt`，纵轴：理想解缠辅助相位（rad）；分别用不同的τ、不同的ν0和扫频斜率、相应未知offset生成理论相同的曲线。

要检验两条曲线的最大绝对误差≈机器精度，而不是检查哪种校正器应变RMSE更低。该反例成立依赖于单延迟/未知τ/未知相位偏置/没有额外标定等条件，加入第二个独立时延、已知扫频端点或硬件标定之后需重新审查。

## 6. 此次审计完成后的科研走向

P2c-B首先必须定义可观测算法的输入边界，再考虑从辅助实测波形（如PD cos条纹、Hilbert+unwrap、SSWT）实现真正的频率标定；然后才回到相位敏感OFDR应变Core RMSE/静态区RMS/覆盖率/失败率/配对Bootstrap和新冻结协议。当前不能据P2c-A数学示例直接声称新的OFDR论文方法。

