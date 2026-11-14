function [T,a]=v7c_audit_size_gate_dev(results,cfg)
%V7C_AUDIT_SIZE_GATE_DEV 只读开发集：审计非仿射幅度门控的提前拒绝。
%
% 输入：
%  results：main_v7c 的输出，必须含 results.development。
%           留空时仅加载本地 V7c_development_results.mat。
%  cfg：保存的开发配置；省略时读取 MAT 中 cfg，或使用 config_v7c。
%
% 输出：
%  T：24个开发 trial 的既有 E、alpha、CV运行情况、配对 Core/Holdout 收益。
%  a：当前固定的额外校正幅度阈值、被提前拒绝的试次及只按
%     |alpha*(qSAPC-qAffine)| 幅度条件筛选的候选 alpha。
%
% 重要限制：
%  1. 本函数不运行激光正演、不重构NUFFT、不重拟合，也不访问冻结测试；
%  2. 不改变门控阈值或 alpha 网格，所有“候选可行”只涉及新增修正幅度，
%     不表示通过单调性、总修正幅度、fold 验证或实验性能检验；
%  3. Core/Holdout 的事后误差只用于分析，并不输入实际门控算法。
    if nargin<1 || isempty(results)
        here=fileparts(mfilename('fullpath'));
        f=fullfile(here,'output','V7c_development_results.mat');
        if ~exist(f,'file')
            error('V7c:AuditMissing','找不到开发集结果：%s',f);
        end
        S=load(f,'results','cfg');
        if ~isfield(S,'results')
            error('V7c:AuditMissing','MAT 文件没有 results。');
        end
        results=S.results;
        if nargin<2 || isempty(cfg)
            if isfield(S,'cfg')
                cfg=S.cfg;
            else
                cfg=config_v7c();
            end
        end
    elseif nargin<2 || isempty(cfg)
        cfg=config_v7c();  % 读取固定协议配置，不触发任何 trial
    end
    if ~isstruct(results)||~isfield(results,'development')
        error('V7c:AuditDevOnly','仅接受含 development 的结果结构体。');
    end
    r=results.development;
    fields={'success','chosen_alpha','extra_peak_MHz','cv_folds_ok', ...
        'fallback_reason','core_rmse','holdout_rmse'};
    for k=1:numel(fields)
        if ~isfield(r,fields{k})
            error('V7c:AuditField','开发集缺少字段 %s',fields{k});
        end
    end
    n=r.n_trials;
    good=logical(r.success(:));
    E=r.extra_peak_MHz(:);
    alpha=r.chosen_alpha(:);
    if numel(good)~=n || numel(E)~=n || numel(alpha)~=n || ...
            size(r.core_rmse,1)~=n || size(r.core_rmse,2)<6 || ...
            size(r.holdout_rmse,1)~=n || size(r.holdout_rmse,2)<6
        error('V7c:AuditShape','统计数组形状与开发试次数量不一致。');
    end
    limit=cfg.v7c.max_extra_correction_MHz;
    grid=cfg.v7c.alpha_grid(:).';
    if ~isscalar(limit)||~isfinite(limit)||limit<=0|| ...
            isempty(grid)||any(grid<0)||any(grid>1)
        error('V7c:AuditConfig','非法的冻结额外修正幅度上限/alpha 网格。');
    end
    reason=string(r.fallback_reason(:));
    size_reason=(reason=="non-affine correction size gate");
    exceeded=good & isfinite(E) & E>limit;
    refused=good & size_reason & alpha==0;
    % 全段拟合的 alpha*E <= limit：只是幅度条件，不代表总体可行。
    nominal_pass=(E.*grid <= limit);
    nominal_pass(~good,:)=false;
    if any(refused & ~exceeded)
        error('V7c:AuditInconsistent','幅度门控记录与 E/阈值不一致，请检查源代码版本。');
    end

    core_aff=r.core_rmse(:,4);core_full=r.core_rmse(:,5);core_cv=r.core_rmse(:,6);
    hold_aff=r.holdout_rmse(:,4);hold_full=r.holdout_rmse(:,5);hold_cv=r.holdout_rmse(:,6);
    core_full_adv=core_aff-core_full;
    hold_full_adv=hold_aff-hold_full;
    core_full_adv(~good)=NaN;hold_full_adv(~good)=NaN;
    T=table((1:n).',good,alpha,E,r.cv_folds_ok(:), ...
        size_reason,exceeded,refused,core_full_adv,hold_full_adv, ...
        core_aff,core_full,core_cv,hold_aff,hold_full,hold_cv, ...
        cellstr(reason), ...
        'VariableNames',{'trial','success','chosen_alpha','extra_peak_MHz', ...
        'cv_folds_ok','size_gate_reason','E_exceeds_limit','early_refused', ...
        'full_core_adv_vs_affine','full_holdout_adv_vs_affine', ...
        'core_affine','core_full','core_cv', ...
        'holdout_affine','holdout_full','holdout_cv','gate_reason'});
    a=struct();
    a.limit_MHz=limit;
    a.alpha_grid=grid;
    a.n_success=nnz(good);
    a.n_exceeded=nnz(exceeded);
    a.n_early_refused=nnz(refused);
    a.n_refused_but_full_core_better=nnz(refused & core_full_adv>0);
    a.n_refused_but_full_holdout_better=nnz(refused & hold_full_adv>0);
    a.refused_trial_ids=find(refused);
    a.nominal_extra_size_pass_matrix=nominal_pass;
    a.refused_candidates_cell=cell(n,1);
    for k=find(refused).'
        a.refused_candidates_cell{k}=grid(nominal_pass(k,:));
    end

    fprintf('\n========== V7c | DEV-only extra-size precheck audit ==========\n');
    fprintf('已执行成功 %d/%d；固定额外修正峰值门限 %.6f MHz\n',a.n_success,n,limit);
    fprintf('E超限 %d；因幅度提前拒绝 %d；其中 Full SAPC Core 较优 %d，Holdout 较优 %d\n', ...
        a.n_exceeded,a.n_early_refused, ...
        a.n_refused_but_full_core_better,a.n_refused_but_full_holdout_better);
    for k=a.refused_trial_ids(:).'
        fprintf('trial %d: E=%.6f MHz; chosen alpha=%.2f; CV folds executed=%d\n', ...
            k,E(k),alpha(k),logical(r.cv_folds_ok(k)));
        fprintf('  full vs affine Core gain=%+.6f με; Holdout gain=%+.6f με\n', ...
            core_full_adv(k),hold_full_adv(k));
        fprintf('  candidate alpha passing ONLY the final-fit extra-size cap: ');
        fprintf('%.2f ',a.refused_candidates_cell{k});
        fprintf('\n');
    end
    fprintf('警告：以上候选尚未接受 CV 评分/单调性/总修正约束审计，不是算法修改或推荐 alpha。\n');
end
