function B=run_B_residual_scale_v5(context)
%RUN_B_RESIDUAL_SCALE_V5 P1：当前 SSWT 的实际误差 e(t) 乘倍率 gamma。
% 每组同时保存“固定真值权重”与“按估计坐标重算权重”两个对照。
    cfg=context.cfg;
    z0=cfg.v5.single_z_m;gammas=cfg.v5.sswt_gamma(:);
    z=v5_fine_grid(cfg,z0,cfg.v5.fine_step_m);
    s=v5_single_signal(context,z0,1,cfg.v5.phase_rad);
    q=context.q_true_Hz;
    err=context.q_sswt_Hz-q;
    ref=v5_spectrum(context,q,s,'fixed',z,true);
    N=numel(gammas);
    B.experiment='B-residual: gamma x SSWT residual';
    B.gamma=gammas;B.z_m=z;B.signal_clean=s;
    B.true_q_Hz=q;B.sswt_error_Hz=err;
    B.reference=ref;
    B.valid=false(N,1);B.failure_reason=cell(N,1);
    B.coordinate_decomposition=cell(N,1);
    B.fixed=cell(N,1);B.full=cell(N,1);
    B.metrics_fixed=cell(N,1);B.metrics_full=cell(N,1);
    B.estimated_q_Hz=cell(N,1);
    B.weighted_theory_ratio=nan(N,1); % complex 值通过逐项扩展自动保持复数
    B.actual_fixed_ratio=nan(N,1);
    B.estimated_rmse_MHz=nan(N,1);
    for i=1:N
        estimated=q+gammas(i)*err;
        B.estimated_q_Hz{i}=estimated;
        decomposition=v5_error_decomposition(context,estimated-q);
        B.coordinate_decomposition{i}=decomposition;
        B.estimated_rmse_MHz=replace_at(B.estimated_rmse_MHz,i,decomposition.raw_rmse_Hz/1e6);
        try
            sf=v5_spectrum(context,estimated,s,'fixed',z,true);
            su=v5_spectrum(context,estimated,s,'full',z,true);
            mf=v5_compare_spectrum(ref,sf,z0,cfg);
            mu=v5_compare_spectrum(ref,su,z0,cfg);
            if ~(mf.valid && mu.valid),error('峰宽无效: %s, %s',mf.reason,mu.reason);end
            B.fixed{i}=sf;B.full{i}=su;
            B.metrics_fixed{i}=mf;B.metrics_full{i}=mu;
            [~,k]=min(abs(z-z0));
            B.actual_fixed_ratio(i)=sf.fine(k)/ref.fine(k);
            w=context.weights_true(:).*context.window_true(:);
            phase=4*pi*cfg.fut.group_index*z0/cfg.const.c_m_s;
            B.weighted_theory_ratio(i)=sum(w.*exp(-1i*phase*(estimated-q)))/sum(w);
            B.valid(i)=true;B.failure_reason{i}='';
        catch ME
            B.failure_reason{i}=ME.message;
        end
    end
    B.valid_count=nnz(B.valid);B.failed_count=N-B.valid_count;
    fprintf('[B-residual] valid gamma %d/%d; gamma=1 amplitude/phase recorded in fixed + full modes\n',B.valid_count,N);
end
function a=replace_at(a,i,val)
    a(i)=val;
end
