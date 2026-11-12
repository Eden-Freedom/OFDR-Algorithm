function w = spectral_window_v3(u, mode)
%SPECTRAL_WINDOW_V3 在物理光频轴 u=(nu-nu0)/DeltaNu 上施加统一窗。
% Hann 加窗可减小有限带宽引起的旁瓣，但会增宽理想主瓣。
    u=u(:);
    if any(~isfinite(u)) || any(u<0) || any(u>1+1e-12)
        error('光频归一化坐标要求 0 <= u <= 1。');
    end
    switch lower(mode)
        case 'hann'
            w=0.5-0.5*cos(2*pi*u);
        case 'none'
            w=ones(size(u));
        otherwise
            error('未知 window，请使用 ''hann'' 或 ''none''。');
    end
end
