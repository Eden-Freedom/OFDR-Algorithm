function [ok,detail,qalpha]=v7d_candidate_feasible(q0,qA,qS,alpha,Lextra_MHz,Ltotal_MHz)
%V7D_CANDIDATE_FEASIBLE 单个候选的确定性物理坐标约束检查。
% 输入：q0辅助估计、qA仿射、qS完整SAPC (Hz)；alpha无单位；
%      Lextra_MHz为相对仿射的额外修正限幅；Ltotal_MHz相对q0总限幅。
% 输出：ok是否可用、detail原因与峰值、qalpha混合后的坐标(Hz)。
% 不读取Rayleigh散射真值、光频真值、应变真值或Holdout评分。
    ok=false;qalpha=[];
    detail=struct('reason','','extra_peak_MHz',NaN,'total_peak_MHz',NaN, ...
                  'min_step_Hz',NaN);
    q0=q0(:);qA=qA(:);qS=qS(:);
    if numel(q0)<2 || numel(qA)~=numel(q0) || numel(qS)~=numel(q0) || ...
            ~isscalar(alpha) || ~isfinite(alpha) || alpha<0 || alpha>1 || ...
            ~isscalar(Lextra_MHz) || ~isfinite(Lextra_MHz) || Lextra_MHz<=0 || ...
            ~isscalar(Ltotal_MHz) || ~isfinite(Ltotal_MHz) || Ltotal_MHz<=0
        detail.reason='invalid dimensions or limits';return;
    end
    if any(~isfinite(q0)) || any(~isfinite(qA)) || any(~isfinite(qS))
        detail.reason='nonfinite coordinate input';return;
    end
    dq=alpha*(qS-qA);
    qalpha=qA+dq;
    detail.extra_peak_MHz=max(abs(dq))/1e6;
    detail.total_peak_MHz=max(abs(qalpha-q0))/1e6;
    detail.min_step_Hz=min(diff(qalpha));
    if detail.extra_peak_MHz>Lextra_MHz
        detail.reason='candidate extra correction > limit';return;
    end
    if detail.total_peak_MHz>Ltotal_MHz
        detail.reason='candidate total correction > limit';return;
    end
    if ~all(isfinite(qalpha)) || ~(detail.min_step_Hz>0)
        detail.reason='nonmonotone candidate coordinate';return;
    end
    detail.reason='feasible';
    ok=true;
end
