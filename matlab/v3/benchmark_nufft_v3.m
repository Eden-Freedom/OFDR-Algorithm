function bench = benchmark_nufft_v3(cfg)
%BENCHMARK_NUFFT_V3 独立数值基准：N 从 256 到 2048。
% 注意这里单独构造带宽内的复数测试信号，独立于 OFDR 模拟的采样率，
% 以便不违反 V1 当 N 变小时可能出现的探测器奈奎斯特条件。
% 计时包含 NUFFT 网格化/FFT/去卷积或 NUDFT 求和；重复取中位数。
    sizes=cfg.v3.benchmark_sizes(:);
    reps=cfg.v3.benchmark_repeats;
    if any(sizes<64) || any(sizes~=floor(sizes)) || reps<1 || reps~=floor(reps)
        error('benchmark_sizes 至少为 64 的正整数，repeats 为正整数。');
    end
    bench.N=sizes;
    bench.direct_s=zeros(size(sizes));
    bench.nufft_s=zeros(size(sizes));
    bench.relative_error=zeros(size(sizes));
    for i=1:numel(sizes)
        N=sizes(i);v=(0:N-1)'/N;
        u=v+0.12/(4*pi)*sin(4*pi*v)+0.04*v.*(1-v);
        % 定义复信号，避免实信号共轭峰带来的观测混淆。
        x=exp(2i*pi*17*u)+0.3*exp(2i*pi*41*u+0.3);
        weights=frequency_density_weights_v3(u,cfg.v3.density_mode);
        x=x.*spectral_window_v3(u,cfg.v3.window);
        k=(0:floor(N/2)).';
        timings_d=zeros(reps,1);timings_n=zeros(reps,1);
        for r=1:reps
            timer=tic;
            direct=nudft_reference_v3(u,x,weights,k);
            timings_d(r)=toc(timer);
            timer=tic;
            approx=nufft_gaussian_type1_v3(u,x,weights,k,cfg.v3);
            timings_n(r)=toc(timer);
        end
        bench.direct_s(i)=median(timings_d);
        bench.nufft_s(i)=median(timings_n);
        bench.relative_error(i)=norm(approx.spectrum-direct)/max(norm(direct),realmin);
    end
end
