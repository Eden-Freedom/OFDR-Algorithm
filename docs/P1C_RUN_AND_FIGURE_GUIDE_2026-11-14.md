# P1c MATLAB操作与逐图阅读指南

> 第一阶段数学单元测试；第二阶段只重算**同一已查看开发seed**的数值Gauge对照。实验代码未在用户MATLAB运行，所有下面的预期文本不是实际结果。

## 1. 获取独立研究分支

在包含顶层README的GitHub仓库根目录，先保存未提交的本地工作；若当前位于P1/P2研究分支：

```matlab
!git fetch origin
!git switch --track origin/research/p1c-gauge-nudft-audit-20261114
addpath('matlab/mechanism_p1p2');
clear p1c_required_sites p1c_gauge_phase_from_spectra
clear smoke_test_p1c_math p1c_gauge_nudft_audit run_p1c_gauge_audit
rehash
which run_p1c_gauge_audit -all
```

若分支已在本地建立，改用 `!git switch research/p1c-gauge-nudft-audit-20261114` 然后 `!git pull --ff-only`。若 `git switch` 报本地修改冲突，先保存更改，不能强制覆盖。

## 2. 先运行纯合成数学smoke

```matlab
smoke_test_p1c_math
```

预期 `[P1c gauge math unit] PASS: sparse bin union, 9-bin conv, equal-trace and bounds.`。没有任何物理随机试次或冻结数据。

## 3. 然后仅运行一次P1c固定seed数值审计

```matlab
a=run_p1c_gauge_audit();
disp(a);
```

这个入口会调用一遍原V6已有P1a seed的物理信号再生，不运行新独立种子，不调用V7冻结试验，也不修改历史P1/P2 MAT。将结果保存到 `matlab/mechanism_p1p2/output/P1C_GAUGE_NUDFT_DEVELOPMENT.mat`、`P1C_GAUGE_NUDFT_DEVELOPMENT.csv`。图窗默认不自动导出PNG，必要时由用户用 `exportgraphics(gcf,...)` 存档；记录当前Git SHA。

**验收重点**：是否复现原V6c Gauge计算；所有数值有限；Core Gauge数量、真实所需bin总数、幅度门限一致性；反三角不等式必须满足。不要因为直接NUDFT相位与NUFFT不一致就按真值剔除难点；需要报告异常。

## 4. Figure 1：Core Gauge 位置上的数值差异

上图横轴固定Core Gauge的中点距离z(m)，纵轴 `eps_D(z)-eps_N(z)` (με)；虚线y=0为同一结果。出现尖峰时，先检查该位置附近复谱幅度、门限或相位跳变，不可以直接把异常Gauge删除来改善整体图像。

下图横轴为 `abs(eps_D-eps_N)` 的经验百分位（%），纵轴为绝对应变数值差（με）；关注尾部最高位置是否很大。这不是bootstrap置信区间，样本间Gauge高度相关。

## 5. Figure 2：同一Gauge掩码下Oracle Core RMSE

横轴NUFFT与直接NUDFT两种数值求和方式；纵轴相同Core位置、同一5με真值的RMSE(με)。两柱接近不代表每个Gauge的数值差都很小，应结合Figure1最大尾部差；图标题还给出真实的有符号 RMSE差及其RMS差上界。该图是同一散射实现的数值核查，不是随机算法优越性或普适物理噪声底限。

## 6. 科研后续

只有在P1c数值一致性核查有足够证据后，才考虑P2下一实验：固定误差方向的中心有限差分估计共模局部灵敏度，预测未参与拟合的应变/误差幅度；保持Oracle机制输入与未来可部署观测模型严格分离。另见即将制定的P2灵敏度研究草案。