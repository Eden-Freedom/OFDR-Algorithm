# P2b MATLAB 实验操作指南（开发期，仅限新种子）

在现有仓库根目录、已保存本地未提交修改的前提下执行：

```matlab
% 1. 切换新研究分支
!git fetch origin
!git switch --track origin/research/p2b-common-sensitivity-20261114

% 2. 独立新实验目录
addpath('matlab/mechanism_p2b');
which main_p2b -all
which p2b_run_trial -all

% 3. 清理函数缓存，先验证逻辑而非运行大样本
clear config_p2b p2b_assert_protocol
clear p2b_predict_local p2b_run_trial p2b_summarize
clear smoke_test_p2b_math smoke_test_p2b_summary smoke_test_p2b
rehash
smoke_test_p2b
```

如果本地已存在该分支：改用 `!git switch research/p2b-common-sensitivity-20261114` 后 `!git pull --ff-only`。不要使用 `git reset --hard` 覆盖用户本地未提交代码。

最小Smoke包括合成方向导数解析单元测试、统计与失败分母单元测试，以及2个新开发种子的四应变×七α完整物理链。预期最终出现 `[P2b smoke] PASS: 2/2 paired new development trials`，这是**预期格式，不是已有实测结果**。smoke如失败，将完整ID、reason、堆栈发回；不要修改α、步长或种子来强行通过。

## 在Smoke 2/2通过后运行开发集

```matlab
cfg=config_p2b();
cfg.p2b.development_repeats=12; % 包含前2次smoke
cfg.p2b.frozen_enabled=false;
cfg.p2b.run_frozen_test=false;
cfg.p2b.allow_frozen_test=false;
cfg.p2b.make_plots=true;
cfg.p2b.save_results=true;
[cfg,results]=main_p2b(cfg);

r=results.development;
s=r.summary;
disp(s);
disp(r.failure_id(~r.success));
disp(r.failure_reason(~r.success));

% 主科学结局：ε=5με、alpha=1的配对准确度
j=find(abs(s.strains_microeps-5)<1e-12);
v=find(abs(s.test_alpha-1)<1e-12);
fprintf('成功 %d/%d, 失败 %d\n',s.n_success,s.n_total,s.n_failure);
fprintf('Actual C: %.8g, Pred C: %.8g (με²)\n', ...
    s.mean_C_actual(j,v),s.mean_C_pred(j,v));
fprintf('Zero predictor MAE: %.8g, model MAE: %.8g (με²)\n', ...
    s.mean_null_abs_error(j,v),s.mean_abs_error(j,v));
fprintf('Paired MAE gain: %.8g [%.8g %.8g] (με²)\n', ...
    s.mean_abs_gain_vs_zero(j,v), ...
    s.gain_CI95(j,v,1),s.gain_CI95(j,v,2));
fprintf('Sign agreement %d/%d, model better %d, worse %d\n', ...
    s.n_sign_agree(j,v),s.n_nonzero_actual(j,v), ...
    s.n_prediction_better(j,v),s.n_prediction_worse(j,v));
```

保存目录：`matlab/mechanism_p2b/output/` 下 `P2B_DEVELOPMENT_results.mat`、`P2B_DEVELOPMENT_trials.csv`。绘图默认产生Figure窗口，不自动保存PNG；可手动使用 `exportgraphics`，并记录Git提交SHA。不要将2次smoke与12次开发相加成14个独立试次。

## 输出字段与特别风险

- `r.C_actual(t,j,v)`、`r.C_pred`：第t个独立trial、应变j、目标αv的实际/局部预测的MSE增量，单位(με)²。
- `r.pred_linear`、`r.pred_quadratic`：交叉项与方向导数平方项，可正/负与非负；二者之和等于预测C。
- `s.mean_abs_gain_vs_zero`与`s.gain_CI95`：相对固定零效应预测器的trial级配对绝对误差收益，是本轮首要评价。
- `r.gradient_h_difference`：h=0.05与0.10所估方向导数逐Gauge RMS差，单位με/α；局部数值稳定性指标，不是独立应变误差。
- `r.common_valid_fraction`、`r.common_core_count`：跨全部4应变、7 α 的固定共同有效空间位置；报告分母和分子。
- `r.failure_id/reason`：每个失败trial必须保留在12的分母。
- **Oracle信息限制**：真实光频和真实应变用于人为误差注入及对机制预测评分，不允许成为实际可部署光频校正或门控的输入。

## 科研注意

固定原V6c离散散射模型仍有未完全排除的P1b网格误差；不能将本轮P2b的拟合效果宣称真实硬件或连续Rayleigh过程的规律。仅当局部预测可以跨新散射试次稳定解释实际C并在后续独立场景复核，才可能进入真正的观测校准算法研究。
