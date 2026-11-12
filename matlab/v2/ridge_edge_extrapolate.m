function [adjusted_Hz, edge_points] = ridge_edge_extrapolate(freq_Hz, fs_Hz, edge_points, fit_points)
%RIDGE_EDGE_EXTRAPOLATE 使用内部可靠脊线对变换边缘做局部二次外推。
% 目的：镜像延拓使靠近 t=0/T 的解析小波相位产生非物理畸变。
% 注意：这是“平滑缓变拍频”这一先验条件下的工程边界校正，
% 不适合扫频启动/结束存在真正突变的情况，必须提供可关闭选项。
    freq_Hz=freq_Hz(:);
    N=numel(freq_Hz);
    edge_points=max(0,min(floor(N/10),round(edge_points)));
    fit_points=max(10,round(fit_points));
    adjusted_Hz=freq_Hz;
    if edge_points<2 || 2*(edge_points+fit_points)>=N
        return;
    end
    dt=1/fs_Hz;
    left_fit=(edge_points+1):(edge_points+fit_points);
    right_fit=(N-edge_points-fit_points+1):(N-edge_points);
    left_edge=1:edge_points;
    right_edge=(N-edge_points+1):N;
    % 中心时间移到拟合窗起点，避免在 0.02 s 这样的小时间上做病态拟合。
    xl=(left_fit-left_fit(1))*dt;
    cl=polyfit(xl(:),freq_Hz(left_fit),2);
    xle=(left_edge-left_fit(1))*dt;
    adjusted_Hz(left_edge)=polyval(cl,xle(:));
    xr=(right_fit-right_fit(1))*dt;
    cr=polyfit(xr(:),freq_Hz(right_fit),2);
    xre=(right_edge-right_fit(1))*dt;
    adjusted_Hz(right_edge)=polyval(cr,xre(:));
end
