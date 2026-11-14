function p2_export_trials(folder,r)
%P2_EXPORT_TRIALS 将全部预设trial包含失败记录导出；每个应变组一行。
    if ~exist(folder,'dir'),mkdir(folder);end
    n=r.n_trials;K=numel(r.strain_microeps);
    trial=repelem((1:n).',K,1);
    strain=repmat(r.strain_microeps(:),n,1);
    success=repelem(r.success,K,1);
    seed=repelem(r.seed_scatter,K,1);
    seedref=repelem(r.seed_ref,K,1);
    seedmeas=repelem(r.seed_meas,K,1);
    ec=repelem(r.ec_rms_MHz,K,1);
    ed=repelem(r.ed_rms_MHz,K,1);
    coverage=repelem(r.common_roi_fraction,K,1);
    coreCount=repelem(r.common_core_count,K,1);
    M=nan(n*K,4);
    R=nan(n*K,4);
    C=nan(n*K,1);D=C;I=C;Iraw=C;
    for t=1:n
        ix=(t-1)*K+(1:K);
        M(ix,:)=reshape(r.M_core(t,:,:),K,4);
        R(ix,:)=reshape(r.rmse_core(t,:,:),K,4);
        C(ix)=reshape(r.C_core(t,:),K,1);
        D(ix)=reshape(r.D_core(t,:),K,1);
        I(ix)=reshape(r.I_core(t,:),K,1);
        Iraw(ix)=reshape(r.I_raw_core(t,:),K,1);
    end
    fid=r.failure_id;reason=r.failure_reason;
    for t=1:n
        if isempty(fid{t}),fid{t}='';end
        if isempty(reason{t}),reason{t}='';end
    end
    failID=repelem(fid,K,1);
    failReason=repelem(reason,K,1);
    T=table(trial,strain,success,seed,seedref,seedmeas,ec,ed,coverage, ...
        coreCount,M(:,1),M(:,2),M(:,3),M(:,4), ...
        R(:,1),R(:,2),R(:,3),R(:,4),C,D,I,Iraw,failID,failReason, ...
        'VariableNames',{'trial','strain_ue','success','seed_scatter', ...
        'seed_ref','seed_meas','ec_rms_MHz','ed_rms_MHz', ...
        'common_roi_fraction','common_core_count', ...
        'M00','M10','M01','M11','RMSE00','RMSE10','RMSE01','RMSE11', ...
        'C_core_ue2','D_core_ue2','I_core_ue2','I_raw_core_ue2', ...
        'failure_id','failure_reason'});
    writetable(T,fullfile(folder,'P2_DEV_trials.csv'));
end