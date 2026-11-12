function out=v5_error_decomposition(context,e_Hz)
%V5_ERROR_DECOMPOSITION 真值加权最小二乘：e=b+epsilon*(q-q_bar)+r。
% 权重严格固定为真值坐标下的 Voronoi×Hann，禁止用它来修正实测算法。
    q=context.q_true_Hz(:);e=e_Hz(:);
    if numel(q)~=numel(e)||any(~isfinite(e)),error('误差长度或有限性错误');end
    w=context.weights_true(:).*context.window_true(:);
    w=w/sum(w);
    qbar=sum(w.*q);
    x=q-qbar;
    b=sum(w.*e);
    eps=sum(w.*x.*(e-b))/sum(w.*x.^2);
    r=e-b-eps*x;
    out.mean_Hz=b;out.scale_ppm=eps*1e6;
    out.residual_rms_Hz=sqrt(sum(w.*r.^2));
    out.raw_rmse_Hz=sqrt(mean(e.^2));
    out.max_abs_Hz=max(abs(e));
    out.sample_mean_Hz=mean(e);
    out.residual_Hz=r;
    out.fitted_Hz=b+eps*x;
    out.true_weight=w;
    out.q_center_Hz=qbar;
    % 仅为描述用的一阶相关性；后续不据此独断噪声“白化”。
    centered=r-mean(r);
    denom=sum(centered.^2);
    if denom>0
        out.lag1_correlation=sum(centered(1:end-1).*centered(2:end))/denom;
    else
        out.lag1_correlation=NaN;
    end
end
