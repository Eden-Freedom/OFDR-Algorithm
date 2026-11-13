# V6c 非零已知应变：Rayleigh 双扫描前向/解调 MATLAB 实验指南

> 状态：实现已编写并做独立数值公式核验；**没有在此环境运行 MATLAB**。先执行 `smoke_test_v6c`，若失败不应把任何后续曲线当成应变精度结论。

## 1. 要回答的科研问题

V6a/V6b 在**零应变**中展示 SSWT 两次扫描校准残差可产生非零 gauge 相位。过去的 με 仅是用假定的相位系数换算的**等效代理**；V6c 首次引入**物理施加的已知非零轴向应变**，并用同一散射体生成两次真实不同的主干涉信号。

研究关卡依次为：
1. **零应变正演验收**：同一散射体，同一真实 q，ε=0 必须给出完全一致的时域主干涉信号，oracle/oracle 的 gauge≈0。
2. **非零 oracle 验收**：真实坐标 NUFFT 下应能恢复 5 με 的幅度及正号；有偏差要先修复模型，不应借 SSWT 改进解释。
3. **SSWT 边际误差**：在同一受应变主信号下比较 oracle、两次共模 SSWT 轨迹、独立 SSWT 轨迹；报告 strain RMSE/bias、静止区假应变、有效率。
4. **幅值线性与失效**：扫已知 0/1/2/5/10/20 με；观察 oracle 和 SSWT 是否遵循 y=x。所有样本以同一前向机制计算，不能将人工注入的载波相位直接作为测量结果。

## 2. 模型与物理符号

从实值应变场 ε(z) 积分得物理位移：

\[u(z)=\int_0^z\epsilon(x)\,dx.\]

在小应变、忽略色散高阶项的近似下，散射点的**载波往返相位变化**：

\[\Delta\phi_c(z)=\frac{4\pi n_{eff}(1-p_e)}{\lambda_0}u(z).\]

扫描光频的散射群时延变化：

\[\Delta\tau_g(z)=\frac{2n_g\beta_g}{c}u(z),\quad \beta_g=0.78\ \text{(可调近似)}.\]

\[s_r(t)=\Re\sum_j a_j e^{i2\pi \tau_{g,j} q_{true}(t)},\]

\[s_m(t)=\Re\sum_j a_j e^{i\Delta\phi_c(z_j)}e^{i2\pi(\tau_{g,j}+\Delta\tau_g(z_j))q_{true}(t)}.\]

这里 `a_j` 是**固定不重抽**的 Rayleigh 复散射系数；相位指数与 V3 NUFFT 的正向符号一致。材料系数 `n_eff`（相折射率）和 `n_g`（群折射率）分开配置，且载波相位用 `lambda_ref_m`，**不把~193 THz 的常相位错误地丢掉**。相应的 gauge 平均应变真值：

\[\epsilon_{g,true}(z)=\frac{u(z+L_g/2)-u(z-L_g/2)}{L_g}.\]

解调使用 V6a 的两条复谱 `C=R_m conj(R_r)`，再取 gauge 端点的差分相位，并按 \(\lambda/(4\pi n_{eff}(1-p_e)L_g)\) 换算。真值只在**事后评分**时使用，不用于反演/校正。

### 与真实仪器的差距（必须写在论文方法限制）

- 仍沿用 V1 的冻结频率短延迟近似与单偏振复散射体模型；未模拟温度、偏振衰落、激光相位噪声、双阶段真实扫频变化、探测器频响与振动。
- 默认两次真实 TLS 扫频相同，主检测噪声关闭；当前重点是隔离误差传播。V6c 不可称为物理实验已证实的传感精度。
- 群延迟弹光因子 `beta_g` 为近似，可通过色散/材料参数敏感性扩展；并非独立测出的材料常数。
- 幅度门限中 oracle_reference 是用于**诊断公平性**的真值坐标参考复谱，真实部署时不得偷用。
- 默认 gauge 相位采用**模 2π 的端点复相位差**，已知真值若接近相位包裹（预设 0.8π）会判作无效；对于大应变需要另外验证相位展开及频率偏移互相关解调，不能直接扩大载荷。

## 3. 为什么提供 raw 与 phase-averaged 两种结果？

Rayleigh 相干衰落使直接两像素端点差分相位误差较大。为避免在正演验收时被偶发衰落误判，V6c **明确**提供：

- `m.raw_gauge_phase_rad` / `m.core_raw_strain_rmse_microeps`：V6a 的原始逐点 gauge 结果。
- `m.gauge_phase_rad` / `m.core_strain_rmse_microeps`：对相邻 `phase_avg_bins` 个**复 gauge phasor** 平均后再取角度。

