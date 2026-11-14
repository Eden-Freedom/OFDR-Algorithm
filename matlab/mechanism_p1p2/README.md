# P1/P2 OFDR 机制研究：非零应变共模/差模误差（开发版）

**只读历史，独立新实验目录。** 保留 V6–V7d 源码不变，禁用冻结测试。

研究材料与关键路径：

- [协议：P1P2_MECHANISM_DEV_PROTOCOL_2026-11-14.md](../../docs/P1P2_MECHANISM_DEV_PROTOCOL_2026-11-14.md)
- [MATLAB 操作指南](../../docs/P1P2_MATLAB_RUN_GUIDE.md)
- [逐图阅读指南](../../docs/P1P2_FIGURE_READING_GUIDE.md)
- [V7d 同分母有效率勘误](../../docs/V7D_COVERAGE_ERRATUM_2026-11-14.md)

在仓库根目录 MATLAB 命令：

```matlab
addpath('matlab/mechanism_p1p2');
smoke_test_p1p2;           % algebra + NUDFT + 两个新开发试次
smoke_test_p1_density;     % 2次嵌套散射自检
% 仅在两个smoke都通过后再进行探索：
cfg=config_p1p2();
cfg.p1p2.run_p1_density=true;
[cfg,results]=main_p1p2(cfg);
```

**尚未在 MATLAB 实机运行，暂无新的科研结果。** 两次smoke不能用于声称论文显著性。P1是物理与数值审计；P2采用真实坐标注入，因此不代表可部署校正算法。