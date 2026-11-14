function d=p1p2_readonly_diagnose(source)
%P1P2_READONLY_DIAGNOSE 只读已运行P1/P2开发集的配对机制诊断。
% 使用已有存盘MAT中的独立trial结果和现成bootstrap CI；不运行任何新
% 光学模拟、随机数、重构、校正参数优化，也不修改原始MAT。
%
% 输入 source: 省略 => 读取本目录output/P1P2_DEVELOPMENT_results.mat；
%             也可传入main_p1p2返回的results结构体。
% 输出 d.p2_table: 每个应变水平的主效应、CI、trial正负次数、raw交互；
%      d.p1_table: 各散射密度的均值及原有配对CI；
%      d: 成功、失败、共同有效ROI及诊断一致性校验。
    if nargin<1||isempty(source)
        file=fullfile(fileparts(mfilename('fullpath')), ...
                     'output','P1P2_DEVELOPMENT_results.mat');
        if ~isfile(file)
            error('P1P2:MissingResults','没有开发结果MAT：%s',file);
        end
        S=load(file,'results');
        if ~isfield(S,'results')
            error('P1P2:MissingResults','MAT没有results。');
        end
        x=S.results;
    elseif isstruct(source)
        x=source;
    else
        error('P1P2:Input','只接受已有results结构体或省略输入。');
    end
    if ~isfield(x,'p2') || ~strcmp(x.p2.dataset,'development')
        error('P1P2:DevOnly','只允许P2已保存开发集。');
    end
    r=x.p2;s=r.summary;
    valid=logical(r.success(:));
    K=numel(r.strain_microeps);
    if numel(valid)~=r.n_trials || size(r.M_core,1)~=r.n_trials || ...
            size(r.M_core,2)~=K || size(r.M_core,3)~=4
        error('P1P2:Shape','P2的trial、strain或四组维度有误。');
    end
    d=struct;
    d.n_total=r.n_trials;
    d.n_success=nnz(valid);
    d.n_failure=d.n_total-d.n_success;
    d.failure_rate=d.n_failure/max(1,d.n_total);
    d.mean_common_roi_fraction=NaN;
    d.mean_common_core_count=NaN;
    if d.n_success>0
        d.mean_common_roi_fraction=mean(r.common_roi_fraction(valid));
        d.mean_common_core_count=mean(r.common_core_count(valid));
        % 每个trial检验2x2平方误差分解恒等式，而非把交互视作残差功率。
        predicted=r.M_core(valid,:,1)+r.C_core(valid,:)+ ...
                  r.D_core(valid,:)+r.I_core(valid,:);
        observed=r.M_core(valid,:,4);
        d.identity_max_error_ue2=max(abs(predicted-observed),[],'all');
        if d.identity_max_error_ue2>1e-9
            error('P1P2:InteractionMismatch','2x2 MSE分解代数不一致。');
        end
    else
        d.identity_max_error_ue2=NaN;
    end
    cmean=nan(K,1);dmean=cmean;imean=cmean;iraw=cmean;
    cpos=zeros(K,1);cneg=cpos;ipos=cpos;ineg=cpos;
    for j=1:K
        if ~any(valid),continue;end
        C=r.C_core(valid,j);D=r.D_core(valid,j);I=r.I_core(valid,j);
        cmean(j)=mean(C);dmean(j)=mean(D);imean(j)=mean(I);
        iraw(j)=mean(r.I_raw_core(valid,j));
        cpos(j)=nnz(C>1e-12);cneg(j)=nnz(C< -1e-12);
        ipos(j)=nnz(I>1e-12);ineg(j)=nnz(I< -1e-12);
    end
    ciC=nan(K,2);ciD=nan(K,2);ciI=nan(K,2);
    if isfield(s,'C_CI95'),ciC=s.C_CI95;end
    if isfield(s,'D_CI95'),ciD=s.D_CI95;end
    if isfield(s,'I_CI95'),ciI=s.I_CI95;end
    d.p2_table=table(r.strain_microeps(:),cmean,ciC(:,1),ciC(:,2), ...
        dmean,ciD(:,1),ciD(:,2),imean,ciI(:,1),ciI(:,2),iraw, ...
        cpos,cneg,ipos,ineg, ...
        'VariableNames',{'strain_ue','C_mean_ue2','C_CI_lo','C_CI_hi', ...
        'D_mean_ue2','D_CI_lo','D_CI_hi','I_mean_ue2','I_CI_lo', ...
        'I_CI_hi','I_raw_mean_ue2','C_positive','C_negative', ...
        'I_positive','I_negative'});
    d.p1_table=table();
    if isfield(x,'p1_density')
        a=x.p1_density;
        g=logical(a.success(:));
        step=a.step_mm(:);
        meanCore=nan(numel(step),1);
        meanRaw=nan(numel(step),1);
        ci=nan(numel(step),2);
        if any(g)
            meanCore=mean(a.core_rmse(g,:),1).';
            meanRaw=mean(a.raw_core_rmse(g,:),1).';
        end
        if isfield(a,'paired_vs_finest_CI95')
            ci=a.paired_vs_finest_CI95;
        end
        d.p1_table=table(step,meanCore,meanRaw,ci(:,1),ci(:,2), ...
            'VariableNames',{'scatter_step_mm','mean_oracle_core_ue', ...
            'mean_oracle_raw_core_ue','paired_minus_finest_CI_lo', ...
            'paired_minus_finest_CI_hi'});
        d.p1_n_success=nnz(g);
        d.p1_n_total=a.n_trials;
    end
    fprintf('\n=== P1/P2 READ-ONLY DEVELOPMENT DIAGNOSIS ===\n');
    fprintf('P2 successful %d/%d, failures %d (%.2f%%), common ROI %.2f%%\n', ...
        d.n_success,d.n_total,d.n_failure,100*d.failure_rate, ...
        100*d.mean_common_roi_fraction);
    if ~isempty(d.p1_table)
        fprintf('P1 scatter %d/%d successful; all contrasts are coupled-trial and DEV-only.\n', ...
                d.p1_n_success,d.p1_n_total);
        disp(d.p1_table);
    end
    disp(d.p2_table);
    fprintf('2x2 MSE identity residual=%.3g (ue^2). No new simulations executed.\n', ...
            d.identity_max_error_ue2);
end