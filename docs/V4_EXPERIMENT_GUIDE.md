# V4 实验指导：SSWT 动态光频校准 + NUFFT 空间谱重构

> 本阶段将 V1/V2/V3 连接成**端到端联合仿真**：非线性 TLS → 辅助 MZI → SSWT 拍频校准 → 非均匀光频坐标 → 主 OFDR Gaussian NUFFT。V1–V3 的算法文件不被修改，仍可独立验证。本文档描述本项目的仿真设计，不是原论文实验的逐项复现。

## 1. 运行

建议 MATLAB R2020b 或更高版本，只使用 MATLAB 基础函数。

```matlab
!git pull --ff-only origin main
addpath('matlab/v4');
smoke_test_v4;
[cfg,truth,signals,results,metrics] = main_v4();
```

V4 自动添加 `matlab/v1`、`matlab/v2`、`matlab/v3` 路径。默认生成以下图形：

- **Figure 11**：未校准 FFT / 真值 NUFFT / SSWT+NUFFT / SSWT+插值 FFT 的全长光纤反射谱、0.450/0.456 m 双峰放大图、无噪声 1.25 m 孤立反射点对照。
- **Figure 12**：V2 的 SSWT 光频轨迹与真实扫频轨迹，以及 MHz 量级光频误差。
- **Figure 13**：各重构算法相对真值 NUFFT 的幅度谱误差及反射点定位误差。
- **Figure 14（可选）**：`run_snr_sweep_v4();` 批量评估辅助信号 SNR 对波长校准与空间谱重构的影响。

## 2. SSWT 与 NUFFT 的接口，为什么需要光频坐标？

辅助 MZI 和主 OFDR 干涉仪采样于相同的时间点 `t_n`。V2 的输出是辅助拍频 `f_hat_aux(t_n)`，光频偏移通过积分获得：

\[
\widehat{\nu}(t_n)-\widehat{\nu}(t_0)
=\frac{1}{\tau_a}\int_{t_0}^{t_n}\widehat f_{aux}(t)\,dt.
\]

要送入 V3 的 Type-1 NUFFT，必须将其转换为**归一化非均匀光频位置**。本项目在 V4 中采用仪器参数定义的*标称扫描带宽*：

\[
\Delta\nu_{nom}=c\bigl(1/\lambda_{end}-1/\lambda_{start}\bigr),\qquad
\widehat u_n=\frac{\widehat\nu(t_n)-\widehat\nu(t_0)}{\Delta\nu_{nom}}.
\]

然后用 V3 的实现直接计算：

\[
R_k\approx\frac1N\sum_n d_n\,w(\widehat u_n)\,
           s_{main}(t_n)\,e^{-i2\pi k\widehat u_n}.
\]

`d_n` 为可选 Voronoi 光频采样密度权重，`w` 为光频 Hann 窗；都按本方法使用的坐标重新计算。物理距离轴始终使用同一个外部给定的标称带宽：

\[z_k=ck/(2n_g\Delta\nu_{nom}).\]

**为什么不能直接用真实轨迹 `truth.u` 修正 `u_hat`？** 因为这会把本该由 SSWT 解决的扫频误差人为去掉，导致明显的真值信息泄露。真实轨迹仅用于理想参考组和评分，不参与 SSWT 结果校正。

**数值有效性限制**：V3 NUFFT 要求 `u_n` 严格递增且位于 `[0,1)`。默认仿真预期满足。若噪声较强或使用偏差较大的校准轨迹导致超界，程序将明确报错，不会排序、裁剪、取模或偷偷借用真值归一化。若要处理真实激光器的扫描端点漂移，需要单独的扫描带宽标定模块。

## 3. 主对照方法

| 结果字段 | 坐标来源 | 空间重构方式 | 作用 |
|---|---|---|---|
| `fft_uncalibrated` | 视为均匀时间采样 | 直接 FFT | 原始未校正基线 |
| `nufft_truth` | 真值光频 | Gaussian NUFFT | 理想标定参考 |
| `interp_truth` | 真值光频 | 线性插值 FFT | 理想插值基线 |
| `nufft_sswt` | SSWT 光频 | Gaussian NUFFT | **本项目联合方法** |
| `interp_sswt` | SSWT 光频 | 线性插值 FFT | NUFFT 对比基线 |
| `pchip_sswt` | SSWT 光频 | PCHIP 插值 FFT | 非线性插值基线 |

