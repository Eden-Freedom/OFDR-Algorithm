function B=run_B_error_families_v5(context)
%RUN_B_ERROR_FAMILIES_V5 实验 B/C：等原始RMS的不同误差类型，不同权重分支。
% 为避免不可辨的错误重建，非单调/超界样本保留为失败记录。
    cfg=context.cfg;types=cfg.v5.error_types;
    rmsMHz=cfg.v5.error_rmse_MHz(:);
    z0=cfg.v5.single_z_m;
    z=v5_fine_grid(cfg,z0,cfg.v5.fine_step_m);
    s=v5_single_signal(context,z0,1,cfg.v5.phase_rad);
    q=context.q_true_Hz;
    ref=v5_spectrum(context,q,s,'fixed',z,true);
    nt=numel(types);nr=numel(rmsMHz);normalizations={'raw','residual'};nn=2;
    B.experiment='B/C equal-RMS error family and weight ablation';
    B.types=types;B.target_rms_MHz=rmsMHz;B.normalizations=normalizations;B.reference=ref;
    B.valid=false(nt,nr,nn);B.reason=cell(nt,nr,nn);
    B.diag=cell(nt,nr,nn);B.fixed=cell(nt,nr,nn);B.full=cell(nt,nr,nn);
    B.injected_error_Hz=cell(nt,nr,nn);
    for i=1:nt
        for j=1:nr
            for h=1:nn
                try
                    e=v5_inject_error(context,types{i},rmsMHz(j), ...
                        cfg.v5.random_seed,normalizations{h});
                    B.injected_error_Hz{i,j,h}=e;
                    decomp=v5_error_decomposition(context,e);
                    B.diag{i,j,h}=decomp;
                    sf=v5_spectrum(context,q+e,s,'fixed',z,true);
                    su=v5_spectrum(context,q+e,s,'full',z,true);
                    mf=v5_compare_spectrum(ref,sf,z0,cfg);
                    mu=v5_compare_spectrum(ref,su,z0,cfg);
                    if ~(mf.valid&&mu.valid),error('%s | %s',mf.reason,mu.reason);end
                    B.fixed{i,j,h}=mf;
                    B.full{i,j,h}=mu;
                    B.valid(i,j,h)=true;B.reason{i,j,h}='';
                catch ME
                    B.reason{i,j,h}=ME.message;
                end
            end
        end
    end
    B.valid_count=nnz(B.valid);B.failed_count=numel(B.valid)-B.valid_count;
    % 常数偏置在锚定前加到 q 上，必须在浮点容许误差内完全抵消。
    B.anchor_offset_Hz=5e6;
    [ut,~]=prepare_frequency_coordinates_v4(q,cfg,'true');
    [uc,~]=prepare_frequency_coordinates_v4(q+B.anchor_offset_Hz,cfg,'constant offset');
    B.absolute_offset_invariance_max=max(abs(ut-uc));
    if cfg.v5.save_results
        if ~exist(cfg.v5.output_dir,'dir'),mkdir(cfg.v5.output_dir);end
        save(fullfile(cfg.v5.output_dir,'B_C_error_families.mat'),'B','-v7.3');
    end
    fprintf('[B/C] valid=%d/%d, const-offset anchor error max=%.3e\n', ...
        B.valid_count,numel(B.valid),B.absolute_offset_invariance_max);
end
