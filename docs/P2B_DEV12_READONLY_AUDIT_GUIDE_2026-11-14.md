# P2b 已保存12次开发集：只读审计和两张补充图（2026-11-14）

> 代码已提交GitHub，但新的只读诊断工具**尚未经用户MATLAB实机验证**。只使用已保存 `P2B_DEVELOPMENT_results.mat`。不重新生成Rayleigh散射、不重新算SSWT、不重新拟合任何参数、不消费冻结种子。

## 一、MATLAB命令（在目前P2b研究分支，仓库根目录）

```matlab
!git pull --ff-only
addpath('matlab/mechanism_p2b');
clear p2b_readonly_audit_dev12 smoke_test_p2b_readonly_audit
clear p2b_plot_readonly_dev12
rehash

% 1. 数学/失败分母合成数据自检（不生成物理随机数）
smoke_test_p2b_readonly_audit

% 2. 只读取以前已经保存的开发结果（不会重跑12次）
[T,d]=p2b_readonly_audit_dev12();

% 3. 查看全部12次试次与失败原因；不会隐藏失败
disp(T);
disp(d);

% 4. 补充两张试次级诊断图
p2b_plot_readonly_dev12(T,d);

% 5. 可选：把新诊断结果导出到单独CSV，不覆盖原12次文件
folder=fullfile('matlab','mechanism_p2b','output');
writetable(T,fullfile(folder,'P2B_DEV12_READONLY_AUDIT.csv'));
```

`smoke_test_p2b_readonly_audit` 是纯合成 trial 表测试；它故意制造3个trial中1个失败，以检查失败分母。其2/3成功和33.33%失败**不代表真实开发集又出现失败**。真实开发集仍为12/12成功。

## 二、主终点（不改变原先协议）

`ε=5με, α=1`，对每个真实试次报告实际增量`C_actual`、预测增量`C_pred`、有符号残差`C_actual-C_pred`、绝对误差、相对误差、相对`C=0`的配对绝对收益和最差绝对预测误差。原协议已固定的主终点CI直接从存盘的`r.summary.gain_CI95`读取，不做第二次bootstrap，不调整种子或选择有利试次。

三个*探索性*（POST-HOC）统计量：

- `quadratic-only = α²<g²>`：把真实应变残差参与的线性交叉项`2α<r0,g>`去掉，用来诊断Oracle残差交叉项是否决定预测精度。**仍需要真实光频构造g，不是可部署校正器**。
- `LOO constant`：对某trial，只用剩余成功trial的真实C值均值预测该trial C；这是一种训练于其他已查看真值标签的**事后常数对照**，不是无真值的实时基线，也不是独立盲测。
- 两步长导数的`RMS(g_0.05-g_0.10)/RMS(g_0.05)`：检查是否有单个试次的局部导数估计不稳定，不能因此事后修改原来的`h=0.05`。

以上新增探索性对照**不得用于修改、替代或重解释**原已预先固定的`gain_CI95`，也不能根据它们在当前数据上的表现选择新的参数然后宣称冻结验证。真正的论文推断必须建立独立的无真值观测模型、固定参数与独立物理条件。

## 三、Figure 6：每个trial实际C与预测C的配对散点

横轴：12个完整开发trial各自的`C_actual(5με,α=1)`，单位(με²)；纵轴：同trial的`C_pred`，单位(με²)。虚线为`y=x`，越靠近表明该trial的方向导数对C估计越准确。该图可以检查平均曲线重叠是否掩盖了散点的系统性失配。12个trial才是独立统计单位，空间Gauge不是12×500独立样本。

## 四、Figure 7：主终点逐trial四类预测绝对误差

横轴：完整开发trial编号（非时间序列，折线连接仅便于看数）；纵轴：`|C_actual-C_prediction|`，单位(με²)。四组：

- 原P2b预设的已知真值方向导数模型；
- 原预设的零效应预测 `C=0`；
- 事后仅二次项预测；
- 事后留一trial常数预测。

在这些对照上，全模型若表现良好，仍然只能说明知道`qtrue/e_c/r0`时该仿真映射可准确局部预测；**不说明实际OFDR能从辅助波形恢复这些量。**

## 五、后续主要科学决策

与其直接让同一固定模型做更多种子、α网格测试，应该优先开展`docs/P2C_OBSERVABILITY_RESEARCH_GATE_2026-11-14.md`的P2c-A无真值辅助MZI观测算子可辨识性研究。它旨在给出哪些共模误差自由度可由实际辅助相位识别、哪些必须通过已标定延迟/静态段/额外观测提供约束的条件性答案；之后再决定是否存在值得开发的新的可部署算法。

冻结测试继续锁定。MATLAB任何新代码报错先报告ID/Reason/Stack，不更改已经看过的12次结果。
