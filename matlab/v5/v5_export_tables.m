function v5_export_tables(results,cfg)
%V5_EXPORT_TABLES 将主实验结构体导出为可审查的 CSV，同时保留原始 .mat。
    if ~cfg.v5.save_results,return;end
    folder=cfg.v5.output_dir;
    if ~exist(folder,'dir'),mkdir(folder);end
    B=results.B_scale;
    [Z,E]=ndgrid(B.distances_m,B.scale_ppm);
    T=table(Z(:),E(:),B.valid(:),B.predicted_offset_m(:)*1e3, ...
      B.absolute_error_m(:)*1e3,B.incremental_error_m(:)*1e3, ...
      B.fwhm_m(:)*1e3,B.peak_loss_dB(:),B.failure_reason(:), ...
      'VariableNames',{'z_m','scale_ppm','valid','theory_shift_mm', ...
      'absolute_error_mm','incremental_shift_mm','fwhm_mm','peak_loss_dB','failure_reason'});
    writetable(T,fullfile(folder,'B_scale_summary.csv'));
    R=results.B_residual;
    N=numel(R.gamma);
    mag=nan(N,1);complexL2=mag;fwhmGrowth=mag;peakMove=mag;phase=mag;
    for i=1:N
        if R.valid(i)
            item=R.metrics_full{i};
            mag(i)=item.full_magnitude_relative_l2;
            complexL2(i)=item.full_complex_relative_l2;
            fwhmGrowth(i)=item.fwhm_growth;
            peakMove(i)=item.delta_location_m*1e3;
            phase(i)=item.fixed_location_phase_delta_rad;
        end
    end
    T=table(R.gamma(:),R.valid(:),R.estimated_rmse_MHz(:), ...
        mag,complexL2,fwhmGrowth,peakMove,phase,R.failure_reason(:), ...
      'VariableNames',{'gamma','valid','coordinate_rmse_MHz', ...
      'magnitude_l2','complex_l2','relative_fwhm_growth', ...
      'incremental_position_mm','fixed_position_phase_rad','failure_reason'});
    writetable(T,fullfile(folder,'B_sswt_gamma_summary.csv'));
    if isfield(results,'D_snr')
        D=results.D_snr;
        T=table(D.snr_dB(:),D.successes(:),D.failures(:),D.failure_rate(:), ...
              D.mean(:,3),D.std(:,3),D.mean(:,6), ...
          'VariableNames',{'SNR_dB','successes','failures','failure_rate', ...
          'q_rmse_MHz_success_mean','q_rmse_MHz_success_std','magnitude_l2_success_mean'});
        writetable(T,fullfile(folder,'D_snr_summary.csv'));
    end
end
