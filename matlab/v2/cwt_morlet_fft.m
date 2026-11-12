function cwt = cwt_morlet_fft(x, fs_Hz, opts)
%CWT_MORLET_FFT 自实现基于 FFT 的复 Morlet 连续小波变换。
%   cwt = cwt_morlet_fft(x, fs_Hz, opts)
%
% 理论（角频率 omega，尺度 a 单位 s）：
%   W(a,b) = integral x(t) * conj(psi((t-b)/a)) / sqrt(a) dt
%   Psi(omega) = pi^(-1/4)*exp(-(omega-w0)^2/2), omega>0
%   W(a,:) = IFFT(FFT(x) .* sqrt(a) .* conj(Psi(a*omega)))
% 仅使用正频率，因此解析复系数的相位随时间增长，便于估计瞬时频率。
%
% 注意：这里使用解析 Morlet 的频域近似（屏蔽负频率）。不保证 CWT
% 严格可逆；此项目用它提取局部拍频，而非重建原始时域波形。
% 通过镜像扩展和 FFT 实现快速的近似线性卷积。

    x = x(:);
    N = numel(x);
    if N < 64 || any(~isfinite(x)) || ~isreal(x)
        error('CWT 输入必须为至少 64 点的有限实值向量。');
    end
    if ~(isscalar(fs_Hz) && isfinite(fs_Hz) && fs_Hz > 0)
        error('采样率 fs_Hz 必须为正数。');
    end
    fmin = opts.f_min_Hz;
    fmax = opts.f_max_Hz;
    w0 = opts.morlet_omega0;
    vpo = opts.voices_per_octave;
    if ~(fmin > 0 && fmin < fmax && fmax < fs_Hz/2)
        error('CWT 分析频段必须满足 0<f_min<f_max<fs/2。');
    end
    if ~(w0 >= 4 && w0 <= 20 && vpo >= 4 && vpo == floor(vpo))
        error('请检查 Morlet w0 与每倍频程尺度数量。');
    end

    nscale = ceil(vpo*log2(fmax/fmin)) + 1;
    % 从高频到低频；对应的尺度 a 从小到大（升序）。
    freq_center_Hz = logspace(log10(fmax), log10(fmin), nscale).';
    scales_s = w0 ./ (2*pi*freq_center_Hz);

    % 镜像扩展长度取最大尺度的 8 倍标准差附近，避免边缘严重失真。
    pad = min(N-2, max(2, ceil(opts.padding_sigmas*max(scales_s)*fs_Hz)));
    xpad = [flipud(x(2:pad+1)); x; flipud(x(end-pad:end-1))];
    nfft = 2^nextpow2(numel(xpad));
    X = fft(xpad, nfft);
    % 以 FFT 正负频率次序排列角频率，nfft 是偶数的 2 次幂。
    k = [0:(nfft/2), -(nfft/2-1):-1].';
    omega = 2*pi*fs_Hz*k/nfft;
    positive = (omega > 0);

    W = complex(zeros(nscale, N));
    for j = 1:nscale
        a = scales_s(j);
        psi_hat = pi^(-1/4)*exp(-0.5*(a*omega - w0).^2);
        psi_hat(~positive) = 0;   % 解析小波：去除负频率/直流
        wtemp = ifft(X .* (sqrt(a)*psi_hat), nfft);
        W(j,:) = wtemp(pad+1:pad+N).';
    end

    cwt.W = W;
    cwt.scales_s = scales_s;
    cwt.freq_center_Hz = freq_center_Hz;
    cwt.time_s = (0:N-1).'/fs_Hz;
    cwt.fs_Hz = fs_Hz;
    cwt.pad_points = pad;
    cwt.morlet_omega0 = w0;
end
