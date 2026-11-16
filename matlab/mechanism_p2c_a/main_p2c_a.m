function [cfg,results]=main_p2c_a(cfg)
%MAIN_P2C_A 纯数学辅助MZI相位积分观测：秩、盲模态、时延歧义。
% 理想解缠相位是强于真实PD波形的观测假设。不能直接声称校准算法。
% 无随机种子、无Rayleigh信号、无主OFDR重构、无冻结数据。
    if nargin<1||isempty(cfg),cfg=config_p2c_a();end
    p2ca_assert_protocol(cfg);
    N=cfg.p2ca.n_frequency_bins;
    dt=cfg.p2ca.dt_s;
    m1=cfg.p2ca.delay_1_bins;
    m2=cfg.p2ca.delay_2_bins;
    [A1,t1]=p2ca_integral_matrix(N,dt,m1*dt);
    [A2,t2]=p2ca_integral_matrix(N,dt,m2*dt);

    % 单延迟、去相位offset后、双延迟、双延迟未知两相位offset四种情形。
    P1=A1-mean(A1,1); % 将未知常相位offset作为干扰项剔除
    P2=A2-mean(A2,1);
    full=[A1;A2];
    centered=[P1;P2];
    aug=[2*pi*A1,ones(size(A1,1),1),zeros(size(A1,1),1); ...
         2*pi*A2,zeros(size(A2,1),1),ones(size(A2,1),1)];
    r1=p2ca_numerical_rank(A1);
    r1_centered=p2ca_numerical_rank(P1);
    r2=p2ca_numerical_rank(A2);
    r12=p2ca_numerical_rank(full);
    r12_centered=p2ca_numerical_rank(centered);
    r12_unknown_offsets=p2ca_numerical_rank(aug);
    assert(r1.rank==N-m1+1 && r1.nullity==m1-1, ...
       'P2CA:RankSingle','单延迟整数网格秩不符合滚动积分结构。');
    assert(r12.rank==N && r12_centered.rank==N-1, ...
       'P2CA:RankDouble','互素双延迟未表现预期秩/直流模态。');
    assert(r12_unknown_offsets.nullity==1, ...
       'P2CA:RankOffset','双延迟独立offset应具有一个直流规范歧义。');

    % 反例一：单延迟m1=4下周期4、每周期均值零的扫频误差方向。
    % 每个完整τ窗口都积掉此模态；改变光频而辅助相位不变。
    k=(0:N-1).';
    x0=0.25+0.05*k+0.008*sin(k/8); % x=ν*dt，无量纲周期/格
    blind=sin(2*pi*k/m1);
    delta=.01;
    x1=x0+delta*blind;
    if any(diff(x0)<=0) || any(diff(x1)<=0)
        error('P2CA:Monotone','示范扫频轨迹必须保持严格单调。');
    end
    offset=cfg.p2ca.offset_phase_rad;
    phiA=2*pi*A1*x0+offset;
    phiB=2*pi*A1*x1+offset;
    phi2A=2*pi*A2*x0+offset;
    phi2B=2*pi*A2*x1+offset;
    single_blind_err=max(abs(phiB-phiA));
    second_delay_signal=max(abs(phi2B-phi2A));
    assert(single_blind_err<1e-10 && second_delay_signal>1e-4, ...
        'P2CA:BlindExample','单延迟零模态或第二延迟解盲示例不正确。');

    % 反例二：未知相位offset时，常光频偏移与相位零点不能区分。
    d_x=.03;   % 每时间格增加0.03周期，对应d_x/dt Hz
    offset2=offset-2*pi*m1*d_x;
    dc_err=max(abs((2*pi*A1*(x0+d_x)+offset2)-phiA));
    assert(dc_err<1e-10, ...
        'P2CA:OffsetExample','未知相位offset与光频常偏置的等价关系不成立。');

    % 反例三：仅单延迟、未知τ及offset，对线性扫频存在一组尺度歧义。
    % 以下时间/τ单位均为dt；相位由精确移动积分得到，不是近似。
    tau1=m1;
    tau_alt=4.7;
    nu0=.10;  slope=.05;
    nu0_alt=nu0*tau1/tau_alt;
    slope_alt=slope*tau1/tau_alt;
    offset_alt=offset+pi*(slope_alt*tau_alt^2-slope*tau1^2);
    t_idx=(ceil(max(tau1,tau_alt)):N).';
    phase1=2*pi*(nu0*tau1+slope*(tau1*t_idx-.5*tau1^2))+offset;
    phase_alt=2*pi*(nu0_alt*tau_alt+ ...
               slope_alt*(tau_alt*t_idx-.5*tau_alt^2))+offset_alt;
    delay_scale_err=max(abs(phase1-phase_alt));
    assert(delay_scale_err<1e-10, ...
        'P2CA:DelayExample','未标定时延/扫频尺度的线性chirp反例不成立。');

    results=struct();
    results.dataset='math_only';
    results.protocol=cfg.p2ca.name;
    results.n_frequency_bins=N;
    results.sample_dt_s=dt;
    results.delay1_s=m1*dt;
    results.delay2_s=m2*dt;
    results.rank_one_known_offset=r1;
    results.rank_one_unknown_offset=r1_centered;
    results.rank_second_known_offset=r2;
    results.rank_two_known_offsets=r12;
    results.rank_two_unknown_offsets=r12_centered;
    results.rank_augmented_unknown_offsets=r12_unknown_offsets;
    results.first_delay_blind_phase_maxrad=single_blind_err;
    results.second_delay_blind_phase_maxrad=second_delay_signal;
    results.unknown_offset_dc_phase_maxrad=dc_err;
    results.unknown_delay_chirp_phase_maxrad=delay_scale_err;
    results.example=struct('k',k,'x_original',x0,'x_blind_perturbed',x1, ...
        't1_s',t1,'t2_s',t2,'phi_original_1',phiA,'phi_blind_1',phiB, ...
        'phi_original_2',phi2A,'phi_blind_2',phi2B, ...
        'chirp_time_bins',t_idx,'chirp_phi_delay1',phase1, ...
        'chirp_phi_delay_alt',phase_alt, ...
        'tau_alt_s',tau_alt*dt,'nu0_alt_normalized',nu0_alt, ...
        'slope_alt_normalized',slope_alt);
    fprintf('\n========== P2c-A | IDEAL AUX MZI IDENTIFIABILITY | MATH ONLY ==========\n');
    fprintf('Frequency bins N=%d, delay1=%d bins, delay2=%d bins\n',N,m1,m2);
    fprintf('Single delay known offset: rank %d/%d, nullity %d\n', ...
        r1.rank,N,r1.nullity);
    fprintf('Single delay unknown offset (demeaned phase): rank %d/%d, nullity %d\n', ...
        r1_centered.rank,N,r1_centered.nullity);
    fprintf('Two delays known offsets: rank %d/%d, nullity %d\n', ...
        r12.rank,N,r12.nullity);
    fprintf('Two delays unknown individual offsets: phase-centered rank %d/%d, nullity %d\n', ...
        r12_centered.rank,N,r12_centered.nullity);
    fprintf('Augmented [x,phi01,phi02] rank %d/%d, nullity %d\n', ...
        r12_unknown_offsets.rank,r12_unknown_offsets.cols, ...
        r12_unknown_offsets.nullity);
    fprintf('Single delay blind mode phase change max=%.3g rad; second delay change=%.5g rad\n', ...
        single_blind_err,second_delay_signal);
    fprintf('Exact DC offset ambiguity residual max=%.3g rad\n',dc_err);
    fprintf('Unknown delay linear chirp ambiguity residual max=%.3g rad\n',delay_scale_err);
    fprintf('All results: ideal unwrapped phase, deterministic math only. NO strain/noise/seed/frozen evaluation.\n');
    if cfg.p2ca.save_results
        folder=cfg.p2ca.output_dir;
        if ~isfolder(folder),mkdir(folder);end
        save(fullfile(folder,'P2CA_MATH_ONLY_results.mat'),'cfg','results','-v7.3');
    end
    if cfg.p2ca.make_plots
        p2ca_plot_results(results);
    end
end