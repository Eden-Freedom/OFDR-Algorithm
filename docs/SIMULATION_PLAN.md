# SSWT + NUFFT 面向 OFDR 的 MATLAB 仿真完整方案

**项目目标**：从基本原理出发，先验证两类算法各自的输入/输出与数值性能，再检验“SSWT 扫频轨迹估计 + NUFFT 空间重构”的联合流程。

**依据**：Dang et al. (2022) 的辅助干涉仪动态波长校准与 SSWT 时频重排原理；Ding et al. (2012) 的非均匀光频采样重构与 Gaussian Gridding NUFFT。**两者串联是本项目为学习和测试提出的架构，并非两篇论文直接提供的联合实现**。

## 1. 整体处理流程

```text
                                     +--> 辅助 MZI: s_aux(t)
                                     |            |
TLS 非线性光频 ν(t) -------------------+       CWT / SSWT
                                     |            |
                                     |       脊线 f_aux(t)
                                     |            |
                                     |       扫频速率 = f_aux / τ_a
                                     |            |
                                     |       积分恢复 ν_hat(t_n)
                                     |            |
                                     +--> 主 OFDR: s_main(t_n) ------> NUFFT --> R(z)

对照：不校准 FFT / 插值 FFT / 真值轨迹 NUFFT / 直接 NUDFT
```

**关键接口**：SSWT 的输出是每个采样点对应的瞬时光频坐标 `nu_hat_Hz`，并不是把 SSWT 时频图直接传入 NUFFT。后者的输入是主干涉信号与同长度的非均匀光频坐标 `(s_main, nu_hat_Hz)`。

### 四个可验收的版本

| 版本 | 工作范围 | 验收成果 |
|---|---|---|
| **V1** | TLS、辅助 MZI、主 OFDR 多点反射及基础 FFT | 真实轨迹、拍频、时域信号、原始空间反射谱；物理约束与数学自检 |
| **V2** | 自实现 Morlet CWT / SSWT、脊线、积分、基线 STFT | 拍频和光频校准 RMSE；时频图与误差曲线 |
| **V3** | 直接 NUDFT 与 Gaussian Gridding NUFFT、插值 FFT | NUFFT 数值精度、反射峰重构和运行性能 |
| **V4** | SSWT + NUFFT、SNR/非线性/参数扫描 | 统一对照表、空间分辨能力、稳健性、复杂度 |

## 2. 物理信号模型

### 2.1 可调谐激光器 (TLS)

将采样时刻写为 `t_n = nT/N`（`n=0,...,N-1`），令 `x=t/T`：

$$\nu(t)=\nu_0+\Delta\nu\,u(t),\qquad
\nu_0=\frac{c}{\lambda_{\rm start}},\quad\Delta\nu=\frac{c}{\lambda_{\rm end}}-\nu_0.$$

其中归一化光频函数为：

$$\boxed{u(t)=x+\frac{a}{2\pi m}\sin(2\pi mx)+b x(1-x)}.$$

相应瞬时扫频速率为：

$$\frac{d\nu}{dt}=\frac{\Delta\nu}{T}\left[1+a\cos(2\pi mx)+b(1-2x)\right].$$

参数 `a`（周期扰动强度）、`m`（周期数）、`b`（慢变化失真）可调整。`|a|+|b|<1` 是保证单调扫频的充分条件。以 `nu0 = c/(1550 nm)`、终点波长 1549 nm 为例，光频随时间增加，总光频带宽约 125 GHz。

> 数值实现中使用 `nu_offset_Hz = DeltaNu*u` 来计算干涉相位，避免直接对约 193 THz 光频做大数相减。要保留 `nu_Hz` 与 `lambda_m = c/nu_Hz` 作为物理真值。第一个和最后一个采样点不含整个扫描端点 `t=T`，但模型在数学上满足 `u(T)=1`。

### 2.2 辅助 MZI 拍频

定义包含光路单/双程系数的**有效总时延** `τ_a`。在短延迟、扫频变化缓慢近似下：

$$s_{\rm aux}(t)=A_a\cos\{2\pi\tau_a[\nu(t)-\nu_0]+\phi_a\}+\eta_a(t).$$

