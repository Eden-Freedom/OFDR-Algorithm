function out = nudft_reference_v3(u, x, weights, k, chunk_size)
%NUDFT_REFERENCE_V3 直接计算非均匀离散傅里叶求和，O(N*M)。
%   out(k) = (1/N) * sum_n weights(n)*x(n)*exp(-1i*2*pi*k*u(n))
%   u: 归一化光频位置，严格递增且 0<=u<1。
%   x: *已完成光频窗处理* 的复/实采样值。
%   weights: 与 NUFFT 使用的密度权重完全一致。
%   k: 非负整数，代表空间坐标 z_k=c*k/(2*ng*DeltaNu)。
% 大数据集使用分块以防产生 N*M 的巨型临时矩阵；V3 默认只取稀疏
% k 点做精度检验，绝不假装它和 N 点 FFT 有相同复杂度。
    if nargin<5 || isempty(chunk_size), chunk_size=64; end
    u=u(:);x=x(:);weights=weights(:);k=k(:);
    N=numel(x);
    if N<2 || numel(u)~=N || numel(weights)~=N || ...
       any(~isfinite(u)) || any(~isfinite(x)) || any(~isfinite(weights)) || ...
       any(diff(u)<=0) || u(1)<0 || u(end)>=1 || ...
       any(~isfinite(k)) || any(k<0) || any(k~=floor(k))
        error('NUDFT 输入：u 需递增且位于 [0,1)，k 为非负整数，数据等长有限。');
    end
    coeff=(weights.*x)/N;
    out=complex(zeros(numel(k),1));
    for lo=1:chunk_size:numel(k)
        hi=min(numel(k),lo+chunk_size-1);
        E=exp((-2i*pi)*(u*k(lo:hi).'));
        out(lo:hi)=E.'*coeff; % 非共轭转置，傅里叶核指数的负号不改变
    end
end
