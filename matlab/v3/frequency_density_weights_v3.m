function weights = frequency_density_weights_v3(u, mode)
%FREQUENCY_DENSITY_WEIGHTS_V3 近似非均匀光频采样对应的积分测度。
%   - 'none'    : 每个样本取权重 1，对应等权离散 NUDFT。
%   - 'voronoi' : 局部光频间隔的 Voronoi 梯形权重，再令均值为 1。
% 两种方式解决的是不同数学目标：等权求和 vs 对光频积分的离散近似。
% 本项目所有 NUDFT / NUFFT 对比都使用 *完全相同* 的 weights。
    u=u(:); N=numel(u);
    if N<3 || any(~isfinite(u)) || any(diff(u)<=0)
        error('归一化光频位置必须是长度 >=3 的严格递增有限向量。');
    end
    switch lower(mode)
        case 'none'
            weights=ones(N,1);
        case 'voronoi'
            d=diff(u);
            weights=[d(1); 0.5*(d(1:end-1)+d(2:end)); d(end)];
            weights=weights/mean(weights); % 使均匀采样时近似为 1
        otherwise
            error('未知 density_mode：请使用 ''none'' 或 ''voronoi''。');
    end
end
