# V6d：非零应变条件下的配对校准残差消融（36 trials）

**研究问题**：V6b 单个试次发现非仿射差分残差可能比线性斜率更影响 gauge 相位，这个观察能否在 V6c 的真实非零应变正演链中重复出现？

本版本属于**机制诊断**。误差分解依赖真实光频轨迹，它不是可以实际部署的校正方法。所有比较都保持相同瑞利散射体、同一受应变主信号和同一参考 SSWT 估计，并使用**同一 trial 内全部分支共同有效的 core/static 掩码**评分。

## 操作

在项目根目录的 MATLAB 命令窗口：

```matlab
!git pull --ff-only origin main
addpath('matlab/v6d');
smoke_test_v6d;
[cfg,results] = main_v6d();
```

默认：`repeats=36`，`applied_microeps=5`，bootstrap `2000` 次，保存 `matlab/v6d/output/`（`.mat`、CSV、PNG）。初次测试可设 `cfg=config_v6d(); cfg.v6d.repeats=4; cfg.v6d.bootstrap_reps=200; main_v6d(cfg);`。

## 四个分支

| 分支 | 参考扫描光频 | 测量扫描光频 | 说明 |
|---|---|---|---|
| `no_diff` | SSWT reference | 同一 SSWT reference | 两次扫描使用相同误差的控制；仍有非零真实应变 |
| `ramp_only` | SSWT reference | reference + SSWT 差误差的锚定坡度 | 仅比例漂移 |
| `nonlinear_only` | SSWT reference | reference + 锚定非仿射差误差 | 仅非线性分量 |
| `full_diff` | SSWT reference | 独立 SSWT measurement | 两次独立 SSWT 的完整差误差 |

注：`full_diff = ramp + nonlinear` 在首样本锚定后的数值分解中成立，程序检查分量相加最大残差低于 `1e-3 Hz`。单独分支的 *RMS 不可简单相加* 得到完整分支。

## 必查字段

- `results.summary.n_success` / `failure_rate`：完整 trial 是否有效，失败不能当成零误差。
- `results.core_rmse`：每次 trial × 4 分支，单位 **με**；使用真实应变的 gauge 平均场作真值。
- `results.static_rmse`：静态区虚假应变 RMS，单位 **με**。
- `results.gauge_phase_rmse`：gauge 相位相对于理想真实应变的 RMS，**rad**。
- `results.common_valid_fraction`：每个 trial 的共用有效 gauge 比例。
- `results.summary.ci_core` / `paired_gain_ci`：基于 trial、不是像素的 bootstrap CI。
- `results.slope_ppm`、`nonaffine_weighted_MHz`、`diff_total_rmse_MHz`：诊断误差的形态。

**决策门槛**：若 `nonlinear_only` 在大多数试次中接近 `full_diff` 而 `ramp_only` 较小，支持优先建模非仿射残差。若相反，则修改研究假设。不能仅凭单个典型试次或回归拟合给创新性结论。

## 物理范围与公平性

复用 V6c 的 5 με 已知轴向应变、合成 Rayleigh 散射、V2 SSWT 和 V3 Gaussian NUFFT。主信号噪声关闭，真实扫描相同；9-bin 复相位空间平均增加支持长度。所有参数、初始种子和失败原因保存。尚未检查两次真实扫频不同的情形，不构成完整工程或实验级验证。

[逐图阅读](V6D_FIGURE_READING_GUIDE.md) ｜ [V7 算法原型指南](V7_EXPERIMENT_GUIDE.md)
