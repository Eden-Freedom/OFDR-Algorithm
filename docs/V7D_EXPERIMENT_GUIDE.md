# V7d-PF MATLAB 实验操作指南
 
## 一、目标和本次算法改动
 
只检查“完整Full SAPC额外修正超限时，是否仍有满足单项约束的可行α”，并在两折上继续按V7c原相位RMS选择候选。保持原V7c原样，使用七方法同一试次配对避免种子差异。
 
路径：`matlab/v7d`。代码只加入该新目录；原V7c/V7b/V7版本禁止随意修改。
 
### 先拉取研究分支
 
在仓库根目录、且已保存本地未提交修改的前提下：
 
~~~matlab
!git fetch origin
!git switch --track origin/research/v7d-pf-candidate-feasibility
addpath('matlab/v7d');
which config_v7d -all
~~~
 
如果本地已经有分支，请改用：`!git switch research/v7d-pf-candidate-feasibility` 后 `!git pull --ff-only`。
 
### 第一阶段：合成坐标单元测试
 
~~~matlab
clear v7d_candidate_feasible v7d_cv_gate v7d_run_trial
clear smoke_test_v7d_feasibility smoke_test_v7d
rehash
smoke_test_v7d_feasibility
~~~
 
预期最终显示单元PASS。这只是可行性公式与安全锁的**程序自检**。
 
### 第二阶段：2个全新开发种子 smoke
 
~~~matlab
smoke_test_v7d
~~~
 
验收预期：7方法配对2/2成功；Core/Holdout有限；共同Core/Holdout Gauge不少于15；新方法最终坐标总修正≤5 MHz、额外修正≤0.8 MHz。若失败，保留ID/Reason及堆栈，**不能为了通过测试直接改门限**。2个试次的改善/CI不能算科研证据。
 
### 第三阶段：24次开发集（仅在 smoke PASS 后运行）
 
~~~matlab
cfg=config_v7d();
cfg.v7d.development_repeats=24;
cfg.v7d.run_development=true;
cfg.v7d.run_frozen_test=false;
cfg.v7d.verbose=true;
cfg.v7d.make_plots=true;
cfg.v7d.save_results=true;
[cfg,results]=main_v7d(cfg);
s=results.development.summary;
disp(s);
disp(s.comparisons(2)); % V7d vs Static affine
disp(s.comparisons(3)); % V7d vs Full SAPC
disp(s.comparisons(4)); % V7d vs 原V7c（主对照）
disp(results.development.reason_v7d);
disp(results.development.failure_id);
disp(results.development.failure_reason);
~~~
 
结果目录 `matlab/v7d/output/`，保存 `V7d_DEVELOPMENT_results.mat` 与 `V7d_DEVELOPMENT_trials.csv`；图窗由 `v7d_plot_results` 生成，**默认不会自动保存图像文件**，可以从MATLAB中手动保存PNG/FIG并关联Git commit SHA。重复运行同名开发模式会覆盖前次MAT/CSV，请归档原始证据。
 
### 冻结阶段安全锁
 
**绝对不要执行V7d冻结测试**。当前对 `cfg.v7d.run_frozen_test=true` 会主动抛出 `V7d:FrozenLocked`，直到另行制定研究协议并解锁。V7b已经看过的冻结数据不能被重新用作V7d的调参/测试样本；V7c的预留冻结数据也不应被消费。
 
## 二、字段和科研解释
 
七方法顺序：Oracle、Raw SSWT、Smoothed SSWT、Static affine、Full SAPC、原V7c CV-SAPC、V7d-PF。
 
- `mean_core`：各方法受应变区域Core RMSE均值（με，越小越好）。
- `mean_holdout`：下游未训练静止区伪应变RMS均值（με，越小越好）。
- `mean_valid`：各方法有效Gauge位置比例；`mean_common_valid`：七方法共享有效比例。
- `comparisons(4)`：V7d相对原V7c的同试次配对增益与CI95，是首要消融。
- `alpha_counts_v7c/v7d`：预先固定五个α的实际选择分布。
- `changed_decision_count`：本次候选级约束是否真正影响了结果。
- `full_extra_peak_MHz`：Full SAPC相对Affine的额外修正峰值E，可与0.8MHz限幅对应。
- `full_candidate_ok`与`fold_candidate_ok`：仅新候选在全部训练/验证条件下的坐标合法性；不是实际应变精度的证明。
- `failure_id`/`failure_reason`：全部失败必须报告，不可去掉。
 
## 三、如果失败
 
若出现 `V7d:FrozenLocked`，检查是否误将冻结开关打开；这属于预期安全保护。其他错误保留命令行堆栈，不直接运行24次或100次。没有用户MATLAB实机结果时，任何V7d性能数值均**不能作为实测已证实**。