默认 `phase_avg_bins=9`，本工程距离步长约 0.818 mm，gauge 约 9.813 mm；局部相位平均又引入约 6.54 mm 的额外平滑支持，因此估计**空间支持宽度约 16.36 mm**。**这不是声称提升分辨率**，而是清楚表述相位噪声—空间分辨率的折中。不可将本阶段平滑指标与 V6a/V6b 未平滑的代理 RMS 直接比较，必须报告两者。

也可设置 `cfg.v6c.phase_avg_bins=1;` 关闭任何附加空间相位平均。表格中还需记录有效位置比例、核心区和静态区各自的 RMSE。

## 4. 首次运行

MATLAB R2020b+，在仓库根目录：

```matlab
!git pull --ff-only origin main
addpath('matlab/v6c');
smoke_test_v6c;  % 必须先过：0 ue 时域同一，oracle 5 ue 符号与数量级
[cfg,results] = main_v6c();
```

自检中默认要求真实坐标 5 με 的 core RMSE < 1 με，且估计平均值与 5 με 相差 < 1 με。**如果失败：优先检查载波相位、时延符号、相干衰落和NUFFT复谱符号；不要调阈值掩盖错误。**

随后设置参数：

```matlab
cfg=config_v6c();
cfg.v6c.strain_microeps=5;
cfg.v6c.strain_sweep_microeps=[0 1 2 5 10 20];
cfg.v6c.phase_avg_bins=9;     % 关闭设1，务必报告空间支持宽度
cfg.v6c.run_mc=false;
[cfg,res]=main_v6c(cfg);
```

如果基础自检通过，再做多独立散射/辅助噪声配对：

```matlab
cfg=config_v6c();
cfg.v6c.run_mc=true;
cfg.v6c.mc_repeats=36;
cfg.v6c.make_plots=true;
[cfg,res]=main_v6c(cfg);
```

36 次属于第一轮统计，进一步应采用不同应变水平及扫描带宽，并在 trial 级 bootstrap，不能把不同像素视作独立试验。

## 5. 输出文件与最重要的数值

- `matlab/v6c/output/V6c_nonzero_strain.mat`：输入配置、真值应变场、每个工况真实/估计 gauge、所有有效性门限。
- `V6c_strain_sweep.csv`：已知非零应变、不同轨迹方案的核心区真值均值、恢复值、应变 RMSE、静止区虚假应变和有效率。
- 启用重复后 `V6c_strain_MC.csv`：每 trial 的散射/辅助种子、oracle/SSWT RMSE 与失效原因。
- `figures/v6c_fig1_*` 至 `v6c_fig4_*`：逐图见 [V6C_FIGURE_READING_GUIDE.md](V6C_FIGURE_READING_GUIDE.md)。

MATLAB 直接取例子：

```matlab
idx=find(abs(results.strain_sweep_microeps-5)<1e-10,1);
case0=results.strain_tests{idx}.trial.cases.oracle;
case1=results.strain_tests{idx}.trial.cases.independent_sswt;
case0.metrics.core_strain_rmse_microeps
case0.metrics.core_raw_strain_rmse_microeps
case1.metrics.core_strain_rmse_microeps
case1.metrics.static_false_strain_rmse_microeps
case1.metrics.valid_fraction
case1.metrics.effective_spatial_support_m*1000
```

**必须区别：** oracle 与 SSWT 的 RMSE 之差才是此模型下的新增校准误差影响；oracle 自身有限的误差来自有限光频带宽、Rayleigh 相干衰落、正演近似与解调器误差。只报告 SSWT 的总 RMSE 会把多个来源混在一起。

## 6. 研究性判据与能否继续创新

- 0 με 的真实轨迹必须恢复零（机器数值噪声内）；
- 对 1/2/5/10/20 με，oracle 实测均值应具有正确符号、近线性，且 RMSE、有效率完整记录；
- 在相同物理信号下，与 oracle 比较，独立 SSWT 是否**额外提高**非零应变 RMSE 和静止区虚假应变；
- 若残差消融在不同应变水平稳定复现，才有依据研究相位保真校准；
- 若 oracle 自身已严重失真，应改进前向/解调器，而不是急于发明新的 SSWT 方法。

参考物理关系：High-Resolution Φ-OFDR Using Phase Unwrap and Nonlinearity Suppression (JLT 2023) https://eprints.soton.ac.uk/475362/1/High_resolution_OFDR_using_phase_unwrap_and_nonlinearity_suppression.pdf；High-Resolution OFDR with All Grating Fiber Combining Phase Demodulation and Cross-Correlation Methods (Sensors 2026) https://doi.org/10.3390/s26031004 。
