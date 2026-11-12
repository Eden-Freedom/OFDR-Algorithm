function A=run_A_fine_reference_v5(context)
%RUN_A_FINE_REFERENCE_V5 实验 A（P0）：粗、0.02mm、0.01mm 网格比较。
% 真实信号固定无噪声；比较真值轨迹与 SSWT 轨迹、NUFFT 与直接NUDFT。
    cfg=context.cfg;
    z0=cfg.v5.single_z_m;
    s=v5_single_signal(context,z0,1,cfg.v5.phase_rad);
    q=context.q_true_Hz;
    k=context.k;
    A.experiment='A: fine-grid peak-width calibration';
    A.z_true_m=z0; A.signal_clean=s;
    A.q_true_Hz=q;A.q_sswt_Hz=context.q_sswt_Hz;
    A.window_true=context.window_true;A.weights_true=context.weights_true;
    A.steps_m=[context.dz_m cfg.v5.fine_step_m cfg.v5.convergence_step_m];
    % 原始粗网格仅用于复现 V4 指标；所有关键比较使用同一局部细网格。
    coarse=v5_spectrum(context,q,s,'fixed',[],true);
    direct=v5_direct_z(q,s,context.z_coarse_m,context.weights_true,context.window_true,cfg);
    A.nufft_vs_nudft_full_relative_l2=norm(coarse.coarse-direct)/max(norm(direct),realmin);
    A.kernel_widths=[8 12];
    A.kernel_rel_errors=nan(1,2);
    for j=1:2
        opt=cfg.v3;opt.kernel_width=A.kernel_widths(j);
        check=nufft_gaussian_type1_v3(context.u_true, ...
             s.*context.window_true,context.weights_true,k,opt);
        A.kernel_rel_errors(j)=norm(check.spectrum-direct)/max(norm(direct),realmin);
    end
    A.coarse_spectrum=coarse.coarse;A.coarse_direct=direct;
    A.coarse_metrics=v5_peak_metrics(context.z_coarse_m,coarse.coarse,z0,cfg);
    for i=2:3
        z=v5_fine_grid(cfg,z0,A.steps_m(i));
        truthSpec=v5_spectrum(context,q,s,'fixed',z,false);
        sswtSpec=v5_spectrum(context,context.q_sswt_Hz,s,'full',z,false);
        tag=sprintf('step%d',i);
        A.(tag).z_m=z;
        A.(tag).truth=truthSpec.fine;
        A.(tag).sswt=sswtSpec.fine;
        A.(tag).truth_metrics=v5_peak_metrics(z,truthSpec.fine,z0,cfg);
        A.(tag).sswt_metrics=v5_peak_metrics(z,sswtSpec.fine,z0,cfg);
        A.(tag).comparison=v5_compare_spectrum(truthSpec,sswtSpec,z0,cfg);
    end
    A.fwhm_convergence_m=abs(A.step2.truth_metrics.fwhm_m-A.step3.truth_metrics.fwhm_m);
    A.sswt_fwhm_convergence_m=abs(A.step2.sswt_metrics.fwhm_m-A.step3.sswt_metrics.fwhm_m);
    A.reference_fwhm_m=A.step3.truth_metrics.fwhm_m;
    A.sswt_fwhm_m=A.step3.sswt_metrics.fwhm_m;
    A.relative_growth=(A.sswt_fwhm_m-A.reference_fwhm_m)/A.reference_fwhm_m;
    fprintf('\n[A] coarse FWHM %.4f mm | true fine 0.02/0.01 mm = %.4f / %.4f mm\n', ...
        A.coarse_metrics.fwhm_m*1e3,A.step2.truth_metrics.fwhm_m*1e3,A.reference_fwhm_m*1e3);
    fprintf('[A] SSWT fine FWHM %.4f mm | convergence %.4f micrometers | NUFFT-vs-NUDFT full rel.L2 %.3e\n', ...
        A.sswt_fwhm_m*1e3,A.fwhm_convergence_m*1e6,A.nufft_vs_nudft_full_relative_l2);
end
