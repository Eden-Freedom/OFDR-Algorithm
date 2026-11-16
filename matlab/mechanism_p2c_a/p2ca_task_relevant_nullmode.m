function r=p2ca_task_relevant_nullmode(cfg)
%P2CA_TASK_RELEVANT_NULLMODE 理想双扫描、单反射点：辅助盲模式是否影响主相位？
%
% 核心问题：A_aux*dnu=0 并不必然意味着所有OFDR输出都不受影响。
% 若测量扫描与参考扫描的真实光频坐标之差是辅助零空间方向，
% 单通道辅助相位无法发现这个差异，但主路径延迟算子可能敏感。
%
% 重要：
%   1) 这里只模拟理想相位积分，无真实Rayleigh、无空间NUFFT、无应变，
%      所以「主通道相位差」不能直接称为「应变误差」或Core RMSE。
%   2) 相位来自完整积分 phi=2*pi*integral nu dt，不使用2*pi*tau*nu(t)
%      的局部近似；对两条扫描使用同一个固定点反射光程延迟。
%   3) 真实光频在此是人为构造的反例，不是可部署估计器输入。
%   4) 同一差异叠加到参考和测量两次扫描时，双扫描相位差严格抵消。
    if nargin<1||isempty(cfg),cfg=config_p2c_a();end
    p2ca_assert_protocol(cfg);
    dt=cfg.p2ca.dt_s;
    N=cfg.p2ca.n_frequency_bins;
    mAux=cfg.p2ca.delay_1_bins;  % 4 bins
    mAux2=cfg.p2ca.delay_2_bins; % 5 bins
    mMain=2;                     % 单反射点主往返时延, 2 bins
    amp_cycles=.01;              % 人为测试误差方向幅度，非真实硬件参数
    k=(0:N-1).';
    xRef=.25+.05*k+.008*sin(k/8); % x=nu*dt，无量纲
    blind=amp_cycles*sin(2*pi*k/mAux);
    xMeas=xRef+blind;
    if any(diff(xRef)<=0)||any(diff(xMeas)<=0)
        error('P2CA:ImpactMonotone','两个示范扫描必须都严格单调。');
    end
    [Aaux,taux]=p2ca_integral_matrix(N,dt,mAux*dt);
    [Aaux2,taux2]=p2ca_integral_matrix(N,dt,mAux2*dt);
    [Amain,tmain]=p2ca_integral_matrix(N,dt,mMain*dt);
    % 用共同的辅助4-bin观测时刻评价主通道（都在完全窗口内部）。
    [found,idx]=ismember(round(taux/dt),round(tmain/dt));
    if ~all(found)
        error('P2CA:ImpactClock','主通道与辅助通道时间索引无法对齐。');
    end

    auxPhaseRef=2*pi*Aaux*xRef;
    auxPhaseMeas=2*pi*Aaux*xMeas;
    secondAuxDiff=2*pi*Aaux2*(xMeas-xRef);
    mainPhaseRef=2*pi*Amain*xRef;
    mainPhaseMeas=2*pi*Amain*xMeas;

    % phase wrapped仅用于示范复数主干涉观测的实际差异，
    % 本设定注入幅度很小，远未引起wrap跳变。
    auxDiff=angle(exp(1i*(auxPhaseMeas-auxPhaseRef)));
    mainDiff=angle(exp(1i*(mainPhaseMeas(idx)-mainPhaseRef(idx))));

    % 反例：如果主通道延迟也恰好为4格，blind属于它的kernel，
    % 则主通道同样不可观测；因此「辅助零空间」不是「必有应变误差」。
    sameDelayMainDiff=angle(exp(1i*(2*pi*Aaux*(xMeas-xRef))));

    % 共模测试：相同的blind注入到两次扫描，主路径phase差为0。
    commonRef=2*pi*Amain*(xRef+blind);
    commonMeas=2*pi*Amain*(xRef+blind);
    commonDiff=angle(exp(1i*(commonMeas(idx)-commonRef(idx))));

    % 对两扫描同时施加相同光频常偏置，差分主相位不变。
    dc=.03; % 无量纲周期/格
    shiftedRef=2*pi*Amain*(xRef+dc);
    shiftedMeas=2*pi*Amain*(xMeas+dc);
    shiftedDiff=angle(exp(1i*(shiftedMeas(idx)-shiftedRef(idx))));
    dcInvariant=max(abs(angle(exp(1i*(shiftedDiff-mainDiff)))));

    r=struct();
    r.dataset='math_only';
    r.protocol='P2CA_TASK_RELEVANT_NULLMODE_2026_11_15';
    r.dt_s=dt;r.N=N;
    r.aux_delay_bins=mAux;
    r.second_aux_delay_bins=mAux2;
    r.main_reflector_delay_bins=mMain;
    r.blind_amplitude_cycles_per_cell=amp_cycles;
    r.blind_amplitude_Hz=amp_cycles/dt;
    r.aux_blind_max_rad=max(abs(auxDiff));
    r.second_aux_max_rad=max(abs(secondAuxDiff));
    r.main_reflector_max_rad=max(abs(mainDiff));
    r.main_reflector_rms_rad=sqrt(mean(mainDiff.^2));
    r.main_same_as_aux_delay_max_rad=max(abs(sameDelayMainDiff));
    r.main_common_scan_max_rad=max(abs(commonDiff));
    r.main_shared_dc_invariance_max_rad=dcInvariant;
    r.k=k;r.x_reference=xRef;r.x_measurement=xMeas;
    r.x_diff=xMeas-xRef;
    r.aux_t_over_dt=taux/dt;r.aux_phase_difference_rad=auxDiff;
    r.second_aux_t_over_dt=taux2/dt;
    r.second_aux_phase_difference_rad=secondAuxDiff;
    r.main_phase_difference_rad=mainDiff;
    r.main_same_delay_phase_difference_rad=sameDelayMainDiff;
    r.main_common_mode_difference_rad=commonDiff;

    assert(r.aux_blind_max_rad<1e-10 && ...
        r.main_reflector_max_rad>1e-3 && ...
        r.second_aux_max_rad>1e-3 && ...
        r.main_same_as_aux_delay_max_rad<1e-10 && ...
        r.main_common_scan_max_rad<1e-10 && ...
        r.main_shared_dc_invariance_max_rad<1e-10, ...
        'P2CA:ImpactIdentity','零空间任务相关性恒等式未成立。');

    fprintf('\n====== P2c-A2 | AUX NULL MODE -> MAIN PHASE | MATH ONLY ======\n');
    fprintf('N=%d; dt=%g s; aux delay=%d bins; main single-point delay=%d bins\n', ...
        N,dt,mAux,mMain);
    fprintf('Same two sweeps: aux1 max Δphi=%.5g rad, aux2 max Δphi=%.5g rad\n', ...
        r.aux_blind_max_rad,r.second_aux_max_rad);
    fprintf('Main differential phase max=%.7g rad, RMS=%.7g rad\n', ...
        r.main_reflector_max_rad,r.main_reflector_rms_rad);
    fprintf('Main delay identical to aux delay -> max Δphi=%.5g rad\n', ...
        r.main_same_as_aux_delay_max_rad);
    fprintf('Same blind mode in both scans -> max Δphi=%.5g rad\n', ...
        r.main_common_scan_max_rad);
    fprintf('Shared constant frequency offset -> change in differential main phase max=%.5g rad\n', ...
        r.main_shared_dc_invariance_max_rad);
    fprintf('No strain/Rayleigh/NUFFT was computed. These are phase responses, NOT microstrain errors.\n');
end