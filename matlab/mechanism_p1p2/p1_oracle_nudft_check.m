function a=p1_oracle_nudft_check(cfg,truth,pair)
%P1_ORACLE_NUDFT_CHECK 用相同光频窗+密度权重直接复核NUFFT复谱。
% 不改变物理前向模型，比较同一个q_true下reference/measurement的复数。
% 输出误差是数值重构误差，不是物理Oracle的应变误差。
    q=truth.nu_offset_Hz(:);
    R=v6_reconstruct_trace(cfg,truth,pair.reference_signal,q);
    M=v6_reconstruct_trace(cfg,truth,pair.measurement_signal,q);
    allk=(0:numel(R.spectrum)-1).';
    loc=R.z_m>=cfg.v6.roi_m(1) & R.z_m<=cfg.v6.roi_m(2);
    kk=allk(loc);
    count=min(cfg.p1p2.p1_sample_bins,numel(kk));
    if count<8,error('P1:NUDFTBins','ROI内直接NUDFT采样点不足');end
    idx=unique(round(linspace(1,numel(kk),count)));
    ks=kk(idx);
    traces={R,M};
    signals={pair.reference_signal,pair.measurement_signal};
    a.labels={'reference','measurement'};
    a.k=ks;
    a.z_m=R.z_m(ks+1);
    a.rel_l2=zeros(1,2);
    a.max_abs=zeros(1,2);
    a.phase_rmse_rad=zeros(1,2);
    a.phase_count=zeros(1,2);
    a.tested_bins=numel(ks);
    for h=1:2
        tr=traces{h};
        x=signals{h}(:).*tr.window(:);
        direct=nudft_reference_v3(tr.u,x,tr.density,ks,32);
        approx=tr.spectrum(ks+1);
        a.rel_l2(h)=norm(approx-direct)/max(norm(direct),eps);
        a.max_abs(h)=max(abs(approx-direct));
        good=abs(direct)>.1*median(abs(direct));
        a.phase_count(h)=nnz(good);
        if any(good)
            delta=angle(approx(good).*conj(direct(good)));
            a.phase_rmse_rad(h)=sqrt(mean(delta.^2));
        else
            a.phase_rmse_rad(h)=NaN;
        end
    end
    a.note='Complex NUFFT vs direct NUDFT with identical u, window and density; not physics accuracy.';
end