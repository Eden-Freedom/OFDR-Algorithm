# P1c 实机数值核查报告：相同固定 Core Gauge 上 NUFFT 与直接 NUDFT

> 2026-11-14 MATLAB 用户实机输出，原 P1a 已查看种子 `311201001`，**开发级确定性核查，不是独立随机验证**。功能实现未重调任何NUFFT精度、门控阈值、Core Gauge或物理参数。用户提供两幅MATLAB截图和完整命令行文本。

## 1. 功能与输入一致性

- `smoke_test_p1c_math`：`PASS: sparse bin union, 9-bin conv, equal-trace and bounds`。
- 真值坐标只用于数值 Oracle 审计，不是实际校正器输入。
- 固定原 NUFFT Oracle 选定的 Core Gauge `509/567`（约89.77%）；9-bin邻域覆盖575个Gauge；直接NUDFT仅对实际需要的587个独立谱点求和。
- 原有NUFFT所判有效的核心Gauge端点中，直接NUDFT光谱幅度低于原阈值的端点计数为`0/546`。
- 同一参考与测量物理波形、相同真实光频、窗、Voronoi密度权重和Gauge复数相位处理定义。

## 2. 实测数值与单位

| 项目 | 用户MATLAB数值 |
|---|---:|
| Reference 谱相对复数L2差 | 1.783e-5 |
| Measurement 谱相对复数L2差 | 1.864e-5 |
| Gauge圆周相位差 RMS (rad) | 9.3821732e-6 |
| Gauge相位差最大绝对值 (rad) | 3.52765e-5 |
| 直接 NUDFT − NUFFT 的Gauge应变差 RMS (με) | 0.0001029903 |
| NUFFT Oracle Core RMSE (με) | 0.14472769 |
| 直接NUDFT Oracle Core RMSE (με) | 0.14471644 |
| NUDFT − NUFFT Oracle RMSE差 (με) | -1.1257e-5 |
| RMSE差的严格反三角不等式上界 (με) | 0.0001029903 |

数值比值：Gauge逐点方法差 RMS / NUFFT Oracle RMSE = **约0.0712%**；两方法Oracle RMSE的实际绝对差 / NUFFT Oracle RMSE = **约0.0078%**。二者都**不是**Oracle误差的“独立贡献方差比例”，不能用于方差直接相减。严格地在本固定相同掩码上有：

`abs(RMSE_NUDFT-RMSE_NUFFT) <= RMS(eps_NUDFT-eps_NUFFT)`。

## 3. 逐图说明

**图1**：上图横轴固定Core Gauge中点距离(m)，纵轴直接NUDFT减NUFFT的应变数值差(με)，大多数位于±0.0002με内，局部尾部约±0.0004με。下图横轴绝对应变数值差的经验百分位(%)、纵轴绝对差(με)；**不是**trial级bootstrap区间。全部点来自同一散射实现且空间相关。

**图2**：横轴NUFFT和直接NUDFT，纵轴相同Core掩码下Oracle Core应变RMSE(με)；柱形重叠不能替代精准数据，差仅-1.1257e-5με，而方法间Gauge RMS差上界0.0001029903με。

## 4. 科研结论、尚未解决的风险

**可接受的有限结论：** 在本P1a已查看的开发seed、当前窗/密度/Gauge设置与Core有效集合下，直接NUDFT数值核替换没有实质性降低Oracle Core RMSE。支持“此配置下NUFFT近似不是Oracle误差差异的主要来源”，但不是全场景的真实物理Oracle噪声极限。

**未证明：** (a) 稀疏散射模型与连续Rayleigh随机过程一致；(b) 更低振幅、变化坐标、不同散射种子仍满足同一相位精度；(c) 9-bin空间平滑与应变边缘没有偏置；(d) 实际OFDR共模信息可观测；(e) 0.1447με的残余全部属于物理噪声。因此下一步应并行保留P1b散射密度和PSF/边缘响应审查，并在新的独立开发种子下做P2b的因果方向灵敏度研究。

## 5. 保持原始证据

- 当前实机命令：`smoke_test_p1c_math`，`a=run_p1c_gauge_audit();`
- 核查输出独立保存：`matlab/mechanism_p1p2/output/P1C_GAUGE_NUDFT_DEVELOPMENT.mat`、`P1C_GAUGE_NUDFT_DEVELOPMENT.csv`。
- 此文档不声称已运行新的P2b实验，不消费已预留的冻结试次。
