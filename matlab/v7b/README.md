# V7b 快速开始

V7b 冻结 SAPC 超参数，以 100 次全新独立种子做配对盲测，并提供失效机理诊断和物理条件泛化实验。**不修改 V7 算法本体**，只给 `run_v7_trial.m` 增加诊断字段。

在 MATLAB 仓库根目录运行：

```matlab
addpath('matlab/v7b');
smoke_test_v7b;
[cfg,results] = main_v7b();                 % 100 次主测试
```

运行预先规定的 17 组物理泛化：

```matlab
cfg=config_v7b();
cfg.v7b.run_blind=false;
cfg.v7b.run_conditions=true;
cfg.v7b.condition_repeats=12;             % 预览；正式每条件 >= 30
[cfg,conditions]=main_v7b(cfg);
```

- [实验指南](../../docs/V7B_EXPERIMENT_GUIDE.md)
- [逐图判读](../../docs/V7B_FIGURE_READING_GUIDE.md)
- [冻结的研究协议](../../docs/V7B_PRE_REGISTERED_PROTOCOL.md)

V7b 仍假设有已知静止上游参考段、两扫描的真实 TLS 轨迹相同、主探测器噪声关闭；结果不是实际仪器精度的证明。
