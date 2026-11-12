function truth = simulate_laser_sweep(cfg)
%SIMULATE_LASER_SWEEP 产生含周期失真与慢变漂移的 TLS 扫频真值。
% 输入 cfg: config_v1 生成的配置结构体。
% 输出 truth: 时间、绝对光频、相对光频、波长、瞬时扫频速率（SI 单位）。
%
%   x = t/T
%   u(x) = x + a/(2*pi*m)*sin(2*pi*m*x) + b*x*(1-x)
%   nu(t) = nu_start + DeltaNu*u(x)
%   dnu/dt = DeltaNu/T * [1+a*cos(2*pi*m*x)+b*(1-2*x)]
%
% 采样点 t_n = n/fs, n=0,...,N-1。t=T 属于扫频末端，不额外采样。

    N = cfg.acq.N;
    fs = cfg.acq.fs_Hz;
    T = cfg.laser.duration_s;
    a = cfg.laser.ripple_a;
    b = cfg.laser.drift_b;
    m = cfg.laser.ripple_cycles;
    c = cfg.const.c_m_s;

    if ~(isscalar(N) && N >= 8 && N == floor(N) && isfinite(N))
        error('采样点数 N 必须为不小于 8 的整数。');
    end
    if ~(isfinite(fs) && fs > 0 && isfinite(T) && T > 0)
        error('采样率 fs 和扫描时间 T 必须为正数。');
    end
    if abs(fs*T - N) > 1e-8*max(N, 1)
        error('当前配置要求 fs*T=N，保证扫描时长和采样网格一致。');
    end
    if ~(isscalar(m) && isfinite(m) && m > 0 && m == floor(m))
        error('扰动周期数 m 必须为正整数。');
    end
    if ~(all(isfinite([a, b])) && (abs(a)+abs(b) < 1))
        error('请满足 |a|+|b|<1，以保证单调扫频（充分条件）。');
    end
    if ~(cfg.laser.lambda_end_m > 0 && ...
            cfg.laser.lambda_start_m > cfg.laser.lambda_end_m)
        error('V1 要求 lambda_start_m > lambda_end_m > 0，即光频正向扫描。');
    end

    t = (0:N-1).' / fs;
    x = t / T;
    u = x + (a/(2*pi*m))*sin(2*pi*m*x) + b*x.*(1-x);
    du_dx = 1 + a*cos(2*pi*m*x) + b*(1-2*x);

    nu_start = c/cfg.laser.lambda_start_m;
    nu_end = c/cfg.laser.lambda_end_m;
    delta_nu = nu_end-nu_start;
    nu_offset = delta_nu*u;  % 相位计算使用偏移量，避免 193 THz 大数精度问题
    nu = nu_start+nu_offset;

    truth.t_s = t;
    truth.x = x;
    truth.u = u;
    truth.nu_Hz = nu;
    truth.nu_offset_Hz = nu_offset;
    truth.nu_start_Hz = nu_start;
    truth.nu_end_Hz = nu_end;
    truth.delta_nu_Hz = delta_nu;
    truth.lambda_m = c./nu;
    truth.tuning_rate_Hz_s = (delta_nu/T)*du_dx;
    truth.N = N;
    truth.fs_Hz = fs;
    truth.dt_s = 1/fs;
end
