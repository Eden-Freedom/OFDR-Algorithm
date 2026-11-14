function [T,d]=p2b_readonly_audit_dev12(source)
%P2B_READONLY_AUDIT_DEV12 仅读取P2b现有MAT；不再运行任何物理随机试次。
%
% 默认读取本目录output/P2B_DEVELOPMENT_results.mat，也可传入results
% 结构体或其results.development字段。不执行bootstrap或随机数操作。
% 主终点固定eps=5με/alpha=1；报告全部trial（包括失败）的配对误差。
%
% 探索性额外对照：
%   1. 仅用alpha^2<g^2>的quadratic-only预测（不使用Oracle交叉项r0*g，
%      但g方向本身仍依赖qtrue，不能部署）。
%   2. 基于其他成功trial的实际C均值的LOO常数预测（事后诊断，
%      使用其他trial的真值标签，不是事先注册的算法或正式基线）。
%
% 任何新增对照均标明POST-HOC；原本的主终点/CI不修改。

    if nargin<1 || isempty(source)
        path=fullfile(fileparts(mfilename('fullpath')), ...
            'output','P2B_DEVELOPMENT_results.mat');
        if ~isfile(path)
            error('P2B:AuditMissing','找不到已保存开发MAT：%s',path);
        end
        L=load(path,'results');
        if ~isfield(L,'results')
            error('P2B:AuditMissing','MAT缺少results。');
        end
        source=L.results;
    end
    if ~isstruct(source)
        error('P2B:AuditType','输入必须是已有开发results结构体。');
    end
    if isfield(source,'development')
        r=source.development;
    else
        r=source;
    end
    if ~isfield(r,'dataset') || ~strcmp(r.dataset,'development')
        error('P2B:AuditDevOnly','只允许读取已完成的开发数据，拒绝冻结。');
    end
    n=r.n_trials;ok=logical(r.success(:));
    if numel(ok)~=n || n<1 || ...
       size(r.C_actual,1)~=n || size(r.C_pred,1)~=n || ...
       size(r.pred_linear,1)~=n || size(r.pred_quadratic,1)~=n || ...
       size(r.prediction_residual,1)~=n
        error('P2B:AuditShape','trial数组形状非法。');
    end
    j=find(abs(r.strains_microeps-5)<1e-12);
    v=find(abs(r.test_alpha-1)<1e-12);
    if numel(j)~=1 || numel(v)~=1
        error('P2B:AuditPrimary','未找到预先固定5με/alpha=1主终点。');
    end
    ca=reshape(r.C_actual(:,j,v),n,1);
    cp=reshape(r.C_pred(:,j,v),n,1);
    linear=reshape(r.pred_linear(:,j,v),n,1);
    quadratic=reshape(r.pred_quadratic(:,j,v),n,1);
    residual=reshape(r.prediction_residual(:,j,v),n,1);
    if any(~isfinite([ca(ok);cp(ok);linear(ok);quadratic(ok);residual(ok)]))
        error('P2B:AuditFinite','成功trial包含非有限MSE数据。');
    end
    if any(abs(cp(ok)-linear(ok)-quadratic(ok))>1e-10)|| ...
       any(abs(ca(ok)-cp(ok)-residual(ok))>1e-10)
        error('P2B:AuditIdentity','共模预测或残差代数恒等式失败。');
    end
    nSuccess=nnz(ok);
    null_abs=nan(n,1);
    model_abs=nan(n,1);
    quadratic_abs=nan(n,1);
    relative_abs=nan(n,1);
    gain_vs_zero=nan(n,1);
    gain_vs_quadratic=nan(n,1);
    loo_constant=nan(n,1);
    loo_abs=nan(n,1);
    gain_vs_loo=nan(n,1);
    null_abs(ok)=abs(ca(ok));
    model_abs(ok)=abs(residual(ok));
    quadratic_abs(ok)=abs(ca(ok)-quadratic(ok));
    gain_vs_zero(ok)=null_abs(ok)-model_abs(ok);
    gain_vs_quadratic(ok)=quadratic_abs(ok)-model_abs(ok);
    nz=ok & abs(ca)>1e-12;
    relative_abs(nz)=model_abs(nz)./abs(ca(nz));
    if nSuccess>=2
        ids=find(ok);
        for k=1:numel(ids)
            t=ids(k);
            other=ids(ids~=t);
            loo_constant(t)=mean(ca(other));
            loo_abs(t)=abs(ca(t)-loo_constant(t));
        end
        gain_vs_loo(ok)=loo_abs(ok)-model_abs(ok);
    end
    gradRMS=r.gradient_rms(:,j);
    hgap=r.gradient_h_difference(:,j);
    hratio=nan(n,1);
    hasGrad=ok & isfinite(gradRMS) & gradRMS>1e-12;
    hratio(hasGrad)=hgap(hasGrad)./gradRMS(hasGrad);
    failure_id=r.failure_id(:);
    failure_reason=r.failure_reason(:);
    scatter_seed=r.scatter_seed(:);
    common_core=r.common_core_count(:);
    common_roi=r.common_valid_fraction(:);
    T=table((1:n).',ok,scatter_seed,common_core,common_roi,ca,cp, ...
        linear,quadratic,residual,model_abs,null_abs,relative_abs, ...
        gain_vs_zero,quadratic_abs,gain_vs_quadratic, ...
        loo_constant,loo_abs,gain_vs_loo,gradRMS,hgap,hratio, ...
        failure_id,failure_reason, ...
        'VariableNames',{'trial','success','scatter_seed', ...
        'common_core_gauges','common_roi_valid_fraction', ...
        'C_actual_ue2','C_pred_ue2','C_linear_ue2', ...
        'C_quadratic_ue2','signed_error_ue2','model_abs_error_ue2', ...
        'zero_abs_error_ue2','relative_abs_error', ...
        'gain_vs_zero_ue2','quadratic_only_abs_error_ue2', ...
        'gain_vs_quadratic_ue2','LOO_constant_C_ue2', ...
        'LOO_abs_error_ue2','gain_vs_LOO_ue2', ...
        'gradient_rms_ue_per_alpha','h_difference_rms_ue_per_alpha', ...
        'relative_h_difference','failure_id','failure_reason'});
    d=struct();
    d.n_total=n;
    d.n_success=nSuccess;
    d.n_failure=n-nSuccess;
    d.failure_rate=d.n_failure/n;
    d.primary_eps_ue=5;
    d.primary_alpha=1;
    d.primary_model_MAE=NaN;
    d.primary_zero_MAE=NaN;
    d.primary_quadratic_only_MAE=NaN;
    d.primary_LOO_constant_MAE=NaN;
    d.gain_vs_zero=NaN;
    d.gain_vs_quadratic=NaN;
    d.gain_vs_LOO=NaN;
    d.model_better_than_zero=0;
    d.model_worse_than_zero=0;
    d.model_better_than_quadratic=0;
    d.model_better_than_LOO=0;
    d.worst_model_abs_error=NaN;
    d.mean_relative_h_difference=NaN;
    d.main_gain_CI95=[NaN NaN];
    d.note='LOO constant and quadratic-only are post-hoc exploratory diagnostics; not preregistered deployable baselines.';
    if nSuccess>0
        d.primary_model_MAE=mean(model_abs(ok));
        d.primary_zero_MAE=mean(null_abs(ok));
        d.primary_quadratic_only_MAE=mean(quadratic_abs(ok));
        d.gain_vs_zero=mean(gain_vs_zero(ok));
        d.gain_vs_quadratic=mean(gain_vs_quadratic(ok));
        d.model_better_than_zero=nnz(gain_vs_zero(ok)>1e-12);
        d.model_worse_than_zero=nnz(gain_vs_zero(ok)<-1e-12);
        d.model_better_than_quadratic=nnz(gain_vs_quadratic(ok)>1e-12);
        d.worst_model_abs_error=max(model_abs(ok));
        d.mean_relative_h_difference=mean(hratio(hasGrad));
        if nSuccess>=2
            d.primary_LOO_constant_MAE=mean(loo_abs(ok));
            d.gain_vs_LOO=mean(gain_vs_loo(ok));
            d.model_better_than_LOO=nnz(gain_vs_loo(ok)>1e-12);
        end
    end
    if isfield(r,'summary') && isfield(r.summary,'gain_CI95')
        d.main_gain_CI95=reshape(r.summary.gain_CI95(j,v,:),1,2);
    end
    fprintf('\n==== P2b DEV12 | READ-ONLY PREDECLARED PRIMARY + EXPLORATORY AUDIT ====\n');
    fprintf('Success %d/%d | failures %d (%.2f%%)\n', ...
        d.n_success,d.n_total,d.n_failure,100*d.failure_rate);
    fprintf('5ue, alpha=1: full model MAE %.8g vs zero MAE %.8g (ue^2)\n', ...
        d.primary_model_MAE,d.primary_zero_MAE);
    fprintf('PREDECLARED paired gain vs zero %.8g CI95 [%.8g, %.8g] (ue^2)\n', ...
        d.gain_vs_zero,d.main_gain_CI95(1),d.main_gain_CI95(2));
    fprintf('POST-HOC: quadratic-only MAE %.8g, LOO constant MAE %.8g (ue^2)\n', ...
        d.primary_quadratic_only_MAE,d.primary_LOO_constant_MAE);
    fprintf('Worst full-model absolute prediction error %.8g (ue^2); this is NOT worst regression vs zero.\n', ...
        d.worst_model_abs_error);
    disp(T);
end