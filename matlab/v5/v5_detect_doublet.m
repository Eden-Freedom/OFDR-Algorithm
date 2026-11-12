function d=v5_detect_doublet(z_m,Y,z1,z2,valley_threshold_dB)
%V5_DETECT_DOUBLET 预注册已知区域内的双峰判据（非盲检）。
% 每个目标点±min(0.4mm,0.25*间距)必须找到局部极大值，
% 两峰之间的谷值功率需低于较弱峰 3dB（可配），两峰独立。
    z=z_m(:);p=abs(Y(:)).^2;
    dz=z2-z1;
    half=min(.4e-3,.25*dz);
    peaks=find(p(2:end-1)>p(1:end-2)&p(2:end-1)>=p(3:end))+1;
    i1=peaks(abs(z(peaks)-z1)<=half);
    i2=peaks(abs(z(peaks)-z2)<=half);
    d.success=false;d.reason='';d.peak1_m=NaN;d.peak2_m=NaN;
    d.valley_dB=NaN;d.candidate_count=numel(peaks);
    if isempty(i1)||isempty(i2)
        d.reason='某一预注册搜索区无局部极大值';return;
    end
    [~,v1]=max(p(i1));[~,v2]=max(p(i2));
    a=i1(v1);b=i2(v2);
    if b<=a+1,d.reason='峰值未分离';return;end
    valley=min(p(a:b));
    d.peak1_m=z(a);d.peak2_m=z(b);
    d.valley_dB=10*log10(max(valley,realmin)/min(p(a),p(b)));
    d.success=d.valley_dB<=-valley_threshold_dB;
    if ~d.success,d.reason='两峰间谷深不足';end
end
