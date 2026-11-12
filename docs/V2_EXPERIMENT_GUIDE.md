# V2 实验指导：从复 Morlet CWT 到 SSWT 光频轨迹校准

## 1. 本阶段能做什么

本阶段保留 V1 同一套 TLS + 辅助 MZI 信号模型。**不使用 NUFFT，也不使用内置 `wsst` 或 `cwt`**。自己完成复 Morlet CWT、时频系数重分配、单脊线提取与由拍频积分得到绝对光频、波长轨迹。

代码文件在 `matlab/v2/`：

- `config_v2.m`：集中配置参数，调用 V1 的 `config_v1`。
- `cwt_morlet_fft.m`：通过频域乘法计算 Morlet CWT；镜像扩展降低边界误差。
- `synchrosqueeze_cwt.m`：由复系数相位导数估计局部拍频并重新分配系数。
- `extract_sswt_ridge.m`：先从 SSWT 选脊线，再用附近尺度上的相位导数细化估计。
- `ridge_edge_extrapolate.m`：对变换边缘相位畸变做可关闭的局部二次外推（缓变扫频先验）。
- `estimate_cwt_ridge.m`：未压缩 CWT 的尺度脊线基线。
- `estimate_stft_ridge.m`：手写 STFT + 峰值抛物线插值基线。
- `recover_optical_frequency.m`：`f_aux(t)=tau_aux*dnu/dt`，按时间累积积分，重建波长。
- `evaluate_calibration_v2.m`：拍频、光频、波长 RMSE 和运行时间。
- `plot_v2_results.m`：图 4–6。
- `main_v2.m` / `smoke_test_v2.m`：主入口和小型回归测试。

## 2. MATLAB 运行方式

在仓库根目录：

```matlab
addpath('matlab/v2');
[cfg, truth, signals, results, metrics] = main_v2();
smoke_test_v2;
```

`main_v2` 会自动添加 `matlab/v1` 路径。建议先运行 `smoke_test_v2` 验证数值实现，再使用常规带噪声的主程序作图。如果需要保存 PNG：

```matlab
cfg = config_v2();
cfg.plot.save_png = true;
main_v2(cfg);
```

如需研究理想无噪声条件：

```matlab
cfg = config_v2();
cfg.sim.add_noise = false;
main_v2(cfg);
```

## 3. 本阶段最重要的物理关系

定义辅助 MZI **有效总时延** `tau_aux`，不再额外乘以往返因子：

```text
s_aux(t) = A*cos(2*pi*tau_aux*(nu(t)-nu_start)+phi) + noise
f_aux(t) = tau_aux*(d nu(t)/dt)
nu_est(t) = nu_start + (1/tau_aux)*integral_0^t f_aux_est(s) ds
lambda_est(t) = c/nu_est(t)
```

因此 V2 的 SSWT **不是直接估计绝对光频**，而是估计 MZI 条纹的瞬时拍频。完成积分还需要已知起点光频 `nu_start` 或其它外部参考。实验里这个锚点由模拟真值提供；实际系统需要物理校准。

## 4. CWT 与 SSWT 数学要点

复 Morlet 小波的频率响应（正频率）为：

```text
Psi(w) = pi^(-1/4) * exp[-(w-w0)^2/2], w>0
W(a,t) = IFFT{ FFT[x] * sqrt(a)*conj(Psi(a*w)) }
```

在足够强的系数上，通过

```text
f(a,t) ≈ angle(W(a,t+dt)*conj(W(a,t-dt))) / (4*pi*dt)
```

得到时频平面中每个点的局部频率估计。这里用**跨两个采样间隔的相位差**，故限制分析频段上界 `f_max < fs/4`，防止 `angle` 包裹导致频率混叠。

对每个 `(a,t)`，将加权系数 `W(a,t)*a^(-3/2)*da` 累加至频率 `f(a,t)` 对应的网格：这就是同步压缩。代码中的 `freq_bin_Hz` 仅定义显示/离散网格，并不表示物理频率分辨率，也不意味着 100 Hz 网格能以 100 Hz 分辨相邻物理频率。

## 5. 为什么加了“连续相位导数细化”

单纯从 100 Hz 的 SSWT 频率网格读出峰位置，会带来频率量化误差。代码先用 SSWT 锁定目标脊线，再选附近尺度上的相位导数，以 `|W|^2` 加权平均进行子频率网格级的细化。因此输出是 **SSWT 脊线辅助的精细化拍频估计**，而不是简单的 SSWT 频率 bin 中心值。

