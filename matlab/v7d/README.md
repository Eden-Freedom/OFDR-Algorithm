# V7d-PF：逐候选可行性门控 SAPC（开发版）
 
仅在新开发种子上尝试移除V7c的“Full额外修正幅度超限→整个试次Affine回退”。保留原V7c算法为同试次对照，绝不修改旧版本。此版本的Frozen测试开关被主动锁定。
 
在仓库根目录、研究分支上运行：
 
~~~matlab
addpath('matlab/v7d');
smoke_test_v7d;             % 先测试2个开发试次
% 仅当smoke通过后：
cfg=config_v7d();
[cfg,results]=main_v7d(cfg);  % 默认24次新开发种子，非冻结测试
~~~
 
文档：[V7d开发协议](../../docs/V7D_DEV_PROTOCOL_2026-11-13.md) / [实验运行指南](../../docs/V7D_EXPERIMENT_GUIDE.md) / [逐图判读](../../docs/V7D_FIGURE_READING_GUIDE.md)。
 
研究代码未在用户MATLAB实机验证，当前没有任何V7d数值结果；不得在未经独立冻结试验前声称性能改善。
