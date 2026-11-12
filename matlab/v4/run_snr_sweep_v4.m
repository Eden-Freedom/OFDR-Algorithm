function out = run_snr_sweep_v4(cfg)
%RUN_SNR_SWEEP_V4 可选多次随机噪声实验：辅助 SNR 对波长与空间误差的影响。
% 结果不假设 SSWT 一定优于 STFT/CWT，也不使用未来样本信息。
% 示例：addpath('matlab/v4'); out=run_snr_sweep_v4();
    if nargin<1 || isempty(cfg),cfg=config_v4();end
    cfg.v4.plot_enabled=false;
    cfg.v4.include_stft_cwt=false;
    cfg.v4.show_isolated_reflector=false;
    cfg.plot.enabled=false;
    cfg.sim.add_noise=true;
    ssnr=cfg.v4.snr_values_dB(:);
    reps=cfg.v4.snr_repeats;
    if any(~isfinite(ssnr)) || isempty(ssnr) || ~(reps>=1 && reps==floor(reps))
        error('SNR 与重复次数参数错误。');
    end
    wavelength_rmse=nan(numel(ssnr),reps);
    magnitude_error=nan(numel(ssnr),reps);
    coord_rmse=nan(numel(ssnr),reps);
    for i=1:numel(ssnr)
        for j=1:reps
            cfg.aux.snr_dB=ssnr(i);
            cfg.sim.random_seed=2026+j; % 同一次重复使用配对随机种子，隔离 SNR 影响
            try
                [~,~,~,~,metrics]=main_v4(cfg);
                wavelength_rmse(i,j)=metrics.calibration.sswt.wavelength_rmse_fm;
                magnitude_error(i,j)=metrics.nufft_sswt.magnitude_relative_l2;
                coord_rmse(i,j)=metrics.scan_error_rmse_MHz;
            catch ME
                warning('V4:SNRCaseFailed', ...
                     'SNR=%.1f dB，重复 %d 失败：%s',ssnr(i),j,ME.message);
            end
        end
    end
    out.snr_dB=ssnr;
    out.wavelength_rmse_fm=wavelength_rmse;
    out.magnitude_relative_l2=magnitude_error;
    out.optical_frequency_rmse_MHz=coord_rmse;
    out.repeats=reps;
    figure('Name','Figure 14: V4 | SNR robustness','Color','w');
    subplot(2,1,1);
    plot_with_replicates(ssnr,wavelength_rmse);
    xlabel('Auxiliary MZI SNR (dB)');ylabel('Wavelength RMSE (fm)');
    title('SSWT dynamic wavelength calibration vs noise');
    subplot(2,1,2);
    plot_with_replicates(ssnr,magnitude_error);
    xlabel('Auxiliary MZI SNR (dB)');ylabel('Magnitude-spectrum relative L2');
    title('SSWT + NUFFT reconstruction vs noise');
    fprintf('V4 sweep summary (NaN values indicate failed trajectories):\n');
    for i=1:numel(ssnr)
        a=wavelength_rmse(i,isfinite(wavelength_rmse(i,:)));
        b=magnitude_error(i,isfinite(magnitude_error(i,:)));
        if isempty(a) || isempty(b)
            fprintf('SNR=%4.0f dB: no valid runs\n',ssnr(i));
        else
            fprintf('SNR=%4.0f dB: lambda RMSE %.2f±%.2f fm; magnitude rel.L2 %.4f±%.4f\n', ...
                ssnr(i),mean(a),std(a),mean(b),std(b));
        end
    end
end

function plot_with_replicates(x,all_data)
    means=nan(size(x)); dev=means;
    for i=1:numel(x)
        row=all_data(i,isfinite(all_data(i,:)));
        if ~isempty(row),means(i)=mean(row);dev(i)=std(row);end
    end
    errorbar(x,means,dev,'o-','LineWidth',1.2);grid on;
end
