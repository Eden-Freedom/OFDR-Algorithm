function width_m = energy_width_v4(z_m, spectrum, energy_fraction)
%ENERGY_WIDTH_V4 计算能量累计分布中间 energy_fraction 所占的距离宽度。
% 此指标可描述未校准展宽的宽谱/多波纹，不会把 FFT 宽谱的局部小尖峰
% 错误解释为高空间分辨率。只用于孤立反射点的无噪声谱。
    if nargin<3,energy_fraction=0.90;end
    z=z_m(:);p=abs(spectrum(:)).^2;
    if ~(energy_fraction>0 && energy_fraction<1) || numel(z)~=numel(p) ...
            || any(diff(z)<=0) || sum(p)<=0
        error('能量宽度参数错误。');
    end
    p=p/sum(p);
    cum=cumsum(p);
    q1=(1-energy_fraction)/2;
    q2=1-q1;
    z1=percentile_crossing(z,cum,q1);
    z2=percentile_crossing(z,cum,q2);
    width_m=max(0,z2-z1);
end

function zp=percentile_crossing(z,cum,q)
    right=find(cum>=q,1,'first');
    if isempty(right),zp=z(end);return;end
    if right==1,zp=z(1);return;end
    x0=cum(right-1);x1=cum(right);
    if x1<=x0,zp=z(right);return;end
    zp=z(right-1)+(q-x0)/(x1-x0)*(z(right)-z(right-1));
end