$$\boxed{f_{\rm aux}(t)=\tau_a\frac{d\nu(t)}{dt}}.$$

因而 `dν/dt = f_aux/τ_a`，对其积分并加已知起始光频基准可恢复光频轨迹。

**注意**：Dang 论文讨论的反射双程因子包含在相应物理相位公式中。本项目将其归入 `τ_a` 的定义中，不应再无条件乘 `2`。若模拟高精度相位或快变扫频，应改用严格的相位差 `Φ(t)-Φ(t-τ_a)` 而非冻结频率近似。

### 2.3 主 OFDR 反射点叠加

给定 `M` 个反射点位置 `z_j`，群折射率为 `n_g`，双程群时延：

$$\tau_j=\frac{2n_gz_j}{c}.$$

模型：

$$s_{\rm main}(t)=\sum_{j=1}^{M}A_j\cos\{2\pi\tau_j[\nu(t)-\nu_0]+\phi_j\}+\eta_{\rm main}(t).$$

`A_j` 表示归一化电域干涉**幅度**，不能直接视为功率反射率。`φ_j` 为散射相位。预设 `z=[0.450, 0.456, 1.250, 2.400] m`，其中两近端反射点相隔 6 mm，用于后续研究邻近峰是否分离。V1 不包含瑞利散射；V4 可添加大量随机弱反射点形成瑞利背景。

### 2.4 物理约束

- 激光光频轨迹必须单调；检查 `diff(nu_offset_Hz)>0` 和解析导数 `dν/dt>0`。
- 必须同时保证 `max(f_aux)`、所有 `max(f_beat,j)` 小于 Nyquist `fs/2`；对修改后的所有参数再次验证。
- 扫频光频带宽决定的理想距离尺度：

  $$\Delta z_{\rm theory}\approx\frac{c}{2n_g\Delta\nu}.$$

  它不等于实际反射峰 FWHM，也不等于 FFT 零填充后的显示间隔。
- 对非线性数据直接按均匀光频 FFT 会造成反射峰展宽。**V1 FFT 只作未校准基线**。

## 3. 初始配置（V1）

| 参数 | 默认值 | 用途 |
|---|---:|---|
| 起始波长 | 1550 nm | 固定起点 |
| 终止波长 | 1549 nm | 光频正向扫描 |
| 扫频时间 `T` | 20 ms | 单次扫描 |
| 样本数 `N` | 8192 | 采样时刻不包含终止点 |
| 采样率 `fs=N/T` | 409.6 kHz | 与拍频奈奎斯特条件配合 |
| 群折射率 `n_g` | 1.468 | 位置/群延迟换算 |
| 有效辅助时延 `τ_a` | 8 ns | 标称辅助拍频约 50 kHz |
| `a, b, m` | 0.12, 0.04, 2 | 两类扫频失真 |
| 反射位置 | 0.450, 0.456, 1.250, 2.400 m | 多峰信号 |
| 辅助 MZI SNR | 25 dB | 按交流信号功率计算 |
| 主信号 SNR | 30 dB | 同上 |
| 随机种子 | 2026 | 可复现实验 |

上述数值对应约 `125 GHz` 光频范围，理论空间尺度约 `0.82 mm`。任意参数变化都应重新检查最大拍频。

## 4. V1 具体模块、输出和验收

### 代码结构

```text
OFRD-Algorithm/
├── README.md
├── .gitignore
├── docs/
│   └── SIMULATION_PLAN.md
└── matlab/
    └── v1/
        ├── main_v1.m
        ├── config_v1.m
        ├── simulate_laser_sweep.m
        ├── simulate_ofdr_signals.m
        ├── validate_v1.m
        ├── plot_v1_results.m
        └── smoke_test_v1.m
```

**参数接口**：`cfg` 嵌套结构体；**真实值接口**：`truth`（`t_s`, `nu_Hz`, `nu_offset_Hz`, `lambda_m`, `tuning_rate_Hz_s`）；**观测值接口**：`signals`（辅助/主干涉信号、各反射点分量、真实拍频、时延）。

