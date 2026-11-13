function [lo,hi] = v6b_bootstrap_ci(values,B,seed)
%V6B_BOOTSTRAP_CI 对不同 trial 做非参数 bootstrap 的均值95%区间。
% 这里每个 trial 是独立重复，空间上相邻的 gauge 不当作独立样本。
    v=values(:);v=v(isfinite(v));n=numel(v);
    if n==0,lo=NaN;hi=NaN;return;end
    if n==1,lo=NaN;hi=NaN;return;end
    rng(seed,'twister');
    boot=zeros(B,1);
    for k=1:B
        ii=randi(n,n,1);
        boot(k)=mean(v(ii));
    end
    boot=sort(boot);
    lo=boot(max(1,ceil(.025*B)));
    hi=boot(min(B,max(1,ceil(.975*B))));
end
