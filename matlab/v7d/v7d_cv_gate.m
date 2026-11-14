function out=v7d_cv_gate(cfg,truth,reftrace,signal,q0,affine,sapc)
%V7D_CV_GATE 逐候选可行性门控：保留V7c的阻塞CV与评分公式。
% 与V7c唯一目标性差别：不因为完整SAPC新增峰值超限就直接return；
% 逐个alpha检验全段坐标、折内坐标的额外/总幅度与严格单调性。
% 数据源：仅已知上游静态段、参考/测量复迹线和辅助估计；
% 不能使用应变Core/Holdout、光频真值或Oracle误差选择alpha。
    z=reftrace.z_m(:);
    lag=round(cfg.v6.gauge_length_m/(z(2)-z(1)));
    I=(1:numel(z)-lag).';J=I+lag;
    mid=0.5*(z(I)+z(J));
    train_lo=cfg.v7.train_static_m(1);
    train_hi=cfg.v7.train_static_m(2);
    in_train=z(I)>=train_lo & z(J)<=train_hi;
    base=v6_reconstruct_trace(cfg,truth,signal,q0(:));
    R=reftrace.spectrum(:);M=base.spectrum(:);
    refsite=z>=train_lo & z<=train_hi;
    level=cfg.v6.amplitude_gate_fraction*median(abs(R(refsite)));
    good=(abs(R)>level)&(abs(M)>level);
    eligible=in_train&good(I)&good(J);

    alphas=cfg.v7d.alpha_grid(:).';
    K=numel(alphas);
    nf=size(cfg.v7c.cv_frac,1);
    errSums=inf(nf,K);
    weights=zeros(nf,1);
    counts=zeros(nf,2);vals=zeros(nf,1);
    foldOK=false(nf,K);
    fullOK=false(1,K);
    fullPeak=nan(1,K);
    for k=1:K
        [fullOK(k),details]=v7d_candidate_feasible(q0, ...
            affine.q_corrected_Hz,sapc.q_corrected_Hz,alphas(k), ...
            cfg.v7d.max_extra_correction_MHz,cfg.v7d.max_total_correction_MHz);
        fullPeak(k)=details.extra_peak_MHz;
    end
    out=struct('alpha',0,'fallback',true,'reason','', ...
        'cv_scores_rad',inf(1,K),'cv_affine_rad',NaN, ...
        'cv_best_rad',NaN,'candidate_alpha',NaN, ...
        'cv_improvement_rad',NaN,'cv_improvement_fraction',NaN, ...
        'cv_folds_ok',false,'candidate_full_ok',fullOK, ...
        'candidate_fold_ok',foldOK,'candidate_extra_peak_MHz',fullPeak, ...
        'extra_peak_full_MHz',max(abs(sapc.q_corrected_Hz(:)- ...
                        affine.q_corrected_Hz(:)))/1e6, ...
        'data_hessian_rcond',sapc.rcond_data_hessian, ...
        'jacobian_rank',sapc.jacobian_rank, ...
        'fit_counts',counts,'validation_counts',vals);
    k0=find(abs(alphas)<1e-12,1);
    if isempty(k0)||k0~=1
        error('V7d:AlphaBaseline','alpha网格必须以0开始，CV基线才是Affine。');
    end
    if ~fullOK(k0)
        error('V7d:AffineInvalid','原始Affine校正坐标未通过基本可行性检查。');
    end
    if sapc.jacobian_rank<4 || ...
         ~isfinite(sapc.rcond_data_hessian) || ...
         sapc.rcond_data_hessian<cfg.v7d.min_data_rcond
        out.reason='full SAPC data Hessian rank/condition gate';return;
    end
    if ~any(fullOK(2:end))
        out.reason='no non-affine candidate passes full-fit constraints';return;
    end

    % 保留原两折的空间位置、保护带、样本筛选及相位评分（不得调参）。
    for fold=1:nf
        frac=cfg.v7c.cv_frac(fold,:);
        lo=train_lo+(train_hi-train_lo)*frac(1);
        hi=train_lo+(train_hi-train_lo)*frac(2);
        validation=eligible & mid>=lo & mid<=hi;
        validx=find(validation);
        validx=validx(1:cfg.v7.training_stride:end);
        fit_allowed=in_train & (mid<lo-cfg.v7c.cv_guard_m | ...
                                mid>hi+cfg.v7c.cv_guard_m);
        counts(fold,1)=nnz(fit_allowed);
        vals(fold)=numel(validx);
        if numel(validx)<cfg.v7c.min_validation_gauges || ...
          nnz(fit_allowed)<cfg.v7c.min_training_gauges*cfg.v7.training_stride
            out.reason='insufficient spatially separated training/validation gauges';return;
        end
        if any(fit_allowed(validx)) || ...
           any(mid(fit_allowed)>=lo-cfg.v7c.cv_guard_m & ...
               mid(fit_allowed)<=hi+cfg.v7c.cv_guard_m)
            error('V7d:Leakage','折内训练与验证Gauge重叠或保护带失效。');
        end
        try
            aa=v7c_fit_subset(cfg,truth,reftrace,signal,q0,'affine',fit_allowed);
            ff=v7c_fit_subset(cfg,truth,reftrace,signal,q0,'full',fit_allowed);
        catch ME
            out.reason=['fold-fit failed: ' ME.identifier];return;
        end
        counts(fold,2)=ff.train_count;
        if ff.jacobian_rank<4 || ~isfinite(ff.rcond_data_hessian) || ...
           ff.rcond_data_hessian<cfg.v7d.min_data_rcond
            out.reason='fold data Jacobian rank/condition gate';return;
        end
        weights(fold)=numel(validx);
        for k=1:K
            if ~fullOK(k)
                continue; % 全段候选不合法，则折内无需评分
            end
            [ok,~,qa]=v7d_candidate_feasible(q0, ...
                 aa.q_corrected_Hz,ff.q_corrected_Hz,alphas(k), ...
                 cfg.v7d.max_extra_correction_MHz,cfg.v7d.max_total_correction_MHz);
            if ~ok
                continue; % 单个候选无效不否决整个试次
            end
            foldOK(fold,k)=true;
            try
                trace=v6_reconstruct_trace(cfg,truth,signal,qa);
                C=trace.spectrum(:).*conj(R);
                phasor=C(J).*conj(C(I));
                w=cfg.v6c.phase_avg_bins;
                if w>1
                    phasor=conv(phasor,ones(w,1)/w,'same');
                end
                p=angle(phasor(validx));
                if ~all(isfinite(p))
                    foldOK(fold,k)=false;continue;
                end
                errSums(fold,k)=sum(p.^2);
            catch
                foldOK(fold,k)=false; % 非法候选失分，不能假装误差=0
            end
        end
    end

    out.fit_counts=counts;
    out.validation_counts=vals;
    out.candidate_fold_ok=foldOK;
    % 只有所有fold都通过可行性、相位有限的候选有有效评分。
    eligibleAlpha=fullOK & all(foldOK,1);
    out.cv_folds_ok=true;
    if ~eligibleAlpha(k0)
        out.reason='affine CV baseline invalid';return;
    end
    scores=inf(1,K);
    scores(eligibleAlpha)=sqrt(sum(errSums(:,eligibleAlpha),1)/sum(weights));
    out.cv_scores_rad=scores;
    out.cv_affine_rad=scores(k0);
    [best,ind]=min(scores);
    out.cv_best_rad=best;
    out.candidate_alpha=alphas(ind);
    out.cv_improvement_rad=out.cv_affine_rad-best;
    out.cv_improvement_fraction=out.cv_improvement_rad/max(out.cv_affine_rad,eps);
    if ind==k0
        out.reason='CV selected affine';return;
    end
    if out.cv_improvement_fraction<cfg.v7d.cv_required_relative_gain || ...
       out.cv_improvement_rad<cfg.v7d.cv_required_absolute_rad
        out.reason='CV gain below predeclared trust threshold';return;
    end
    out.alpha=alphas(ind);
    out.fallback=false;
    out.reason='CV accepted feasible non-affine candidate';
end
