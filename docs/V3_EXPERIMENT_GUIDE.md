# V3 实验指导：真实光频坐标下的 Gaussian Gridding NUFFT

> **V3 是独立的 NUFFT 算法验证阶段，尚未将 V2 的 SSWT 轨迹估计误差接入。** 这样才能区分 NUFFT 的数值逼近误差与校准误差。MATLAB R2020b+，基础函数实现，无第三方 NUFFT 库。

## 1. 运行

在仓库根目录执行：

```matlab
addpath('matlab/v3');
smoke_test_v3;  % 无噪声、均匀/非均匀 NUDFT 精度和距离测试
[cfg, truth, signals, results, metrics] = main_v3();
```

程序自动添加 `matlab/v1` 路径，使用同一份 V1 物理信号模型。V3 默认运行独立小规模 NUDFT vs NUFFT 耗时对照，可设置 `cfg.v3.show_benchmark=false` 跳过。

### 建议先观察的图

- **Figure 7**：非均匀光频样本间隔、Gaussian kernel 局部网格扩散、Gaussian 频域核响应与网格求和结果。
- **Figure 8**：未校准 FFT、线性插值 FFT、PCHIP 插值 FFT 和**真实坐标 NUFFT** 的空间反射谱；中间是 0.450/0.456 m 的反射双峰，下面是 1.25 m 附近的展宽对比。
- **Figure 9**：Gaussian NUFFT 全谱与直接 NUDFT 的**选定索引**精度对照；下面是复数幅度误差对距离的变化。
- **Figure 10**：小规模 `N=256,512,1024,2048` 下直接 NUDFT 与 NUFFT 的耗时/数值误差。复杂度基准不等于 Ding 论文的大规模（百万点）实验性能。

## 2. 数学目标和尺度

真实光频相对坐标定义为

\[
u_n = \nu_0+\Delta\nu\,u_n,\qquad u_n\in[0,1).\]

主干涉信号（V1 的冻结频率近似）为

\[s_n=\sum_j A_j\cos(2\pi\tau_j\Delta\nu\,u_n+\phi_j)+\eta_n,\qquad \tau_j=2n_gz_j/c.\]

对空间索引 \(k=0,1,\ldots,\lfloor N/2\rfloor\)，V3 的 NUFFT 与 NUDFT 共享相同目标：

\[
F_k=\frac1N\sum_{n=0}^{N-1}d_n\,w(u_n)\,s_n\,e^{-i2\pi ku_n}.
\]

- `w(u)`：Hann 光频窗或无窗（用于限制频谱泄漏）。
- `d_n`：等权 `none` 或局部光频密度补偿 `voronoi`。二者描述不同的离散求和目标，不能交叉比较精度。
- 空间坐标：\(z_k = ck/(2n_g\Delta\nu)\)。这里的 \(\Delta\nu\) 是**激光器总的理论扫描带宽**，而不是两个实际采样端点间的频差。
- 当 `N` 较大且加 Hann 窗时，邻近反射点更容易识别，但主瓣比矩形窗宽；**距离 bin** 不等于实测 FWHM。

V3 没有假设普通 FFT 可直接处理非均匀 `u_n`：普通 FFT 是一个刻意错误的时间网格对照。

## 3. Gaussian Gridding 的四步

在过采样网格 \(K=\lceil \alpha N\rceil\) 上：

1. 映射到浮点网格索引 `p_n = K*u_n`。
2. 在 `J=kernel_width` 个邻近格点通过 `g(d)=exp(-d²/(2σ²))` 分摊样本，并在周期边界取模。
3. 对长度为 `K` 的网格做 FFT。
4. 以正频率索引 \(k\) 除以高斯卷积对应的核谱

\[
G_k=\sqrt{2\pi\sigma^2}\exp\big[-2\pi^2\sigma^2(k/K)^2\big].
\]

本实现选择

\[
\sigma^2=\frac{J}{4\pi\left(1-\frac{1}{2\alpha_{\rm eff}}\right)},\qquad\alpha_{\rm eff}=K/N.
\]

