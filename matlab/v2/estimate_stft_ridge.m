function stft = estimate_stft_ridge(x, fs_Hz, opts, smooth_points)
%ESTIMATE_STFT_RIDGE 自行实现 STFT 基线（Hann 窗 + 分帧 FFT）。
% 各帧寻找正频峰并做抛物线精细化；将帧中心频率插值回原采样时间。
% 反射边界避免零填充时第一个/最后一个时间窗的瞬时频率偏移。

    x=x(:); N=numel(x);
    L=opts.window_length;
    H=opts.hop_length;
    nfft=opts.nfft;
    if ~(L>=16 && L==floor(L) && L<=N && H>=1 && H==floor(H) && ...
         nfft>=L && nfft==floor(nfft))
        error('STFT 参数必须满足 16<=window<=N、hop>=1、nfft>=window。');
    end
    window = (0.5-0.5*cos(2*pi*(0:L-1)'/(L-1)));
    centers = unique([1:H:N, N]);
    nframe=numel(centers);
    nf=floor(nfft/2)+1;
    spec=complex(zeros(nf,nframe));
    ridge_frames=zeros(nframe,1);
    freq_axis=(0:nf-1)'*fs_Hz/nfft;
    for j=1:nframe
        idx = centers(j) + ((0:L-1)'-floor(L/2));
        % 镜像反射索引：映射到 [1,N]，而不是直接截断数据。
        q = mod(idx-1, 2*(N-1));
        inds = 1+min(q,2*(N-1)-q);
        Y = fft(x(inds).*window,nfft);
        spec(:,j) = Y(1:nf);
        [~,k]=max(abs(spec(2:end-1,j)));
        k=k+1;
        y1=log(max(abs(spec(k-1,j)),realmin));
        y2=log(max(abs(spec(k,j)),realmin));
        y3=log(max(abs(spec(k+1,j)),realmin));
        den=y1-2*y2+y3;
        delta=0;
        if abs(den)>1e-12
            delta=max(-1,min(1,0.5*(y1-y3)/den));
        end
        ridge_frames(j) = ((k-1)+delta)*fs_Hz/nfft;
    end
    tframes=(centers-1)'/fs_Hz;
    t=(0:N-1)'/fs_Hz;
    track=interp1(tframes,ridge_frames,t,'pchip');
    if smooth_points>1
        track=movmean(track,smooth_points);
    end
    stft.S=spec;
    stft.time_s=tframes;
    stft.freq_axis_Hz=freq_axis;
    stft.ridge_frame_Hz=ridge_frames;
    stft.freq_Hz=track;
end
