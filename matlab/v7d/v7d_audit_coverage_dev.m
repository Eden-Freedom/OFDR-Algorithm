function [T,d]=v7d_audit_coverage_dev(results,cfg)
%V7D_AUDIT_COVERAGE_DEV V7d已运行开发集的只读门控覆盖诊断。
% 用途：查阅 E 幅度分布、候选资格、CV是否运行、共同有效Gauge、
%       与原V7c的逐试次alpha和RMSE差，不生成任何新随机试次。
%
% 输入：
%   results - main_v7d 的输出；省略时只读取V7d_DEVELOPMENT_results.mat
%   cfg     - 可选配置；省略时读取MAT内cfg，或config_v7d()默认值
% 输出：
%   T - 含失败trial的逐试次诊断表（不删除失效样本）
%   d - 分母、覆盖、E范围、共同掩码、候选资格等描述性统计
%
% 保密：冻结测试锁不变。truth/Core评估仅供事后核查，绝不能倒灌到门控参数。
    if nargin<1 || isempty(results)
        here=fileparts(mfilename('fullpath'));
        filename=fullfile(here,'output','V7d_DEVELOPMENT_results.mat');
        if ~exist(filename,'file')
            error('V7d:AuditMissing','未找到开发集结果：%s',filename);
        end
        S=load(filename,'results','cfg');
        if ~isfield(S,'results')
            error('V7d:AuditMissing','文件没有 results 字段。');
        end
        results=S.results;
        if nargin<2 || isempty(cfg)
            if isfield(S,'cfg'),cfg=S.cfg;else,cfg=config_v7d();end
        end
    elseif nargin<2 || isempty(cfg)
        cfg=config_v7d();
    end
    if ~isstruct(results)||~isfield(results,'development')
        error('V7d:AuditDevOnly','只允许分析 results.development。');
    end
    r=results.development;
    if ~isfield(r,'dataset') || ~strcmp(r.dataset,'development')
        error('V7d:AuditDevOnly','输入的数据集必须标记为development。');
    end
    n=r.n_trials;good=logical(r.success(:));
    if numel(good)~=n || size(r.core_rmse,1)~=n || ...
       size(r.core_rmse,2)~=7 || size(r.holdout_rmse,2)~=7 || ...
       size(r.valid_fraction,2)~=7 || size(r.full_candidate_ok,2)~=5 || ...
       size(r.fold_candidate_ok,2)~=5
        error('V7d:AuditDimensions','七方法、五候选或试次数组形状不匹配。');
    end
    E=r.full_extra_peak_MHz(:);
    alphaC=r.alpha_v7c(:);alphaD=r.alpha_v7d(:);
    if numel(E)~=n || numel(alphaC)~=n || numel(alphaD)~=n
        error('V7d:AuditDimensions','门控向量长度不匹配。');
    end
    threshold=cfg.v7d.max_extra_correction_MHz;
    above=good & isfinite(E) & E>threshold;
    changed=good & abs(alphaC-alphaD)>1e-12;
    coreGain=r.core_rmse(:,6)-r.core_rmse(:,7);
    holdGain=r.holdout_rmse(:,6)-r.holdout_rmse(:,7);
    coreGain(~good)=NaN;holdGain(~good)=NaN;
    foldOKC=logical(r.cv_folds_v7c(:));
    foldOKD=logical(r.cv_folds_v7d(:));
    fullN=sum(r.full_candidate_ok(:,2:end),2);
    % fold_candidate_ok=false 既可能代表候选不合格，也可能表示该trial
    % 在Hessian/候选过滤等步骤提前返回、根本没有运行完整CV。
    % 故这里只在foldOKD=true时解释“全部折评分通过候选”的数量。
    foldN=sum(r.fold_candidate_ok(:,2:end),2);
    foldN(~foldOKD)=NaN;
    deltaValid=r.valid_fraction(:,7)-r.valid_fraction(:,6);
    deltaValid(~good)=NaN;
    reasonC=r.reason_v7c(:);reasonD=r.reason_v7d(:);
    for i=1:n
        if isempty(reasonC{i}),reasonC{i}='';end
        if isempty(reasonD{i}),reasonD{i}='';end
    end
    T=table((1:n).',good,E,threshold-E,above,alphaC,alphaD,changed, ...
        foldOKC,foldOKD,fullN,foldN,coreGain,holdGain,deltaValid, ...
        r.common_valid_fraction(:),r.common_core_count(:), ...
        r.common_holdout_count(:),reasonC,reasonD, ...
        'VariableNames',{'trial','success','E_MHz','E_margin_MHz', ...
        'full_E_exceeds_limit','alpha_v7c','alpha_v7d','changed', ...
        'cv_folds_v7c','cv_folds_v7d','full_nonaffine_count', ...
        'fold_nonaffine_count_if_CV_executed','core_gain_vs_v7c', ...
        'holdout_gain_vs_v7c','valid_gain_vs_v7c', ...
        'common_valid_fraction','common_core_count', ...
        'common_holdout_count','reason_v7c','reason_v7d'});

    d=struct();
    d.total=n;
    d.n_success=nnz(good);d.n_failure=n-d.n_success;
    d.n_over_extra_limit=nnz(above);
    d.n_changed=nnz(changed);
    d.n_candidate_full_all_nonaffine_blocked=nnz(good & fullN==0);
    d.n_cv_completed_v7c=nnz(good & foldOKC);
    d.n_cv_completed_v7d=nnz(good & foldOKD);
    d.E_min_MHz=NaN;d.E_max_MHz=NaN;d.E_p95_MHz=NaN;
    d.mean_common_valid=NaN;
    d.mean_valid_by_method=nan(1,7);
    d.mean_core_common_count=NaN;
    d.mean_holdout_common_count=NaN;
    d.n_Core_nonzero_gain=0;d.n_Core_negative_gain=0;
    d.n_Core_ties=0;
    d.n_Holdout_nonzero_gain=0;
    fprintf('\n========== V7d | READ-ONLY development exposure audit ==========\n');
    fprintf('成功 %d/%d；失败 %d（分母保留）\n',d.n_success,n,d.n_failure);
    if any(good)
        ev=sort(E(good & isfinite(E)));
        if ~isempty(ev)
            d.E_min_MHz=ev(1);
            d.E_max_MHz=ev(end);
            d.E_p95_MHz=ev(max(1,ceil(.95*numel(ev))));
        end
        d.mean_common_valid=mean(r.common_valid_fraction(good));
        d.mean_valid_by_method=mean(r.valid_fraction(good,:),1);
        d.mean_core_common_count=mean(r.common_core_count(good));
        d.mean_holdout_common_count=mean(r.common_holdout_count(good));
        d.n_Core_nonzero_gain=nnz(abs(coreGain(good))>1e-12);
        d.n_Core_negative_gain=nnz(coreGain(good)<-1e-12);
        d.n_Core_ties=nnz(abs(coreGain(good))<=1e-12);
        d.n_Holdout_nonzero_gain=nnz(abs(holdGain(good))>1e-12);
        fprintf('Full E: min=%.6f, max=%.6f, p95(近邻秩)=%.6f MHz; 门限 %.6f MHz\n', ...
            d.E_min_MHz,d.E_max_MHz,d.E_p95_MHz,threshold);
        fprintf('E超限 %d/%d；alpha决策改变 %d/%d；无合法full非仿射候选 %d\n', ...
            d.n_over_extra_limit,d.n_success,d.n_changed,d.n_success, ...
            d.n_candidate_full_all_nonaffine_blocked);
        fprintf('完整CV折执行 V7c=%d，V7d=%d；相对V7c Core非零差异 %d, Holdout非零差异 %d\n', ...
            d.n_cv_completed_v7c,d.n_cv_completed_v7d, ...
            d.n_Core_nonzero_gain,d.n_Holdout_nonzero_gain);
        fprintf('七方法共同Gauge比例 %.4f；单一方法Gauge比例：',d.mean_common_valid);
        fprintf(' %.4f',d.mean_valid_by_method);fprintf('\n');
        fprintf('平均共同Core Gauge %.1f，Holdout Gauge %.1f\n', ...
            d.mean_core_common_count,d.mean_holdout_common_count);
    end
    fprintf('警告：此审计只读已查看开发集；不要按E/真值结果挑seed或调冻结阈值。\n');
end