该参数选取是为了平衡有限核截断和频谱折叠误差（属于本项目的数值实现选择），**不直接照搬论文可能使用不同变量归一化的高斯 \(\tau\)**。误差必须用直接 NUDFT 验证，不应以单个小 `J` 的图形外观判断。

注意本实现为**正距离分支的一维 Type-1 NUFFT**，并非从非均匀样本恢复时间信号的逆插值算法。

## 4. 为什么增加密度补偿？

非均匀光频坐标中，如果低扫频速率区域的时间样本更密集，直接等权求和会让这些光频区域获得更大的贡献。我们提供可选的 Voronoi 权重，以近似连续光频积分。密度权重及窗函数必须在 NUFFT 与直接 NUDFT 中使用完全相同的约定。

`interp1` 是单独的均匀光频网格插值基线，它不通过 NUFFT 的密度补偿步骤；两者的数值目标不完全相同，因此应结合峰位、峰宽与物理谱质量评价，而非简单用 NUFFT/NUDFT 的相对误差评价插值 FFT。

由于 V1 不采集精确 `t=T` 端点，插值到 `u_grid=n/N` 在某些非线性设置下可能涉及最后一个点附近极小的外推，程序会报告点数。

## 5. 关键可调参数

```matlab
cfg=config_v3();
cfg.v3.alpha=2;
cfg.v3.kernel_width=12;      % 从 8 提高至 12，通常显著减小近似误差
cfg.v3.density_mode='voronoi'; % 改为 'none' 查看采样密度的影响
cfg.v3.window='hann';         % 改为 'none' 观察低旁瓣/高分辨率权衡
cfg.v3.show_benchmark=false;  % 先跳过额外耗时基准
[cfg, truth, signals, results, metrics]=main_v3(cfg);
```

建议分组实验：

1. `cfg.laser.ripple_a=0; cfg.laser.drift_b=0; cfg.sim.add_noise=false;` → 验证普通 FFT ≈ NUFFT。
2. 恢复非线性，关闭噪声 → 看未经校准的峰如何展宽。
3. 保持非线性，噪声开启 → 比较弱反射点能否清楚辨认。
4. `alpha=[1.25,1.5,2,3]` 与 `kernel_width=[4,6,8,12]` → 记录 NUDFT 近似误差和耗时。
5. 切换 `density_mode` 和 `window`，比较它们与 NUFFT 数值误差的区别。

## 6. 重要限制和理解

- **直接 NUDFT 只在稀疏且真值附近密集的 `probe_k` 计算；计时不能误当完整 N 点 NUDFT。** Figure 10 才计算全部正距离索引用于小规模耗时比较。
- NUFFT 的 `relative_l2` 是指定离散求和目标下的**数值逼近误差**，与 OFDR 理论空间分辨率不是一个概念。
- 由于 V1 使用实值余弦信号，正反距离存在共轭分量；本项目只显示正距离分支。
- 真实光学实验中的激光线宽、极化衰落、散射相关性、探测带宽、激光相位噪声、ADC jitter 等暂不模拟。
- V4 才将 `V2.calibration.sswt.nu_offset_Hz / truth.delta_nu_Hz` 用作 NUFFT 估计采样坐标，届时需要处理单调性、端点带宽漂移及不同绝对频率基准带来的距离标尺影响。**不可在 V3 偷用光频真值代替估计轨迹并称为 SSWT+NUFFT。**

## 7. 论文关系

Ding et al., 2012, *Review of Scientific Instruments* 83, 066110：辅助光频轨迹测量、Gaussian gridding、过采样 FFT 与去卷积的四步框架。本文 V3 采用同类框架，实际高斯参数与数值归一化按当前实现重新定义。参考 DOI：https://doi.org/10.1063/1.4729376。

Dang et al., 2022, *Optics Express* 30, 46722–46733：SSWT 动态波长校准在 V2 中独立实现；与 V3 的联合测试安排在 V4。DOI：https://doi.org/10.1364/OE.477771。