**V1 可视化**：TLS 非线性曲线（理想比较）、波长/速率/光频采样间距；辅助拍频波形和真值拍频；主信号时域与未校准 FFT 空间谱、真值反射位置。

**V1 验收**：
1. 所有矢量长度均为 `N`，无 `NaN/Inf`。
2. 光频严格递增，采样条件成立。
3. 模拟实际 `f_aux` 与相位差分得到的拍频一致。
4. 将扫频设为严格线性、关闭噪声后，对每个单反射分量使用常规 FFT 得到的峰值位置应接近真值（有限频率网格误差允许约一个距离 bin）。
5. 重复调用同一固定随机种子生成器，输出一致。

## 5. V2：SSWT 动态校准

目标：从 `s_aux(t)` 估计 `f_aux(t)`、`dν/dt` 与 `ν_hat(t)`。

### 5.1 自实现连续小波变换

使用**复 Morlet** 母小波，CWT 的连续形式：

$$W(a,b)=\frac{1}{\sqrt a}\int s(t)\,\psi^*\left(\frac{t-b}{a}\right)dt.$$

离散实现基于 FFT 卷积，不调用 `cwt()`；保留母小波频域定义、尺度与物理频率的对应关系、边界处理与归一化因子。

### 5.2 瞬时频率与同步压缩

在非零小波系数上利用

$$\widehat f(a,b)=\frac{1}{2\pi}\operatorname{Im}\left[\frac{\partial_b W(a,b)}{W(a,b)}\right]$$

或相邻复系数相位差近似，滤除低幅值系数并将 `(a,b)` 的系数分配到 `(f_hat,b)` 的频率网格。保留尺度权重以验证频率重分配是否正确，并且避免将压缩图谱的“更细”误认作真实估计 RMSE 一定更小。

### 5.3 脊线与积分恢复

基线：逐时刻频率峰值；改进：带连续性约束的脊线跟踪。根据

$$\widehat\nu(t)=\nu_{\rm anchor}+\frac{1}{\tau_a}\int_0^t\widehat f_{\rm aux}(\xi)d\xi$$

恢复各个采样点的光频；再换算波长 `lambda_hat = c / nu_hat`。

对照：STFT / CWT / SSWT；可选 Hilbert 相位解调。评价瞬时拍频 RMSE、光频 RMSE、波长 RMSE（fm）、Rényi 熵、脊线可用率、运行时间。单频、chirp 和多分量测试必须先于真实 MZI 多反射脊线测试。

## 6. V3：NUFFT 空间信号重构

### 6.1 直接非均匀 DFT（小数据参考）

$$R(z_k)=\sum_n w_n s_n\exp\!\left[-i2\pi\frac{2n_gz_k}{c}(\nu_n-\nu_{\rm ref})\right].$$

其中 `w_n=1/N` 可实现**等权离散求和**；若期望近似连续光频积分，可另设由光频采样间距计算的密度补偿权重，二者是不同数学问题，NUDFT 与 NUFFT 的比较必须统一权重。

### 6.2 Gaussian Gridding NUFFT

1. 将非均匀 `ν_n` 归一化；
2. 将每个样本通过高斯核扩散到邻近 `N_sp` 个均匀网格点；
3. 在 `K=αN` 过采样网格执行 FFT；
4. 通过高斯核在空间域的传递响应进行补偿；
5. 裁剪/定位目标空间坐标，检查 FFT 指数符号、周期边界与幅度缩放。

初值：`α=2`、`N_sp=8`；扫描 `α={1.25,1.5,2,3}`、`N_sp={4,6,8,12}`。Ding 论文采用的实验参数 `α=2, N_sp=12` 可作为参考配置。

对照组：未校准普通 FFT、线性插值+FFT、样条插值+FFT、直接 NUDFT、Gaussian NUFFT。指标：复谱相对误差、位置偏差、FWHM、PSLR、相邻峰可分性、运行时间和内存开销。不预设 NUFFT 必然比插值 FFT 快。

## 7. V4：联合实验与参数敏感性

