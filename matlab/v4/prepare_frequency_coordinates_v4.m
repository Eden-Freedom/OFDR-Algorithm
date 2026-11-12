function [u,meta] = prepare_frequency_coordinates_v4(nu_offset_Hz, cfg, label)
%PREPARE_FREQUENCY_COORDINATES_V4 将估计光频轨迹转成 NUFFT 的归一化坐标。
% 物理量：u(t)=[nu_hat(t)-nu_hat(0)]/DeltaNu_nominal。
% 输入轨迹来自辅助 MZI 的拍频积分，不能直接将 SSWT 时频系数送入 NUFFT。
% 分母由独立给定的 TLS 标称起止波长确定，而非使用真实模拟轨迹。
% 保留光频误差，避免通过用 truth.u 归一化人为提高校准精度。
    if nargin<3 || isempty(label), label='estimated'; end
    x=nu_offset_Hz(:);
    if isempty(x) || numel(x)<16 || any(~isfinite(x))
        error('%s 光频估计必须是有限且不少于16个样本。',label);
    end
    if ~strcmpi(cfg.v4.normalization,'nominal')
        error('V4 目前仅实现 nominal 归一化模式，以保证绝对距离刻度可解释。');
    end
    nominal=cfg.const.c_m_s*(1/cfg.laser.lambda_end_m-1/cfg.laser.lambda_start_m);
    if ~(nominal>0 && isfinite(nominal))
        error('TLS 标称扫频带宽必须为正。');
    end
    % 首样本锚定。对于 V2，nu_offset(1) 应为 0；不从真实轨迹导入额外修正。
    u=(x-x(1))/nominal;
    d=diff(u);
    if any(d<=0)
        error('%s 校准轨迹非严格递增。需先检查 SSWT 错误脊线，不能排序后冒充原时序。',label);
    end
    if u(1)<0 || u(end)>=1
        error(['%s 轨迹超出 NUFFT 要求的 [0,1)。当前扫描端点可能有偏差；' ...
            '请检查校准或重新设置独立标称扫描带宽，不要直接截断/取模。'],label);
    end
    meta.nominal_span_Hz=nominal;
    meta.first_u=u(1);
    meta.last_u=u(end);
    meta.max_step=max(d);
    meta.min_step=min(d);
end
