function result = nufft_gaussian_type1_v3(u, x, weights, k, opts)
%NUFFT_GAUSSIAN_TYPE1_V3 一维 Type-1 Gaussian Gridding 非均匀 FFT。
% 目标（用 NUDFT 作真值）：
%   F(k)=(1/N)*sum_n weights(n)*x(n)*exp(-1i*2*pi*k*u(n))
% 1) 非均匀 u_n 映射到 K=ceil(alpha*N) 的周期网格 p_n=K*u_n。
% 2) 各采样值用 Gaussian 核分摊给附近 J=kernel_width 个网格点。
% 3) 对长度为 K 的网格做标准 FFT。
% 4) 除以离散高斯核在相应 k 的傅里叶响应，补偿卷积平滑效应。
%
% 使用高斯核 exp(-d^2/(2*sigma2))，sigma2 的选择平衡离散化混叠
% 和有限核截断误差，并非直接将论文中不同归一化形式的 tau 硬套用。
% 只计算 k=0..floor(N/2) 以满足当前实值 OFDR 的正距离支路。
% 这是近似 NUFFT，收敛性以 nudft_reference_v3 为判断标准。
    u=u(:);x=x(:);weights=weights(:);k=k(:);
    N=numel(u);
    if N<16 || numel(x)~=N || numel(weights)~=N || ...
       any(~isfinite(u)) || any(~isfinite(x)) || any(~isfinite(weights)) || ...
       any(diff(u)<=0) || u(1)<0 || u(end)>=1 || ...
       any(~isfinite(k)) || any(k<0) || any(k~=floor(k)) || ...
       any(k>floor(N/2))
        error('NUFFT：位置必须严格递增且在 [0,1)；k 必须为 0..floor(N/2)。');
    end
    alpha=opts.alpha;
    J=opts.kernel_width;
    if ~(isscalar(alpha) && isfinite(alpha) && alpha>1 && ...
         isscalar(J) && isfinite(J) && J>=4 && J==floor(J))
        error('NUFFT 需要 alpha>1 且核宽度 J 为 >=4 的整数。');
    end
    K=ceil(alpha*N);
    if K<=N || J>=K, error('过采样网格太小，或核宽度超出网格。'); end
    alpha_effective=K/N;

    % Gaussian 最优近似平衡：有限 J 截断 vs 折叠频谱 (aliasing)。
    sigma2=J/(4*pi*(1-1/(2*alpha_effective)));
    pos=K*u;
    base=floor(pos);           % 0-based 网格索引，向量长度 N
    offsets=(-floor((J-1)/2)):ceil((J-1)/2);
    coeff=(x.*weights)/N;

    tgrid=tic;
    grid_real=zeros(K,1);grid_imag=zeros(K,1);
    for h=1:numel(offsets)
        unwrapped=base+offsets(h);
        d=unwrapped-pos;
        local_kernel=exp(-(d.^2)/(2*sigma2));
        bin=mod(unwrapped,K)+1; % 周期包裹：边界样本不能被截掉
        add=coeff.*local_kernel;
        grid_real=grid_real+accumarray(bin,real(add),[K,1],@sum,0);
        grid_imag=grid_imag+accumarray(bin,imag(add),[K,1],@sum,0);
    end
    grid_signal=complex(grid_real,grid_imag);
    t_gridding=toc(tgrid);

    tfft=tic;
    grid_fft=fft(grid_signal);
    t_fft=toc(tfft);

    t_deconv=tic;
    % 高斯函数在网格上周期化后的连续傅里叶系数：
    % G(k)=sqrt(2*pi*sigma2)*exp(-2*pi^2*sigma2*(k/K)^2)
    kernel_ft=sqrt(2*pi*sigma2)*exp(-2*pi^2*sigma2*(k/K).^2);
    if any(kernel_ft<1e-12)
        error('高斯去卷积因子过小：检查 alpha/kernel_width/k。');
    end
    spectrum=grid_fft(k+1)./kernel_ft;
    t_deconvolution=toc(t_deconv);

    result.k=k;
    result.spectrum=spectrum;
    result.grid_signal=grid_signal;
    result.K=K;
    result.alpha_effective=alpha_effective;
    result.kernel_width=J;
    result.sigma2_bins=sigma2;
    result.kernel_ft=kernel_ft;
    result.gridding_s=t_gridding;
    result.fft_s=t_fft;
    result.deconvolution_s=t_deconvolution;
    result.total_s=t_gridding+t_fft+t_deconvolution;
end
