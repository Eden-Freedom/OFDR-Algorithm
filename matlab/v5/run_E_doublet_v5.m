function E=run_E_doublet_v5(context)
%RUN_E_DOUBLET_V5 双峰间距×振幅比×相位差，真值/SSWT配对、无主噪声。
% 固定双峰判据（谷深至少 cfg.v5.doublet_valley_dB dB）；
% 这里依赖预设真值搜索窗，不能宣传为盲反射点探测成功率。
    cfg=context.cfg;gaps=cfg.v5.doub_gap_mm(:);
    amps=cfg.v5.doub_amp_ratio(:);phases=cfg.v5.doub_phase_rad(:);
    ng=numel(gaps);na=numel(amps);np=numel(phases);
    ok_truth=false(ng,na,np);ok_sswt=false(ng,na,np);
    valley_truth=nan(ng,na,np);valley_sswt=nan(ng,na,np);
    reason_truth=cell(ng,na,np);reason_sswt=cell(ng,na,np);
    base=cfg.v5.single_z_m;
    for i=1:ng
        z1=base;z2=base+gaps(i)*1e-3;
        step=cfg.v5.fine_step_m;
        z=(z1-4e-3:step:z2+4e-3).';
        for j=1:na
            for k=1:np
                s=v5_single_signal(context,[z1;z2],[1;amps(j)],[0;phases(k)]);
                try
                    a=v5_spectrum(context,context.q_true_Hz,s,'fixed',z,false);
                    b=v5_spectrum(context,context.q_sswt_Hz,s,'full',z,false);
                    d1=v5_detect_doublet(z,a.fine,z1,z2,cfg.v5.doublet_valley_dB);
                    d2=v5_detect_doublet(z,b.fine,z1,z2,cfg.v5.doublet_valley_dB);
                    ok_truth(i,j,k)=d1.success;ok_sswt(i,j,k)=d2.success;
                    valley_truth(i,j,k)=d1.valley_dB;
                    valley_sswt(i,j,k)=d2.valley_dB;
                    reason_truth{i,j,k}=d1.reason;reason_sswt{i,j,k}=d2.reason;
                catch ME
                    reason_truth{i,j,k}=ME.message;reason_sswt{i,j,k}=ME.message;
                end
            end
        end
        fprintf('[E] gap %.1fmm: truth %d/%d, SSWT %d/%d\n',gaps(i), ...
            nnz(ok_truth(i,:,:)),na*np,nnz(ok_sswt(i,:,:)),na*np);
    end
    E.experiment='E: predetermined doublet valley test';
    E.gaps_mm=gaps;E.amplitude_ratio=amps;E.relative_phase_rad=phases;
    E.valley_threshold_dB=cfg.v5.doublet_valley_dB;
    E.truth_success=ok_truth;E.sswt_success=ok_sswt;
    E.truth_valley_dB=valley_truth;E.sswt_valley_dB=valley_sswt;
    E.truth_reason=reason_truth;E.sswt_reason=reason_sswt;
    E.truth_success_rate=reshape(mean(reshape(ok_truth,ng,[]),2),[],1);
    E.sswt_success_rate=reshape(mean(reshape(ok_sswt,ng,[]),2),[],1);
    if cfg.v5.save_results
        if ~exist(cfg.v5.output_dir,'dir'),mkdir(cfg.v5.output_dir);end
        save(fullfile(cfg.v5.output_dir,'E_doublet_results.mat'),'E','-v7.3');
    end

end
