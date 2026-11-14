function [A,t_sample_s]=p2ca_integral_matrix(N,dt_s,tau_s)
%P2CA_INTEGRAL_MATRIX 固定时延辅助MZI的精确分段常值光频积分算子。
%
% 将真实频率偏移 ν_k(Hz) 视为在[(k-1)dt,kdt]内常数，
% φ_j-φ0=2πΣ_k [时间窗口(t_j-τ,t_j]和第k单元的交叠秒数]*ν_k。
%
% 输入：N(频率单元数量)、dt_s(时间步长, s)、tau_s(辅助延时,s)。
% 输出：A为无量纲加权矩阵：若x_k=ν_k*dt_s(每单元的周期数)，
%       则φ=2π*A*x+φ0。A元素为[0,1]的重叠比例。
%       t_sample_s 为所有完整延迟观测时刻（避免窗口外未知历史）。
%
% 注意：不使用平均频率近似2πτν(t)，保留真实积分。理想解缠相位
% 已比真实辅助PD原始cos(φ)包含更多信息，因此辨识失败是强反例。
    if ~isscalar(N)||~isfinite(N)||N~=floor(N)||N<3|| ...
       ~isscalar(dt_s)||~isfinite(dt_s)||dt_s<=0|| ...
       ~isscalar(tau_s)||~isfinite(tau_s)||tau_s<=0||tau_s>N*dt_s
        error('P2CA:Input','N、采样间隔dt或延迟τ不合法。');
    end
    dt=dt_s;
    T=(1:N).'*dt;
    tiny=32*eps(N*dt);
    keep=T+tiny >= tau_s;
    t_sample_s=T(keep);
    m=numel(t_sample_s);
    if m<2
        error('P2CA:Window','完整延迟窗口不足两个样本。');
    end
    A=zeros(m,N);
    left_edges=(0:N-1)*dt;
    right_edges=(1:N)*dt;
    for j=1:m
        aa=t_sample_s(j)-tau_s;
        bb=t_sample_s(j);
        overlap=max(0,min(bb,right_edges)-max(aa,left_edges));
        A(j,:)=overlap/dt;
    end
    expected=tau_s/dt;
    if max(abs(sum(A,2)-expected))>1e-9*max(expected,1)
        error('P2CA:Overlap','窗积分行和不等于τ/dt。');
    end
end