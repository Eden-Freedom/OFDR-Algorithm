function y=v5_direct_z(q_Hz, samples, z_m, density, window, cfg)
%V5_DIRECT_Z 在任意连续物理距离 z 上直接求和，解决 V3 仅整数 k 的限制。
% R(z)=1/N sum_n d_n w_n s_n exp(-i*4*pi*n_g*z*q_n/c)。
% 该式不需 1/dz 量化，适合局部峰位、FWHM 精确评估。
    q=q_Hz(:);s=samples(:);z=z_m(:);d=density(:);w=window(:);
    N=numel(q);
    if N~=numel(s)||N~=numel(d)||N~=numel(w)||any(~isfinite(q)) ...
       ||any(~isfinite(s))||any(~isfinite(z))||any(diff(q)<=0)
        error('任意 z 直接变换：输入无效或光频坐标非严格递增。');
    end
    alpha=4*pi*cfg.fut.group_index/cfg.const.c_m_s;
    block=cfg.v5.direct_block_size;
    coef=(s.*d.*w)/N;
    y=complex(zeros(numel(z),1));
    for first=1:block:numel(z)
        ids=first:min(numel(z),first+block-1);
        phase=alpha*(q*z(ids).');
        y(ids)=(coef.'*exp(-1i*phase)).';
    end
end
