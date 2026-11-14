# OFDR P2b：非零应变共模光频误差方向灵敏度预测（开发版）

此目录为**独立新实验**。保留V1–V7d与P1/P2/P1c历史版本，不回看冻结试次、不按真值拟合实际校正器。

本实验的真值光频qtrue与真实应变仅用于**机制扰动/Oracle评价**，不能称为实际可部署的扫频校正算法。当前真实物理模型仍使用V6c离散Rayleigh散射场、9-bin复相位平均、共同TLS扫描与主探测器无噪声的限制。

数学主线：

```
参考和测量辅助估计 -> 共模误差方向ec（真值诊断）
                   -> α=±0.05局部方向导数g
                   -> ε=5με, α=1的MSE增量C预测
                   -> 同trial实际C和“预测C=0”基线配对对比
```

相关文档：

- [开发协议与冻结隔离](../../docs/P2B_COMMON_SENSITIVITY_DEV_PROTOCOL_2026-11-14.md)
- [MATLAB操作指南](../../docs/P2B_MATLAB_RUN_GUIDE_2026-11-14.md)
- [五张MATLAB图逐图说明](../../docs/P2B_FIGURE_READING_GUIDE_2026-11-14.md)
- [P1c数值核查实机结果](../../docs/P1C_MATLAB_RESULT_2026-11-14.md)

在仓库根目录先运行：

```matlab
addpath('matlab/mechanism_p2b');
smoke_test_p2b
```

只有2/2完整smoke PASS后，才可运行预设12次新开发种子：

```matlab
cfg=config_p2b();
[cfg,results]=main_p2b(cfg);
```

**重要：当前新增P2b代码尚未在MATLAB实机验证，不存在任何P2b算法优越性实测结果。** 任何错误必须先记录ID/Reason/Stack，不修改冻结种子或针对试次调步长、应变、α。
