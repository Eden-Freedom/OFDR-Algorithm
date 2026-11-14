# P1c：NUFFT/直接NUDFT在Gauge端点与最终Core应变上的数值一致性审计

> 状态：新数值审核代码已创建，**尚未运行用户MATLAB实机**；在已查看P1a开发seed上重算确定性的物理正演，不产生独立验证结论。原V6/V6c与P1/P2协议、历史输出、V7所有冻结数据不更改。

## 1. 研究动机与应回答的可证伪问题

现有P1a已知开发种子、80个ROI复数谱采样bin，NUFFT相对直接NUDFT的复谱L2误差为 reference 1.72×10⁻⁵、measurement 1.79×10⁻⁵；但相位敏感OFDR应变估计是Gauge端点的复比值经9-bin复平均和angle得到。局部低幅度点可能放大全局谱L2看不出来的相位误差。P1c目标是验证**原始数值近似在同一固定Core Gauge上的最终应变误差差异**，而不是研制新的校准算法。

## 2. 严格固定的输入

- 复用P1a已查看的散射seed=`cfg.p1p2.scatter_seed_base+200000`，同一真实TLS、同一reference/5με measurement正演，不在不同方法之间换散射系数或随机种子。
- 使用仅供数值Oracle评估的真实光频 `truth.nu_offset_Hz`；严格沿用V6的 `prepare_frequency_coordinates_v4`、窗口、Voronoi密度权重、相同空间bin、NUFFT固定参数。
- 核查范围取**原NUFFT Oracle结果定义**的所有 `core_valid` Gauge，中途不能按直接NUDFT得到的结果或应变真值再次筛选。
- Gauge端点 `I` 与 `J=I+lag`，9-bin复平滑 `conv(C(J)*conj(C(I)),ones(9,1)/9,'same')`，所需直接NUDFT位置是固定Core及其±4 Gauge邻域中所有参考/测量端点bin的去重集合。
- 对全部所需bin调用现有 `nudft_reference_v3`，使用与NUFFT同一原始信号、窗口、密度权重；不拟合补偿系数、不修改原函数或误差门限。

## 3. 数值比较量

在同一固定Core位置，定义直接与近似得到的应变 `eps_D(z)`、`eps_N(z)`：

- 复谱相对L2（只对所有实际参与Core Gauge计算的空间bin）：分别报告reference/measurement；
- Gauge相位圆周差 `delta_phi=angle(exp(1i*(phi_D-phi_N)))` 的RMS与最坏绝对值(rad)；
- 数值Gauge应变差 `delta_eps=eps_D-eps_N` 的RMS(με)，以及圆周相位等效的RMS(με)；
- **相同固定Core位置**上的Oracle RMSE：`RMSE_D`与`RMSE_N`(με)，带符号差 `RMSE_D-RMSE_N`；
- 报告原本被NUFFT判断为有效的位置中，直接NUDFT复谱有多少端点幅度跌破了**原固定**幅度门限；仅作诊断，不按这个数字删除数据。

同一真值与同一Gauge集合下，反三角不等式有：

`abs(RMSE_D-RMSE_N) <= sqrt(mean((eps_D-eps_N).^2))`。

代码验证该恒等上界；它是本次数据中NUFFT/NUDFT**数值差异对RMSE改变量**的约束，不是Oracle物理误差、连续散射模型误差或实际仪器噪声的上界。

## 4. 功能/科学闸门

- 单元测试验证9-bin窗口首尾、Gauge邻域全部复谱bin并集、相同参考/测量迹线的Gauge相位恒等于零。
- P1c真实数值运行须报告固定Core总数、所需NUDFT复谱点数、端点幅度门限变化、raw与9bin数值差、相位差、两类Oracle RMSE及反三角界。
- 若对应Gauge数值差已可解释相当比例的Oracle RMSE变化，就不能简单把Oracle残差主要归因到物理模型；优先检查NUFFT参数与局部弱幅度误差。
- 若数值差远小于Oracle残余，仅能排除**本配置/本散射种子上的NUFFT近似差异**为主要来源。还需P1b更密网格统计、PSF/应变边缘响应，以及真实物理模型适用性验证。

## 5. 安全与研究隔离

这是已查看开发seed的定点数值审核，不能当成新的独立样本或同一方法的冻结测试。无需运行原有8次P2或4次P1密度实验，不消耗任何预留冻结种子。P1c结果写独立输出 `P1C_GAUGE_NUDFT_DEVELOPMENT.mat/.csv`，不覆盖原P1/P2文件。任何基于数值结果调核参数的工作都应另建修复分支并重新固定验证方案。