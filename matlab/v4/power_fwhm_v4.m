function width_m = power_fwhm_v4(z_m, spectrum, expected_peak_m)
%POWER_FWHM_V4 孤立峰功率半高宽，含左右阈值交点线性插值。
% 峰定位限制在真反射点±0.05 m，避免将其他反射点的峰作为目标。
% 对严重展宽而无法确定两侧半功率点的谱，返回 NaN（不伪造峰宽）。
    z=z_m(:);y=abs(spectrum(:)).^2;
    if numel(z)~=numel(y) || any(diff(z)<=0)
        error('FWHM 输入的距离网格必须严格递增。');
    end
    ids=find(abs(z-expected_peak_m)<=0.05);
    width_m=NaN;
    if numel(ids)<4, return; end
    [~,ix]=max(y(ids));p=ids(ix);
    h=y(p)/2;
    ileft=find(y(1:p-1)<h,1,'last');
    iright_rel=find(y(p+1:end)<h,1,'first');
    if isempty(ileft) || isempty(iright_rel),return;end
    iright=p+iright_rel;
    zL=linear_crossing(z(ileft),z(ileft+1),y(ileft),y(ileft+1),h);
    zR=linear_crossing(z(iright-1),z(iright),y(iright-1),y(iright),h);
    width_m=max(0,zR-zL);
end

function zcross=linear_crossing(z0,z1,y0,y1,ycross)
    if abs(y1-y0)<1e-30, zcross=(z0+z1)/2;
    else, zcross=z0+(ycross-y0)*(z1-z0)/(y1-y0);
    end
end
