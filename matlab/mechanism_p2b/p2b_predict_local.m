function o=p2b_predict_local(r0,fminus,fplus,h,ftest,alpha)
%P2B_PREDICT_LOCAL 从同一Core Gauge上的有限差分得到局部预测（单位με）。
% r0=epshat(alpha=0)-eps_true; f±=epshat(±h); ftest=epshat(alpha)。
% 模型 Cpred(alpha) = 2*alpha*mean(r0.*g) + alpha^2*mean(g.^2)
% 观测 Cactual(alpha)=mean((ftest-true).^2)-mean(r0.^2)
% 此函数为了独立单元验证直接接受真值误差r0。
% 这些变量仅用于物理机理Oracle诊断，不能作为实际校正器的输入。
    r0=r0(:);fminus=fminus(:);fplus=fplus(:);
    ftest=ftest(:);
    if ~isscalar(h)||~isfinite(h)||h<=0||~isscalar(alpha)|| ...
       ~isfinite(alpha)|| ...
       numel(r0)~=numel(fminus)||numel(r0)~=numel(fplus)|| ...
       numel(r0)~=numel(ftest)||isempty(r0)|| ...
       any(~isfinite([r0;fminus;fplus;ftest]))
        error('P2B:PredictInput','有限差分输入必须合法且Core长度一致。');
    end
    g=(fplus-fminus)/(2*h);
    f0=0.5*(fplus+fminus); %#ok<NASGU> 不作为预测截距，以避免二阶偏差
    % F(0)-truth = r0; 对非零应变，真值只进入残差r0和事后评分。
    linear=2*alpha*mean(r0.*g);
    quadratic=alpha^2*mean(g.^2);
    o.g=g;
    o.g_rms=sqrt(mean(g.^2));
    o.cross_mean=mean(r0.*g);
    o.g_square_mean=mean(g.^2);
    o.linear_term=linear;
    o.quadratic_term=quadratic;
    o.C_pred=linear+quadratic;
end