# P2c-A：理想辅助MZI光频可观测性数学审计

这是P2b发展后的**独立纯数学模块**，仅分析延迟积分观测的秩与不可区分参数反例，不调用Rayleigh散射、实际应变、真值校准器或冻结随机数据。

仓库根目录：

```matlab
addpath('matlab/mechanism_p2c_a');
smoke_test_p2c_a_math
cfg=config_p2c_a();
[cfg,results]=main_p2c_a(cfg);
```

- `p2ca_integral_matrix.m`：完整时窗上精确积分，支持非整数τ/dt。
- `main_p2c_a.m`：单/双延迟矩阵数值秩、周期盲模态、未知φ0造成的光频常偏置、未知τ引起的线性扫频尺度歧义。
- `smoke_test_p2c_a_math.m`：纯合成、不消耗随机数的单元测试及冻结锁。
- `p2ca_plot_results.m`：三张图，全部只表示数学结构。

详细物理模型、预期数学秩表与局限见[研究协议](../../docs/P2CA_IDEAL_MZI_MATH_PROTOCOL_2026-11-14.md)及[MATLAB逐图指南](../../docs/P2CA_RUN_AND_FIGURE_GUIDE_2026-11-14.md)。

**P2c-A新增代码尚未通过用户MATLAB实机验证。** 本阶段也没有随机试次/Bootstrap/应变测量，因此不能把数学秩结论误记成新的独立物理校正实验。
