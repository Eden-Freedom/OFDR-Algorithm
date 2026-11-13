# V6d / V7 36 次配对实验结果判读（2026-11-13）

本记录根据用户在 MATLAB 中运行的 **36 次 V6d**、**36 次 V7** 日志与图像制作。所有统计来自运行输出；未擅自增加 MATLAB 实测数值。脚本仍须由使用者在 MATLAB 中回归运行。

## 1. 状态结论

- **V6d：机理实验成功**。当前模拟中，非仿射差分光频残差比单独锚定比例坡度更强地破坏静止区相位 / 虚假应变；然而 Core RMSE 的分量差异较小，不能据此称其“主导所有误差”。
- **V7：初步有效但贡献有限**。SAPC 相较原始 Independent SSWT，平均 Core RMSE 下降 0.0099 με，**配对 bootstrap CI95 = [0.0053, 0.0149] με**；静止持出区 RMS 从 0.2922 降到 0.2745 με；有效率从 90.3% 到 90.4%。对当前固定模型/参数和已测种子，可认为改善可观测，但不能声称泛化、独立创新或工程优势。
- **更重要的基线**是 Static affine：Core RMSE = 0.2189 με、持出区 = 0.2842 με。SAPC 只比它低约 0.0049 με（Core）及 0.0097 με（持出区）。当前输出**没有提供 SAPC vs affine 的配对置信区间**；这是下一项必做检验。
- V7 需要**已知上游未受应变参考区**、相同实际 TLS 轨迹等假设，主干涉探测噪声仍关闭。不能把一项受限模型实验当成实际仪器完成验证。

## 2. 路径警告与修复