当前脊线跟踪只支持一个平滑的主要拍频分量；具有多个强反射点的辅助干涉仪信号，需要后续新增多脊线追踪与分量身份管理。

## 6. 图与指标应如何解读

- 图 4：手写 STFT、Morlet CWT、SSWT 时频图。白虚线为真值，红线为提取脊线。SSWT 的能量更窄并不自动等于更准确的轨迹估计。
- 图 5：三方法的瞬时拍频估计与估计误差（Hz）。**拍频 RMSE 只在中间 90% 样本上统计**，减少变换边界影响。
- 图 6：真实/恢复光频与波长，以及校准残差。**光频、波长 RMSE 在整个扫频上统计**，因为积分的累积误差不可忽略。
- 终端打印算法耗时：SSWT 总耗时包含 CWT，不应将只做重分配的时间和完整 STFT 比较。

时间-频率集中度的 Rényi 熵若采用不同频率轴网格，则数值不可直接公平比较；当前程序计算参考值，但不用于 SSWT 与 CWT 的主要排名依据。

## 7. 参数建议与实验步骤

1. **先验证纯音与无噪声**：执行 `smoke_test_v2` 与 `cfg.sim.add_noise=false`。
2. 默认 SNR=25 dB，查看 STFT/CWT/SSWT 的拍频与光频轨迹 RMSE。
3. 将 `cfg.sswt.voices_per_octave` 分别改为 12、24、36、48，观察精度与时间。
4. 将 `cfg.sswt.freq_bin_Hz` 改为 50、100、250；观察时频图变化与轨迹估计误差。
5. 将 `cfg.aux.snr_dB` 设为 15、25、35 dB；比较脊线稳定性。低 SNR 下可能需要增加跟踪约束。
6. 修改 V1 的 `cfg.laser.ripple_a` / `drift_b`；确保 `|a|+|b|<1` 且辅助/主拍频未超过 Nyquist。

## 8. 小波边界相位失真的处理

对于实值余弦的解析 Morlet 小波，镜像延拓后的边界干涉条纹可能等效于相位翻折，因此靠近扫频起点或末端时，CWT 相位导数偶尔出现明显的非物理拍频跳变。因为**光频估计采用累计积分**，即使边缘只出现很短的跳变，也会引入贯穿整个扫描的光频偏差。

默认 `cfg.sswt.edge_extrapolate=true`：从内部可靠频率估计中，截取一小段平滑曲线进行局部二次外推，替代最前/最后一小段受污染的脊线。相同边界修正原则也应用于 CWT/STFT 基线。这个步骤不是 SSWT 的核心数学定义，而是利用本项目假设的“扫频速率随时间平滑变化”进行边界处理。

**对扫频真正存在骤变、跳变或外推窗严重含噪的情况，必须关闭此开关并采用其他边界估计方式**。建议自己先比较关闭前后的波长残差，直观理解为何频率积分对边缘估计敏感。

## 9. 当前限制和常见问题

- MATLAB 2020b+；仅需基础数值函数（包括 `fft`、`ifft`、`movmean`、`accumarray`、`interp1`、`cumtrapz`）。
- 当前采用频域解析 Morlet 近似及镜像延拓，不实现可逆 CWT、锥形影响区域 (COI) 的精确遮罩或小波自适应参数优化。
- 真实 OFDR 的激光线宽、相位噪声、光学器件误差等仍未建模。
- 波长误差单位：`fm` = 1e-15 m；它不等于 OFDR 的空间分辨率。
- 提升频率网格密度可能让图像更细，但不会凭空提高数据的有效信噪比或真实分辨率。
- 如果出现异常结果，请保存报错信息、MATLAB 版本以及当前 `cfg` 设置，再对照 `smoke_test_v2` 定位。

## 10. 与文献的对应

- Dang et al. (2022), *Optics Express*, DOI 10.1364/OE.477771：式 (1)–(3) 说明辅助干涉拍频与光频轨迹关系，式 (4)–(6) 对应 CWT 与 SSWT。
- Ding et al. (2012), *Review of Scientific Instruments*, DOI 10.1063/1.4729376：NUFFT 的 Gaussian Gridding 属于 V3，**不在 V2**。
