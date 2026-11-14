# V7d-PF 三幅MATLAB图：横纵轴、正确结论、错误结论与边界
 
> 适用对象：`v7d_plot_results.m` 当前生成的 **DEVELOPMENT** 图。全部图像只显示成功trial；标题/日志必须同时列出总试次数和失败率。图形不是冻结统计。
 
## Figure 1：平均Core与配对统计
 
**上图**：横轴为 Raw SSWT / Affine / Full SAPC / V7c / V7d-PF 五种方法（Oracle和Smoothed另在日志）；纵轴为受应变区 Core RMSE（με，越低越好）。必须比较 Full 与 V7c，而不是只与 Raw SSWT 比较。均值相近不能只凭柱子判断统计显著性。
 
**下图**：横轴 C/A、H/A、C/Full、H/Full、C/V7c、H/V7c；C代表Core，H代表下游静止Holdout；纵轴为V7d减误差后对该基线的配对收益（基线RMSE - V7d RMSE，με），正值表明新方法更好。误差条为trial级Bootstrap 95%CI。若相对V7c的Core/Holdout区间跨零，不能证明本次唯一门控修改有稳定收益；CI均>0也不能等同硬件验证或论文新颖性。
 
**必须同时看**：`summary.failures`、`mean_valid`、`comparisons(4).wins/losses/ties/worst_regression`。
 
## Figure 2：配对trial胜负，尤其不能漏掉NaN CV分数试次
 
**上图**：横轴原V7c的Core RMSE（με），纵轴V7d Core RMSE（με）；虚线为y=x。下面的点表示V7d改善、上面退化、重合不变。
 
**下图**：横轴试次编号，纵轴每次V7c RMSE - V7d RMSE（με），含所有成功trial，避免沿用旧Figure2的横轴CV gain而隐去早期hard-gate的NaN评分。正值改善、负值退化、零值一致。**两者使用同一随机散射与噪声**。
 
**必须结合**：每次 `reason_v7c`、`reason_v7d` 和 `alpha_v7c/v7d`，确定是否只有E超限试次改变；不允许把所有改善归因于Trial19故事本身。
 
## Figure 3：α分布与额外修正幅度
 
**上图**：横轴α=[0,.25,.5,.75,1]，纵轴为成功trial数；一组柱子原V7c、一组柱子V7d。α=0是采用Affine校正，α=1等价于Full SAPC。两组分布差异证明选择决策变化，不是精度收益。
 
**下图**：横轴Full SAPC相对Affine额外修正峰值 E（MHz），纵轴V7d选择的α，颜色表示V7d相对V7c的Core配对改善（με）。竖虚线为0.8 MHz的**Full校正限幅参考线**；注意V7d对每个候选采用αE≤0.8，因此E>0.8仍可能选0<α<1。该图只显示成功试次，失败记录看CSV。
 
**局限**：同一静态光纤中的空间CV不具严格独立性；名义扫描带宽仍来自固定激光端点配置；主探测噪声关闭，双扫描真实TLS轨迹相同。不在单一场景上作工程泛化或论文原创性主张。