此前：
\`\`\`matlab
% config_v6d.m; here = .../matlab/v6d
addpath(fullfile(fileparts(here),'../v6c')); % 错：等价于 .../v6c
% config_v7.m; here = .../matlab/v7
addpath(fullfile(fileparts(here),'../v6d')); % 错：等价于 .../v6d
\`\`\`

已修复为：
\`\`\`matlab
% matlab/v6d/config_v6d.m
addpath(fullfile(fileparts(here),'v6c'));
% matlab/v7/config_v7.m
addpath(fullfile(fileparts(here),'v6d'));
\`\`\`

MATLAB addpath 对不存在路径的警告不等于求值失败。其他入口可能已经正确添加必要路径；验证：\`which config_v6c -all\`、\`which config_v6d -all\`、\`which v6c_forward_pair -all\`、\`which v7_static_phase_fit -all\`。更新后重新启动 MATLAB 或执行 \`rehash\`，分别重跑 smoke。

## 3. V6d 数据：36 次成功、0 失败

| 组别 | Core RMSE (με) | 静止区 RMS (με) | Gauge phase RMS (rad) | Core 均值 bootstrap 95% CI |
|---|---:|---:|---:|---|
| no_diff | 0.2077 | 0.0313 | 0.01129 | [0.2019, 0.2141] |
| ramp_only | 0.2132 | 0.0540 | 0.01214 | [0.2068, 0.2200] |
| nonlinear_only | 0.2166 | 0.2189 | 0.02012 | [0.2093, 0.2236] |
| full_diff | 0.2240 | 0.2280 | 0.02089 | [0.2164, 0.2310] |

**关键解释**：

1. \`no_diff\` 是参考与测量共用**带误差的参考 SSWT 坐标**，**不是** oracle/oracle。其 Core RMSE 仍大于 0。
2. 静止区：非仿射组与 full 接近，坡度组远低于 full，支持“非仿射残差是虚假应变的重要因素”。
3. Core: ramp 与 nonaffine 都让 RMSE 上升，full 通常更高；不能将 RMS 简单相减后归为正交贡献。需继续看配对差 CI、强度与散射条件依赖。
4. 分解使用 \`truth.nu_offset_Hz\` 和真实参考权重，是**oracle 机理诊断**，不能把该分解直接当作 V7 可部署校正器。
5. Figure 2 上图的点如果落在 y=x 下方，代表 nonlinear-only Core RMSE 小于 full；下图表明 slope 和 nonaffine RMS 跨 trial 有分布，不能单凭散点声称二者不相关。

## 4. V7 数据：36 次成功、0 失败，施加 5 με

| 方法 | Core RMSE (με) | 持出静止区 RMS (με) | 有效 gauge (%) |
|---|---:|---:|---:|
| Oracle | 0.1092 | 0.0121 | 91.1 |
| Independent SSWT | 0.2239 | 0.2922 | 90.3 |
| Smoothed SSWT | 0.3701 | 0.5253 | 89.9 |
| Static affine | 0.2189 | 0.2842 | 90.4 |
| SAPC | 0.2140 | 0.2745 | 90.4 |

相对 Independent SSWT：
- Core 平均误差下降 \`(0.2239-0.2140)/0.2239 ≈ 4.42%\`；绝对收益 0.0099 με，配对 bootstrap [0.0053,0.0149] με。
- 下游静止持出 RMS 下降约 \`(0.2922-0.2745)/0.2922 ≈ 6.06%\`；**尚未报告配对 CI**。
- 平均有效比例只差 0.1 个百分点；**尚未报告配对 CI**。
- 相比 Oracle 的误差缺口从 0.1147 缩至 0.1048 με；在这个固定条件下消除了约 8.6% 的缺口，距离理想状态仍明显。

相对 Static affine，SAPC Core 绝对收益仅 0.0049 με，不能在未检验配对 CI 的条件下宣称“非仿射模型有明确额外贡献”。

Figure 1：总体表现和持出分数；Figure 2：每一个配对 trial，低于对角线才代表该次改善（并不是全部试次都改善）；Figure 3：视觉上 5 με 平台与真实曲线重合，但必须读 Core Bias/ RMSE、边缘位置与静止区虚假应变，不能靠峰高重合下结论。

## 5. 必做：针对 affine 与静态持出区计算配对置信区间

运行后，从 \`main_v7\` 的输出 \`results\` 读取数组。**不要**对每个距离像素 bootstrap，独立样本单位是整次 trial。

\`\`\`matlab
[cfg, r] = main_v7();
good = r.success;
% 列：1 oracle, 2 raw SSWT, 3 smooth, 4 static affine, 5 SAPC
gain_affine = r.core_rmse(good,4) - r.core_rmse(good,5);
gain_holdout = r.static_holdout(good,2) - r.static_holdout(good,5);
gain_affine_holdout = r.static_holdout(good,4) - r.static_holdout(good,5);
gain_valid = r.valid_fraction(good,5) - r.valid_fraction(good,2);
fprintf('SAPC vs affine Core: %.5f ue\n',mean(gain_affine));
fprintf('SAPC vs affine holdout: %.5f ue\n',mean(gain_affine_holdout));
fprintf('SAPC vs raw SSWT holdout: %.5f ue\n',mean(gain_holdout));
fprintf('SAPC minus raw valid fraction: %.4f percentage points\n',100*mean(gain_valid));
% 使用现有基础函数
[lo,hi]=v6b_bootstrap_ci(gain_affine,2000,20261113);
fprintf('SAPC vs affine core 95%% CI [%.5f, %.5f] ue\n',lo,hi);
[lo,hi]=v6b_bootstrap_ci(gain_holdout,2000,20261114);
fprintf('SAPC vs raw holdout 95%% CI [%.5f, %.5f] ue\n',lo,hi);
[lo,hi]=v6b_bootstrap_ci(gain_affine_holdout,2000,20261115);
fprintf('SAPC vs affine holdout 95%% CI [%.5f, %.5f] ue\n',lo,hi);
\`\`\`

> 若重跑时 \`cfg.v7.repeats\` 被恢复为 8，请显式设置为 36 并调用 \`main_v7(cfg)\`，否则不应把 8 次演示 CI 当作 36 次结果。

## 6. 后续论文决策与防止过拟合

1. **单独比较 SAPC vs affine 的配对 CI**，以及所有试次改善/退化比例，不仅比较两个均值。
2. **锁定超参数后用全新随机种子与散射体**评估；这 36 次数据已用于设计和判断，不得再次当独立盲测集。推荐 100 次配对外部复现，记录失败率。
3. 扫描静止参考段长度/位置、辅助 SNR、不同真实 TLS 轨迹与起止频带、应变幅度（0/1/2/5/10/20 με）、gauge 长度、Rayleigh fading；确保 SAPC 不仅对默认 5 με 有效。
4. 评价完整运行时间（校准+迭代多次 NUFFT+解调）及静态参考段额外硬件条件。
5. 与严格匹配的普通平滑、同阶低维多项式、不使用非仿射校正、现有双扫描对齐/相位校正方法公平比较，避免把实现差异包装为原创性。
6. 当前模型主干涉仪无探测噪声，无法保证真实实验性能；有条件时加入实测数据。

**阶段判定**：V6d 实现了预设机理目的；V7 在当前固定合成条件下显示小幅正收益，尚未证明“相位保真非仿射方法”优于简单仿射校正，更不能形成已验证的论文创新结论。
