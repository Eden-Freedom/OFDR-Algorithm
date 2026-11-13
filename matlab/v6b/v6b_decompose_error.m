function d = v6b_decompose_error(q_true_Hz,e_Hz,weights)
%V6B_DECOMPOSE_ERROR 加权最小二乘，辨识统计均值、比例斜率和非仿射残差。
% 注意：常数绝对偏置在首样本锚定时消失；这里的均值并非可独立注入的
% 物理绝对光频偏置。真正的可重建分量是锚定线性斜率与锚定非线性剩余。
    q=q_true_Hz(:);e=e_Hz(:);w=weights(:);
    if numel(q)~=numel(e)||numel(e)~=numel(w)||any(~isfinite([q;e;w])) || any(w<0) || sum(w)<=0
        error('V6b:InvalidDecomposition','加权分解输入无效。');
    end
    wn=w/sum(w);
    q0=sum(wn.*q); e0=sum(wn.*e);
    x=q-q0;
    denom=sum(wn.*x.^2);
    if denom<=0,error('V6b:DegenerateSweep','光频跨度不足。');end
    a=sum(wn.*x.*(e-e0))/denom;
    fit=e0+a*x;
    residual=e-fit;
    ramp=a*(q-q(1));
    nonlinear=residual-residual(1);
    d.weighted_mean_Hz=e0;
    d.scale_ppm=1e6*a;
    d.raw_rmse_Hz=sqrt(mean(e.^2));
    d.centered_weighted_rmse_Hz=sqrt(sum(wn.*(e-e0).^2));
    d.nonlinear_weighted_rmse_Hz=sqrt(sum(wn.*residual.^2));
    d.fitted_Hz=fit;
    d.unanchored_residual_Hz=residual;
    d.anchored_ramp_Hz=ramp;
    d.anchored_nonlinear_Hz=nonlinear;
    d.reconstruction_max_error_Hz=max(abs((ramp+nonlinear)-(e-e(1))));
end
