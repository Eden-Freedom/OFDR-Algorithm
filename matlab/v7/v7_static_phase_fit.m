function out=v7_static_phase_fit(cfg,truth,reference_trace,measurement_signal,q_meas_init_Hz,basis_mode)
%V7_STATIC_PHASE_FIT 仅用已知静态上游段的gauge相位拟合低维测量坐标校正。
% 不传入 truth.nu_offset_Hz、散射体真值、应变值或受应变区域的相位。
% 这里 truth 只用于 fs/N/物理距离网格和NUFFT所需标称带宽（同早期版本）。
% 估计是非线性的阻尼Gauss-Newton，正则项限制无支撑/大幅校正。
    if nargin<6,basis_mode='full';end
    q=q_meas_init_Hz(:);n=numel(q);
    if any(diff(q)<=0),error('V7:Nonmonotone','原始测量坐标不单调');end
    x=(q-q(1))/(q(end)-q(1));
    full_basis=[x, x.*(1-x),sin(2*pi*x),sin(4*pi*x)];
    if strcmp(basis_mode,'affine'),B=full_basis(:,1);else,B=full_basis;end
    K=size(B,2);beta=zeros(K,1);
    base=v6_reconstruct_trace(cfg,truth,measurement_signal,q);
    z=reference_trace.z_m(:);dz=z(2)-z(1);
    lag=round(cfg.v6.gauge_length_m/dz);I=(1:numel(z)-lag).';J=I+lag;
    train= z(I)>=cfg.v7.train_static_m(1) & z(J)<=cfg.v7.train_static_m(2);
    ref=reference_trace.spectrum(:);m0=base.spectrum(:);
    refsite=z>=cfg.v7.train_static_m(1) & z<=cfg.v7.train_static_m(2);
    amp=median(abs(ref(refsite)));
    threshold=cfg.v6.amplitude_gate_fraction*amp;
    good=(abs(ref)>threshold)&(abs(m0)>threshold);
    train=train&good(I)&good(J);
    selected=find(train);selected=selected(1:cfg.v7.training_stride:end);
    if numel(selected)<cfg.v7.min_train_gauges
        error('V7:TrainingMask','训练区有效gauge仅%d个',numel(selected));
    end
    out.beta_MHz=beta;out.objective_history=[];
    out.train_count=numel(selected);out.train_range_m=cfg.v7.train_static_m;
    out.basis_mode=basis_mode;out.initial_q_Hz=q;
    out.max_correction_MHz=cfg.v7.max_correction_MHz;
    Rr=ref;reg=cfg.v7.regularization;
    [p,~,ok]=response(beta);
    if ~ok,error('V7:Initial','初始坐标重构失败');end
    out.rms_before_rad=sqrt(mean(p.^2));
    for it=1:cfg.v7.max_iterations
        Jmat=zeros(numel(selected),K);delta=cfg.v7.finite_diff_MHz;
        for j=1:K
            probe=beta;probe(j)=probe(j)+delta;
            [qphase,~,valid]=response(probe);
            if ~valid,error('V7:Jacobian','有限差分坐标无效');end
            Jmat(:,j)=angle(exp(1i*(qphase-p)))/delta;
        end
        % V7b 诊断：先记录未正则化的数据可辨识性。
        % 原 rcond(H) 含正则项，不能单独反映观测本身的秩信息。
        Hdata=(Jmat.'*Jmat)/numel(p);
        out.rcond_data_hessian=rcond(Hdata);
        out.jacobian_rank=rank(Jmat);
        H=Hdata+reg*eye(K);
        grad=(Jmat.'*p)/numel(p)+reg*beta;
        out.rcond_hessian=rcond(H);
        if out.rcond_hessian<cfg.v7.min_condition_rcond
            error('V7:Rank','静止段信息不足，参数不可辨识');
        end
        step=-H\grad;
        obj=sum(p.^2)/numel(p)+reg*sum(beta.^2);
        out.objective_history(end+1,1)=obj;
        accepted=false;
        for sf=[1 0.5 0.25 0.125]
            cand=beta+sf*step;
            [pc,~,valid]=response(cand);
            if ~valid,continue;end
            objc=sum(pc.^2)/numel(pc)+reg*sum(cand.^2);
            if objc<=obj-1e-13
                beta=cand;p=pc;accepted=true;break;
            end
        end
        if ~accepted,break;end
    end
    [p,trace,ok]=response(beta);
    if ~ok,error('V7:Optimization','拟合后坐标无效');end
    out.beta_MHz=beta;
    out.delta_q_Hz=1e6*B*beta;
    out.q_corrected_Hz=q+out.delta_q_Hz;
    out.measurement_trace=trace;
    out.rms_after_rad=sqrt(mean(p.^2));
    out.training_phase_rad=p;
    out.training_indices=selected;
    out.basis_matrix=B;
    out.method='Static-Anchor Phase-Consistency (SAPC) prototype';
    out.uses_truth_for_fit=false;
    out.uses_strained_region_for_fit=false;

    function [phase,R,valid]=response(coeff)
        dq=1e6*B*coeff;
        qc=q+dq;
        valid=all(isfinite(qc))&&all(diff(qc)>0)&& ...
            max(abs(dq))<=cfg.v7.max_correction_MHz*1e6;
        R=[];phase=[];
        if ~valid,return;end
        try
            R=v6_reconstruct_trace(cfg,truth,measurement_signal,qc);
            rm=R.spectrum(:);
            C=rm.*conj(Rr);
            gauge_phasor=C(J).*conj(C(I));
            % 与V6c评分采用一致的显式复相位邻域平均，静态参考段离应变边缘足够远。
            w=cfg.v6c.phase_avg_bins;
            if w>1,gauge_phasor=conv(gauge_phasor,ones(w,1)/w,'same');end
            phase=angle(gauge_phasor(selected));
            valid=all(isfinite(phase));
        catch
            valid=false;
        end
    end
end
