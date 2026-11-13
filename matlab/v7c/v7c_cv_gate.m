function out=v7c_cv_gate(cfg,truth,reftrace,signal,q0,affine,sapc)
%V7C_CV_GATE 仅已知上游静态段，阻塞交叉验证选择 SAPC 混合强度。
% 改进需在训练子段中未参与拟合的 gauge 上成立；真实光频/应变区/持出下游不参与。
% 注：空间 gauge 像素相关；这里的 CV 是保护带隔离的模型选择，不是独立盲测。
    z=reftrace.z_m(:);lag=round(cfg.v6.gauge_length_m/(z(2)-z(1)));
    I=(1:numel(z)-lag).';J=I+lag;mid=0.5*(z(I)+z(J));
    train_lo=cfg.v7.train_static_m(1);train_hi=cfg.v7.train_static_m(2);
    in_train=z(I)>=train_lo & z(J)<=train_hi;
    base=v6_reconstruct_trace(cfg,truth,signal,q0(:));
    R=reftrace.spectrum(:);M=base.spectrum(:);
    refsite=z>=train_lo & z<=train_hi;
    level=cfg.v6.amplitude_gate_fraction*median(abs(R(refsite)));
    good=(abs(R)>level)&(abs(M)>level);
    eligible=in_train&good(I)&good(J);
    a=cfg.v7c.alpha_grid(:).';
    nfold=size(cfg.v7c.cv_frac,1);
    errs=nan(nfold,numel(a));weights=zeros(nfold,1);
    fitcounts=zeros(nfold,2);valcounts=zeros(nfold,1);
    out=struct('alpha',0,'fallback',true,'reason','', ...
        'cv_scores_rad',nan(1,numel(a)),'cv_affine_rad',NaN,'cv_best_rad',NaN, ...
        'candidate_alpha',NaN,'cv_improvement_rad',NaN, ...
        'cv_improvement_fraction',NaN,'cv_folds_ok',false, ...
        'fitted_peak_MHz',max(abs(sapc.delta_q_Hz(:)))/1e6, ...
        'data_hessian_rcond',sapc.rcond_data_hessian, ...
        'jacobian_rank',sapc.jacobian_rank, ...
        'fit_counts',fitcounts,'validation_counts',valcounts, ...
        'validation_fit_separation_m',cfg.v7c.cv_guard_m);
    if sapc.jacobian_rank<4 || ~isfinite(sapc.rcond_data_hessian) || ...
            sapc.rcond_data_hessian<cfg.v7c.min_data_rcond
        out.reason='full SAPC data Hessian rank/condition gate';return;
    end
    % 限制的是相对于 affine 的新增非仿射修正；不能把大校正伪称可信。
    extra= (sapc.q_corrected_Hz(:)-affine.q_corrected_Hz(:));
    if max(abs(extra))>cfg.v7c.max_extra_correction_MHz*1e6
        out.reason='non-affine correction size gate';return;
    end
    for fold=1:nfold
        frac=cfg.v7c.cv_frac(fold,:);
        lo=train_lo+(train_hi-train_lo)*frac(1);
        hi=train_lo+(train_hi-train_lo)*frac(2);
        val=eligible & mid>=lo & mid<=hi;
        validx=find(val);validx=validx(1:cfg.v7.training_stride:end);
        fit_allowed= in_train & (mid<lo-cfg.v7c.cv_guard_m | mid>hi+cfg.v7c.cv_guard_m);
        fitcounts(fold,1)=nnz(fit_allowed);
        valcounts(fold)=numel(validx);
        if numel(validx)<cfg.v7c.min_validation_gauges || ...
                nnz(fit_allowed)<cfg.v7c.min_training_gauges*cfg.v7.training_stride
            out.reason='insufficient spatially separated training/validation gauges';return;
        end
        % 从实现层面验证“禁用 + 保护带”：拟合掩码和验证索引不得重叠。
        if any(fit_allowed(validx)) || any(mid(fit_allowed)>=lo-cfg.v7c.cv_guard_m & ...
                                    mid(fit_allowed)<=hi+cfg.v7c.cv_guard_m)
            error('V7c:Leakage','CV gauge 与训练 gauge 泄漏或保护带无效');
        end
        try
            aa=v7c_fit_subset(cfg,truth,reftrace,signal,q0,'affine',fit_allowed);
            ff=v7c_fit_subset(cfg,truth,reftrace,signal,q0,'full',fit_allowed);
        catch ME
            out.reason=['fold-fit failed: ' ME.identifier];return;
        end
        fitcounts(fold,2)=ff.train_count;
        if ff.jacobian_rank<4 || ff.rcond_data_hessian<cfg.v7c.min_data_rcond
            out.reason='fold data Jacobian rank/condition gate';return;
        end
        for k=1:numel(a)
            qalpha=aa.q_corrected_Hz(:)+a(k)*(ff.q_corrected_Hz(:)-aa.q_corrected_Hz(:));
            if any(diff(qalpha)<=0)||max(abs(qalpha-q0(:)))>cfg.v7.max_correction_MHz*1e6
                out.reason='candidate coordinate monotonicity/size gate';return;
            end
            try
                trace=v6_reconstruct_trace(cfg,truth,signal,qalpha);
                C=trace.spectrum(:).*conj(R);
                phasor=C(J).*conj(C(I));
                w=cfg.v6c.phase_avg_bins;
                if w>1,phasor=conv(phasor,ones(w,1)/w,'same');end
                p=angle(phasor(validx));
                if ~all(isfinite(p)),error('V7c:Nonfinite','CV phase nonfinite');end
                errs(fold,k)=sum(p.^2);
            catch ME
                out.reason=['fold evaluation failed: ' ME.identifier];return;
            end
        end
        weights(fold)=numel(validx);
    end
    out.cv_scores_rad=sqrt(sum(errs,1)/sum(weights));
    out.fit_counts=fitcounts;out.validation_counts=valcounts;
    out.cv_folds_ok=true;out.cv_affine_rad=out.cv_scores_rad(1);
    [best,ind]=min(out.cv_scores_rad);
    out.candidate_alpha=a(ind);out.cv_best_rad=best;
    out.cv_improvement_rad=out.cv_affine_rad-best;
    out.cv_improvement_fraction=out.cv_improvement_rad/max(out.cv_affine_rad,eps);
    if ind==1
        out.reason='CV selected affine';return;
    end
    if out.cv_improvement_fraction < cfg.v7c.cv_required_relative_gain || ...
       out.cv_improvement_rad < cfg.v7c.cv_required_absolute_rad
        out.reason='CV gain below predeclared trust threshold';return;
    end
    out.alpha=a(ind);out.fallback=false;out.reason='CV accepted non-affine blend';
end
