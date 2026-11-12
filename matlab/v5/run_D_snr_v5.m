function D=run_D_snr_v5(cfg)
%RUN_D_SNR_V5 辅助 MZI 信噪比扫描，主信号固定无噪声，配对种子。
% 默认7档×30次；关键条件可把 cfg.v5.snr_repeats 改为100。
% 所有失败保留在结果表，无法定义指标时填写NaN，不丢失分母。
    if nargin<1,cfg=config_v5();end
    outdir=fullfile(cfg.v5.output_dir,'D_snr_trials');
    if cfg.v5.save_results && ~exist(outdir,'dir'),mkdir(outdir);end
    baseline_cfg=cfg;baseline_cfg.sim.add_noise=false;
    baseline=v5_setup(baseline_cfg,false);
    s=v5_single_signal(baseline,cfg.v5.single_z_m,1,cfg.v5.phase_rad);
    z=v5_fine_grid(cfg,cfg.v5.single_z_m,cfg.v5.fine_step_m);
    reference=v5_spectrum(baseline,baseline.q_true_Hz,s,'fixed',z,true);
    snrs=cfg.v5.snr_dB(:); R=cfg.v5.snr_repeats;
    [ns,~]=size(snrs);
    values=nan(ns,R,7); valid=false(ns,R); reasons=cell(ns,R);
    for i=1:ns
        for j=1:R
            trial=cfg;
            trial.plot.enabled=false;
            trial.aux.snr_dB=snrs(i);
            trial.sim.add_noise=true;
            trial.sim.random_seed=cfg.v5.random_seed+j-1; % 相同j不同SNR配对
            ticTrial=tic;
            try
                % V2 不修改。它仍会生成 noisy main，但这里明确只使用 s（无噪声）。
                evalc('ctx=v5_setup(trial,true);');
                diagnostics=v5_beat_diagnostics(ctx,ctx.f_sswt_Hz);
                candidate=v5_spectrum(ctx,ctx.q_sswt_Hz,s,'full',z,true);
                comparison=v5_compare_spectrum(reference,candidate,cfg.v5.single_z_m,cfg);
                if ~comparison.valid,error(comparison.reason);end
                valid(i,j)=true;
                values(i,j,1)=diagnostics.beat_rmse_central90_Hz;
                values(i,j,2)=diagnostics.beat_bias_Hz;
                values(i,j,3)=diagnostics.q_decomposition.raw_rmse_Hz/1e6;
                values(i,j,4)=diagnostics.q_decomposition.scale_ppm;
                values(i,j,5)=diagnostics.q_decomposition.residual_rms_Hz/1e6;
                values(i,j,6)=comparison.full_magnitude_relative_l2;
                values(i,j,7)=comparison.full_complex_relative_l2;
                reasons{i,j}='';
                if cfg.v5.save_results
                    record=struct('cfg',trial,'matlab_version',version(), ...
                        'seed',trial.sim.random_seed,'experiment','D-snr', ...
                        't_s',ctx.truth.t_s,'q_true_Hz',ctx.q_true_Hz, ...
                        'q_hat_Hz',ctx.q_sswt_Hz,'aux_signal',ctx.signals.aux, ...
                        'main_clean',s,'beat_error_Hz',diagnostics.error_Hz, ...
                        'cumulative_integral_Hz',diagnostics.cumulative_integral_Hz, ...
                        'diag',diagnostics,'metrics',comparison,'status','ok', ...
                        'runtime_s',toc(ticTrial));
                    save(fullfile(outdir,sprintf('snr_%02d_rep_%03d.mat',snrs(i),j)),'record','-v7.3');
                end
            catch ME
                reasons{i,j}=ME.message;
                if cfg.v5.save_results
                    record=struct('cfg',trial,'seed',trial.sim.random_seed, ...
                        'status','failed','reason',ME.message,'runtime_s',toc(ticTrial));
                    save(fullfile(outdir,sprintf('snr_%02d_rep_%03d.mat',snrs(i),j)),'record');
                end
            end
        end
        fprintf('[D-SNR] %g dB: success %d/%d\n',snrs(i),nnz(valid(i,:)),R);
    end
    D.experiment='D: auxiliary-only SNR paired Monte Carlo';
    D.snr_dB=snrs;D.repeat_count=R;D.valid=valid;
    D.metrics_cube=values;D.failure_reason=reasons;
    D.metric_names={'beat_central90_Hz','beat_mean_Hz','q_rmse_MHz', ...
          'scale_ppm','residual_rmse_MHz','mag_relative_l2','complex_relative_l2'};
    D.successes=sum(valid,2);D.failures=R-D.successes;D.failure_rate=D.failures/R;
    D.mean=nan(ns,7);D.std=nan(ns,7);
    for i=1:ns
        for k=1:7
            v=values(i,valid(i,:),k);v=v(:);
            if ~isempty(v),D.mean(i,k)=mean(v);D.std(i,k)=std(v);end
        end
    end
    if cfg.v5.save_results
        save(fullfile(cfg.v5.output_dir,'D_snr_summary.mat'),'D','-v7.3');
    end
end
