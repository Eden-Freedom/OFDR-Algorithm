function [T,d]=v7c_diagnose_development(results)
%V7C_DIAGNOSE_DEVELOPMENT 已运行开发集的事后诊断，不重新拟合、不执行随机仿真。
% 输入：main_v7c 已产生的 results（仅使用 results.development）。
% 无输入时读取本目录 output/V7c_development_results.mat。
% 输出：
%   T：逐 trial 配对误差、门控选择、CV 分数及失败记录的 MATLAB table。
%   d：最大退化试次与留一均值等描述性统计。
% 【科研边界】本脚本只用于分析已经查看的开发集，不能根据其结果
% 选择 V7c 现有冻结测试的算法超参数；不调用 Oracle 真值进行拟合。
    if nargin<1 || isempty(results)
        here=fileparts(mfilename('fullpath'));
        f=fullfile(here,'output','V7c_development_results.mat');
        if ~exist(f,'file')
            error('V7c:DevFileMissing','未找到开发集文件：%s',f);
        end
        loaded=load(f,'results');
        results=loaded.results;
    end
    if ~isstruct(results) || ~isfield(results,'development')
        error('V7c:DevOnly','必须提供包含 development 的结果，禁止把冻结测试作为开发诊断输入。');
    end
    r=results.development;
    n=r.n_trials;
    if numel(r.success)~=n || size(r.core_rmse,1)~=n || ...
            size(r.core_rmse,2)~=6
        error('V7c:DevShape','开发试次数量与误差数组不一致。');
    end
    good=logical(r.success(:));
    trial=(1:n).';
    alpha=r.chosen_alpha(:);

    % 正值表示 CV-SAPC 优于对照；每一行来自同一随机 trial。
    ga=r.core_rmse(:,4)-r.core_rmse(:,6);
    gf=r.core_rmse(:,5)-r.core_rmse(:,6);
    ha=r.holdout_rmse(:,4)-r.holdout_rmse(:,6);
    hf=r.holdout_rmse(:,5)-r.holdout_rmse(:,6);
    % 对失败试次保留 NaN，不能将其改成0或剔除分母。
    ga(~good)=NaN;gf(~good)=NaN;
    ha(~good)=NaN;hf(~good)=NaN;

    T=table(trial,good,r.seed_scatter(:),alpha, ...
        r.core_rmse(:,4),r.core_rmse(:,5),r.core_rmse(:,6),ga,gf, ...
        r.holdout_rmse(:,4),r.holdout_rmse(:,5),r.holdout_rmse(:,6),ha,hf, ...
        r.cv_gain_fraction(:),r.data_hessian_rcond(:), ...
        r.valid_fraction(:,4),r.valid_fraction(:,6), ...
        r.fallback_reason(:),r.failure_id(:),r.failure_reason(:), ...
        'VariableNames',{'trial','success','scatter_seed','alpha', ...
        'core_affine','core_sapc','core_cv','core_gain_vs_affine', ...
        'core_gain_vs_sapc','holdout_affine','holdout_sapc', ...
        'holdout_cv','holdout_gain_vs_affine','holdout_gain_vs_sapc', ...
        'cv_gain_fraction','hessian_data_rcond', ...
        'valid_affine','valid_cv','gate_reason','failure_id','failure_reason'});

    d=struct();
    d.n_total=n;
    d.n_success=nnz(good);
    d.n_failure=n-d.n_success;
    d.n_affine_fallback=nnz(good & alpha==0);
    d.n_full_sapc=nnz(good & alpha==1);
    d.n_partial=nnz(good & alpha>0 & alpha<1);
    % 仅做事后 Oracle 评分诊断，绝不能反过来用于 alpha 的选择。
    % 接受失误：alpha>0 但 Core 比 affine 更差。
    d.n_accept_regression=nnz(good & alpha>0 & ga<0);
    d.n_accept_improvement=nnz(good & alpha>0 & ga>0);
    % 拒绝代价：alpha=0，但 Full SAPC 本可获得更低的 Core RMSE。
    % 这只是对 full 的反事实比较，不保证 full 在 Holdout 也更好。
    d.n_reject_full_better=nnz(good & alpha==0 & ...
        r.core_rmse(:,5)<r.core_rmse(:,4));
    d.loo_mean_core_gain_vs_sapc=nan(n,1);
    d.loo_mean_core_gain_vs_affine=nan(n,1);
    d.worst_vs_sapc_trial=NaN;
    d.worst_vs_sapc_gain=NaN;
    d.worst_vs_affine_trial=NaN;
    d.worst_vs_affine_gain=NaN;

    fprintf('\n========== V7c 24次开发集事后诊断（非冻结测试） ==========\n');
    fprintf('成功 %d/%d，失败 %d；回退 affine=%d，完全 SAPC=%d，部分混合=%d\n', ...
        d.n_success,n,d.n_failure,d.n_affine_fallback,d.n_full_sapc,d.n_partial);
    if ~any(good)
        fprintf('所有 trial 均失败，跳过收益统计。\n');
        return;
    end
    fprintf('被接受的非仿射试次：Core 改善=%d，反而退化=%d；拒绝 full 但 full Core 较优=%d\n', ...
        d.n_accept_improvement,d.n_accept_regression,d.n_reject_full_better);
    fprintf('平均 Core gain：vs affine = %+.6f με，vs full SAPC = %+.6f με\n', ...
        mean(ga(good)),mean(gf(good)));
    fprintf('平均 Holdout gain：vs affine = %+.6f με，vs full SAPC = %+.6f με\n', ...
        mean(ha(good)),mean(hf(good)));

    % 每一类 alpha 的均值只作事后描述，不能作为新算法阈值的选择依据。
    groups={'alpha=0','0<alpha<1','alpha=1'};
    masks={good & alpha==0,good & alpha>0 & alpha<1,good & alpha==1};
    for k=1:numel(groups)
        mask=masks{k};
        if ~any(mask)
            fprintf('%s：0个试次。\n',groups{k});
        else
            fprintf('%s：%d个；Core gain vs affine=%+.6f，vs SAPC=%+.6f με\n', ...
                groups{k},nnz(mask),mean(ga(mask)),mean(gf(mask)));
        end
    end

    positions=find(good);
    [d.worst_vs_sapc_gain,j]=min(gf(good));
    d.worst_vs_sapc_trial=positions(j);
    [d.worst_vs_affine_gain,j]=min(ga(good));
    d.worst_vs_affine_trial=positions(j);
    fprintf('\n相对 Full SAPC 最严重的 Core 退化：trial %d，gain=%+.6f με\n', ...
        d.worst_vs_sapc_trial,d.worst_vs_sapc_gain);
    fprintf('相对 Affine 最严重的 Core 退化：trial %d，gain=%+.6f με\n', ...
        d.worst_vs_affine_trial,d.worst_vs_affine_gain);
    disp(T(T.trial==d.worst_vs_sapc_trial, ...
        {'trial','alpha','core_gain_vs_sapc','holdout_gain_vs_sapc', ...
         'cv_gain_fraction','hessian_data_rcond','gate_reason'}));

    % Leave-one-out 是均值对单一样本的敏感性分析，不是删除异常值。
    if numel(positions)>1
        for j=1:numel(positions)
            keep=good & trial~=positions(j);
            d.loo_mean_core_gain_vs_sapc(positions(j))=mean(gf(keep));
            d.loo_mean_core_gain_vs_affine(positions(j))=mean(ga(keep));
        end
        fprintf('删除最差 SAPC 对照 trial 的敏感性均值（仅诊断）：%+.6f με\n', ...
            d.loo_mean_core_gain_vs_sapc(d.worst_vs_sapc_trial));
    end
    fprintf('注意：正式推断依然使用全部成功 trial，失败 trial 保留在失败率分母。\n');
end
