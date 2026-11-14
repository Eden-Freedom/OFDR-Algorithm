# V7c：Trial 19 非仿射幅度门控的提前拒绝（开发集事后研究记录）

> 数据来源：用户 Windows MATLAB 的24次开发集和只读诊断；非独立冻结试验。算法及冻结协议 `V7C_CV_SAPC_2026-11-13_B` 均未改变。下面所有性能数值仅为开发集描述。

## 1. 实机证据与算法结论

- 诊断单元测试和24次开发集读取均正常。24/24成功、13次 affine 回退、8次 alpha=1、3次部分混合；接受非仿射后相对 affine Core 是5胜/6负。
- 回退到 affine 的13次中，有7次事后根据真值评分发现 Full SAPC 的 Core RMSE 更低；这只表明反事实错失，并非算法可观测的真值信息。
- Trial 19：alpha=0，回退原因 `non-affine correction size gate`，`cv_gain_fraction=NaN`，data Hessian rcond=0.00016988，Affine与CV有效位置比例均为0.89641。

| Trial 19 指标 | Static affine | Full SAPC | CV-SAPC |
|---|---:|---:|---:|
| Core RMSE (με) | 0.22132 | 0.18782 | 0.22132 |
| Holdout RMS (με) | 0.3239 | 0.2269 | 0.3239 |

相对 Full SAPC，Trial 19 的 CV Core 退化0.033498 με、Holdout退化0.0970 με；Full SAPC相对Affine的这两项误差约低15.1%与29.9%。

## 2. 为什么 NaN 不是 CV 预测失误

已重新核对 `matlab/v7c/v7c_cv_gate.m`：首先初始化 alpha=0、cv_folds_ok=false、cv_gain_fraction=NaN，然后先做未正则 Hessian/rank 检查；接着检查完整SAPC相对Affine的额外修正峰值。若大于固定0.8 MHz则立即设置 `non-affine correction size gate` 并 return。两折 CV 循环位于 return 之后。所以 Trial 19 **没有执行折内CV**，NaN表示未计算，不代表CV评分很差。需要直接读取 `results.development.extra_peak_MHz(19)` 才能报告确切峰值，当前不能捏造数值。

## 3. 数学上值得进一步研究的设计边界（尚未验证新算法）

记 E=max_t |q_sapc(t)-q_affine(t)|，完整模型的额外修正阈值 L=0.8 MHz。现有V7c规则只要 E>L 就直接 alpha=0，但混合模型 `q_alpha=q_affine+alpha*(q_sapc-q_affine)` 的额外幅值为 alpha*E。因此 E>L 并不意味着所有 alpha>0 候选都超限。例如E=1.2 MHz时，alpha=0.25/0.5满足单独幅度约束，而alpha=0.75/1超限。

这是**可解析的规则结构性质**，并非实际新算法收益证据。其他必要条件包括单调性、相对原始坐标的总修正不超过5MHz、折内拟合有效及真实Core/Holdout泛化。不能把现有V7c的'完整修正先验门限'偷偷修改成'逐alpha可行性门限'。若要研究这种策略，应另建V7d协议和完全新种子。

## 4. 为什么图2下图可能漏掉最差试次

旧Figure 2下图横轴使用 `r.cv_gain_fraction(good)*100`，Trial 19该值为NaN，因此该点不显示。注意纵轴是相对Affine的Core改善，在Trial 19因回退α=0而为零；所谓0.033498 με的最差退化则**相对Full SAPC**。禁止将二者混淆。所有trial仍必须计入统计与CSV，不能只看可见散点。

## 5. 利用现有结果做只读审计（无冻结集）

新文件 `matlab/v7c/v7c_audit_size_gate_dev.m` 从已保存 `V7c_development_results.mat` 读取 `extra_peak_MHz`、门控原因、CV是否真正运行，以及每个候选alpha是否满足**单独的额外修正幅度上限**。另有纯合成数据单元测试 `smoke_test_v7c_size_gate_audit.m`。两者尚未经过用户MATLAB实机验证。

```matlab
!git pull --ff-only
addpath('matlab/v7c');
clear v7c_audit_size_gate_dev smoke_test_v7c_size_gate_audit
rehash
smoke_test_v7c_size_gate_audit
[T,a]=v7c_audit_size_gate_dev();
disp(T(T.trial==19,:));
disp(a.refused_candidates_cell{19});
```

候选输出仅反映 `alpha*E<=0.8` 的必要幅度条件，不是CV评分，不代表应变精度提高，也不是可直接部署的可行解。真值Core/Holdout只用作事后评价，绝不返回真实算法拟合。

## 6. 统计敏感性与下一步

24次CV相对Full SAPC的Core gain均值 -0.00086688 με；Trial19 gain=-0.033498。若仅做 leave-one-out 敏感性计算，剩余23次均值约+0.000552；不允许删Trial19作为主结果。Holdout gain均值 -0.002554；同理去除Trial19的 -0.097 后约+0.00155。这说明均值对极端试次敏感，不等于方法平均风险已被改进。

当前优先确认Trial19的E实际数值，并比较全部提前拒绝试次的门控原因与物理误差。暂不运行100次冻结测试、不调参、不宣称论文创新。