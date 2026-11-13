# V7c | Spatially Blocked CV-SAPC

本目录实现“已知上游静止区内部的阻塞交叉验证 + 可信度门控 + 仿射回退”。代码 **不改变 V7/V7b 既有算法**，在新种子上比较 CV-SAPC、Full SAPC、Static affine、Raw SSWT、平滑基线及 Oracle。

MATLAB 仓库根目录：

```matlab
addpath('matlab/v7c');
smoke_test_v7c;
[cfg,dev] = main_v7c();  % 默认 24 次开发集，不是独立盲测

cfg = config_v7c();
cfg.v7c.run_development = false;
cfg.v7c.run_frozen_test = true;
[cfg,test] = main_v7c(cfg); % 全新100次独立种子
```

报告请先看 [`docs/V7C_FIGURE_READING_GUIDE.md`](../../docs/V7C_FIGURE_READING_GUIDE.md) 及 [`docs/V7C_PRE_REGISTERED_PROTOCOL.md`](../../docs/V7C_PRE_REGISTERED_PROTOCOL.md)。不得用新的测试结果调参后仍称同一批数据是“盲测”。