| 分组 | 光频坐标 | 重构方法 | 目的 |
|---|---|---|---|
| A | 假定均匀 | 普通 FFT | 未校准参考 |
| B | 真实轨迹 | 插值 + FFT | 插值重构理想参考 |
| C | 真实轨迹 | NUFFT | NUFFT 理想参考 |
| D | SSWT 估计 | 插值 + FFT | 观察校准轨迹误差 |
| E | SSWT 估计 | NUFFT | 目标联合流程 |
| F（可选） | Hilbert 解调轨迹 | NUFFT | 其他校准技术对照 |

依次开展：理想线性/无噪声验证 → 强弱非线性扫描 → SNR 扫描 → 小波尺度/阈值扫描 → NUFFT 过采样/核宽度扫描 → 样本数增长 → 多次随机试验及置信区间。保留相同原始信号与噪声实现公平对比。

### 可视化清单

1. 线性、非线性真实扫频曲线和采样间距；
2. 辅助拍频信号与真值；
3. STFT/CWT/SSWT 时频图与脊线；
4. 光频/波长校准误差；
5. Gaussian Gridding 局部扩散原理图；
6. FFT/插值/NUDFT/NUFFT 空间反射谱及局部放大；
7. 非线性与噪声参数热图、误差统计；
8. 准确度—运行时间与样本数复杂度对比。

### 指标解释边界

**空间反射峰变窄不等于突破扫频带宽决定的理论距离分辨尺度。**必须区分峰宽 FWHM、理论分辨率及零填充 FFT 的坐标间隔。SSWT 可能改善拍频时频能量集中，但需以真实拍频和光频 RMSE 评估其校准性能。SSWT 轨迹带来的累积误差与 NUFFT 数值近似误差必须分别计算。

## 8. 实施约定与版本管理

- MATLAB R2020b+，以基础 `fft`、`ifft`、`interp1`、`cumtrapz`、`unwrap` 等为主，SSWT/NUFFT 核心从原理实现而不直接调用黑盒函数。
- 中文注释解释物理公式、单位和误差来源；脚本入口、模块和配置分开。
- 以 GitHub 提交区分阶段；保留测试入口及 README 使用说明。
- V1 的源码可能需要本地 MATLAB 运行调试；**未运行的程序不宣称已通过 MATLAB 执行**。
- 联合应用的科研新颖性及可发表性需单独文献查新，不能仅由算法组合形式判断。

## 9. 参考文献及原理论文位置

1. H. Dang et al., “Dynamic wavelength calibration based on synchrosqueezed wavelet transform,” *Optics Express*, 30, 46722–46733 (2022), DOI [10.1364/OE.477771](https://doi.org/10.1364/OE.477771)。辅助干涉仪拍频与扫频速率关系见式 (1)–(3)；CWT、SSWT 见式 (4)–(6)；光频校准及 OFDR 应用见图 2、5–8。
2. Z. Ding et al., “Note: Improving spatial resolution of optical frequency-domain reflectometry against frequency tuning nonlinearity using non-uniform fast Fourier transform,” *Review of Scientific Instruments*, 83, 066110 (2012), DOI [10.1063/1.4729376](https://doi.org/10.1063/1.4729376)。辅助 MZI 见式 (1)–(2)；非均匀重构、网格化与补偿见式 (3)–(5) 和图 2。

本文档中的扫频曲线、散射点与噪声模型是为可控仿真设计的，不意味着对原始论文实验数据或仪器硬件的原样复现。


---

## 10. V4 实施记录（2026-11-11）

V4 代码位于 `matlab/v4/`，实验指导位于 `docs/V4_EXPERIMENT_GUIDE.md`。将 V2 的 `calibration.sswt.nu_offset_Hz` 转成标称带宽归一化坐标后直接送入 V3 的 Type-1 NUFFT；同时比较未校准 FFT、真值坐标 NUFFT、真值/SSWT 插值 FFT。针对孤立反射点增加功率半高宽与 90% 能量累计宽度，以区分未校准谱的宽纹波与真实主瓣。已添加 `smoke_test_v4`、可选 `run_snr_sweep_v4`，等待使用者 MATLAB 本地运行验证。