可设置 `cfg.v4.include_stft_cwt=true` 额外尝试 `nufft_stft` 和 `nufft_cwt`（可选消融）；其中 CWT 累计的正向偏差可能令末端 `u>=1`，该可选支路将跳过，并给出提示，不影响 SSWT+NUFFT 主要路径。默认 `cfg.v4.include_stft_cwt=false`，以确保主实验输出简洁。

## 4. 指标及其科学含义

- **拍频 RMSE**：`metrics.calibration.sswt.beat_rmse_Hz`，与 V2 一致，忽略首尾 5% 的边界估计样本。
- **波长 RMSE**：`metrics.calibration.sswt.wavelength_rmse_fm`，全扫频统计，包含积分累计的偏差。
- **光频坐标 RMSE**：`metrics.scan_error_rmse_MHz`，V4 估计位置与真值的差值；真值仅用于评估。
- **幅度谱相对 L2**：`metrics.nufft_sswt.magnitude_relative_l2`，与真值坐标 NUFFT 的幅度分布比较，可反映峰高与谱形失真。
- **复数谱相对 L2**：`metrics.nufft_sswt.complex_relative_l2`，包含相位误差，不应直接等同于物理反射点分辨率。
- **局部峰位**：`metrics.nufft_sswt.peaks_m` / `.errors_m`，在预设真实反射位置附近搜索局部最大峰，因此是*定位对照*，不是盲检成功率。
- **孤立反射峰功率 FWHM**：`metrics.isolated.nufft_sswt.power_fwhm_m`，使用 `|S|^2` 的半高宽（3 dB 功率宽度）。
- **孤立反射谱 90% 能量宽度**：`metrics.isolated.fft_uncalibrated.energy90_width_m`，更适合评价未校准 FFT 形成的宽展、波纹谱，避免对一个局部小尖峰计算误导性的 FWHM。三种方法均计算此指标。

注意：**距离 bin 尺度、功率 FWHM、90% 能量宽度是三个不同指标**。FFT 零填充不能提高物理分辨率。

## 5. 参数实验建议

```matlab
cfg=config_v4();
cfg.v4.include_stft_cwt=false;
cfg.v3.kernel_width=12;      % 更精确的 NUFFT 数值近似
cfg.aux.snr_dB=20;
cfg.sswt.smooth_points=41;   % 注意 V2 也对 STFT、CWT 使用此平滑点数
[cfg,truth,signals,results,metrics]=main_v4(cfg);
```

先依次运行：(1) `cfg.sim.add_noise=false; cfg.laser.ripple_a=0; cfg.laser.drift_b=0;`；(2) 无噪声、恢复默认非线性；(3) 恢复噪声；(4) 核宽度分别设为 6/8/12 比较数值近似；(5) 独立执行 `run_snr_sweep_v4()`，得到均值和标准差。不要同时改变多个参数，以免误差来源混杂。

## 6. 已知限制

1. 仍使用 V1 冻结频率的教学光路模型，不包含瑞利散射、偏振、相位噪声、实际探测带宽等。
2. 扫描带宽由独立标称起止波长给定。实际系统必须建立可靠的绝对光频锚点和扫描带宽标定。
3. SSWT 时频图能量更集中不意味着它的频率估计 RMSE 或最终空间分辨率必定优于所有算法。
4. 默认采用近似 Gaussian Gridding NUFFT，数值近似误差已在 V3 用直接 NUDFT 独立验证；V4 讨论额外的*校准误差*。
5. **本环境未配备 MATLAB 运行时**：源码和静态检查不能代替使用者的 MATLAB 本地 `smoke_test_v4`。

## 7. 相关论文

- H. Dang et al., *Optics Express* 30, 46722–46733 (2022), https://doi.org/10.1364/OE.477771：辅助干涉仪 + SSWT 动态波长校准。
- Z. Ding et al., *Review of Scientific Instruments* 83, 066110 (2012), https://doi.org/10.1063/1.4729376：Gaussian Gridding NUFFT 空间域重构。

本项目将两种思想结合，但**不宣称这两篇论文提出了此联合架构**。
