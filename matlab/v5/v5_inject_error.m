function e=v5_inject_error(context, kind, target_rmse_MHz, seed, normalization)
%V5_INJECT_ERROR 注入首样本锚定的光频误差（时间/光频轴定义见分支）。
% 不改真实主信号；同 RMS 不代表同均值/同斜率，需随后做分解。
    if nargin<4,seed=context.cfg.v5.random_seed;end
    if nargin<5,normalization='raw';end
    q=context.q_true_Hz(:);u=q/context.bandwidth_Hz;
    t=context.truth.t_s(:);x=(t-t(1))/(context.cfg.laser.duration_s);
    N=numel(q);
    if target_rmse_MHz==0,e=zeros(N,1);return;end
    switch kind
        case 'scale'
            shape=u;
        case 'quadratic'
            shape=x.*(1-x); % 时间轴上平滑弯曲误差
        case 'boundary_start'
            w=.035; shape=(x/w).*exp(-x/w); % 起点严格为0
        case 'boundary_end'
            w=.035; shape=exp(-((1-x)/w).^2);
        case 'correlated_short'
            shape=correlated(N,16,seed);
        case 'correlated_long'
            shape=correlated(N,128,seed);
        otherwise
            if strncmp(kind,'periodic_',9)
                cyc=str2double(kind(10:end));
                if ~isfinite(cyc)||cyc<1,error('周期数非法');end
                shape=sin(2*pi*cyc*u); % 光频轴上构造
            else
                error('未知误差类型 %s',kind);
            end
    end
    shape=shape(:)-shape(1); % 注入后的相对坐标锚定为0
    if strcmp(normalization,'raw')
        rms_shape=sqrt(mean(shape.^2));
    elseif strcmp(normalization,'residual')
        decomposition=v5_error_decomposition(context,shape);
        rms_shape=decomposition.residual_rms_Hz;
    else
        error('归一化必须指定 raw 或 residual。');
    end
    if rms_shape<1e-12,error('误差形状退化或去仿射残差接近0');end
    e=shape/rms_shape*(target_rmse_MHz*1e6);
end
function x=correlated(N,sigma,seed)
    rng(seed,'twister');raw=randn(N,1);
    radius=ceil(4*sigma); lag=(-radius:radius)';
    g=exp(-.5*(lag/sigma).^2);g=g/sum(g);
    x=conv(raw,g,'same');
end
