function m=v5_peak_metrics(z_m, spectrum, z_expected, cfg)
%V5_PEAK_METRICS 同网格比较真实/估计的细网格峰位、功率半高宽。
% 能量90%为“当前相同局部评估窗内”的5%-95%积分分位差，非全距FFT。
% 若边缘能量占比高，则无法声称局部能量宽度代表完整峰。
    z=z_m(:);y=spectrum(:);p=abs(y).^2;
    if numel(z)~=numel(p)||numel(z)<5||any(diff(z)<=0)||any(~isfinite(p))
        error('计算峰宽时需要有限的严格递增细距离网格。');
    end
    m.valid=false;m.reason='';m.peak_m=NaN;m.absolute_error_m=NaN;
    m.fwhm_m=NaN;m.energy90_width_m=NaN;m.peak_power=NaN;
    m.peak_phase_rad=NaN;m.sidelobe_dB=NaN;m.edge_fraction=NaN;
    [peak_power,j]=max(p);
    if peak_power<=0,m.reason='无有效峰';return;end
    m.peak_m=z(j);m.absolute_error_m=z(j)-z_expected;
    m.peak_power=peak_power;m.peak_phase_rad=angle(y(j));
    h=peak_power/2;
    left=find(p(1:j-1)<h,1,'last');
    rightrel=find(p(j+1:end)<h,1,'first');
    if isempty(left)||isempty(rightrel)
        m.reason='半功率点缺失：宽峰或搜索窗不足';return;
    end
    right=j+rightrel;
    zl=interp_cross(z(left),z(left+1),p(left),p(left+1),h);
    zr=interp_cross(z(right-1),z(right),p(right-1),p(right),h);
    m.fwhm_m=zr-zl;
    % 用与峰位无关的同一个物理局部窗进行能量积分，不把步数当作概率。
    area=cumtrapz(z,p);
    if area(end)<=0,m.reason='总能量为零';return;end
    a05=interp_cumulative(z,area,area(end)*.05);
    a95=interp_cumulative(z,area,area(end)*.95);
    m.energy90_width_m=a95-a05;
    % 边界能量监控：用两端 ~5% 区域积分占比检查局部裁剪。
    edge=max(2,round(.05*numel(z)));
    m.edge_fraction=(trapz(z(1:edge),p(1:edge))+ ...
                    trapz(z(end-edge+1:end),p(end-edge+1:end)))/area(end);
    % 主瓣排除区 ±1.5 FWHM，旁瓣测试只在当前评估窗口内成立。
    outer=abs(z-m.peak_m)>1.5*m.fwhm_m;
    if any(outer)
        m.sidelobe_dB=10*log10(max(p(outer))/peak_power);
    end
    m.valid=true;
end
function x=interp_cross(x0,x1,y0,y1,target)
    if y1==y0,x=(x0+x1)/2;else,x=x0+(target-y0)*(x1-x0)/(y1-y0);end
end
function x=interp_cumulative(z,c,target)
    i=find(c>=target,1,'first');
    if i<=1,x=z(1);return;end
    if c(i)==c(i-1),x=z(i);return;end
    x=z(i-1)+(target-c(i-1))/(c(i)-c(i-1))*(z(i)-z(i-1));
end
