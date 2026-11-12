function [cfg,truth,signals,results,metrics] = main_v4(cfg)
%MAIN_V4 V4 SSWT + NUFFT 联合 OFDR 仿真（真值/插值/无校准对照）。
% MATLAB 使用方法：
%   addpath('matlab/v4');
%   [cfg,truth,signals,results,metrics] = main_v4();
%
% 流程：V1 生成共同主/辅助信号 → V2 SSWT 得到 nu_hat(t_n)
%      → 用已知 TLS 标称扫描带宽得到归一化 u_hat(t_n)
%      → 同一个 V3 NUFFT 函数重构 OFDR 空间反射谱。
%
% 注意：V4 真值轨迹只用于对照，不用于修正 SSWT 估计的轨迹！
%       NUFFT 的数值误差已在 V3 独立验证，本阶段研究光频校准误差的传递。
    here=fileparts(mfilename('fullpath'));
    addpath(fullfile(fileparts(here),'v1'), ...
            fullfile(fileparts(here),'v2'), ...
            fullfile(fileparts(here),'v3'));
    if nargin<1 || isempty(cfg),cfg=config_v4();end
    if ~isfield(cfg,'v4') || ~isfield(cfg,'v3') || ~isfield(cfg,'sswt')
        error('请先通过 config_v4() 获取完整配置。');
    end
    joint_timer=tic;
    % main_v2 同时生成与 V1 相同的 TLS/主干涉信号，避免二次加噪不一致。
    % 关闭它的画图但保留中间结果和评估指标。
    v2cfg=cfg;
    v2cfg.plot.enabled=false;
    [~,truth,signals,v2result,v2metrics]=main_v2(v2cfg);

    N=truth.N;
    k=(0:floor(N/2)).';
    nominal_span=cfg.const.c_m_s*(1/cfg.laser.lambda_end_m-1/cfg.laser.lambda_start_m);
    dz=cfg.const.c_m_s/(2*cfg.fut.group_index*nominal_span);
    z=k*dz;
    data=signals.main(:);

    % 理想校准光频（只是验证用的 Oracle），与 SSWT 的数据同一时间采样。
    [u_true,meta_true]=prepare_frequency_coordinates_v4( ...
               truth.nu_offset_Hz,cfg,'truth');
    % V2 拍频积分后的非均匀光频位置，注意不允许代入 truth.u 拟合它。
    [u_sswt,meta_sswt]=prepare_frequency_coordinates_v4( ...
               v2result.calibration.sswt.nu_offset_Hz,cfg,'SSWT');

    timer=tic;
    truth_recon=reconstruct_on_track_v4(u_true,data,cfg,k,true);
    timing.truth_recon_s=toc(timer);
    timer=tic;
    sswt_recon=reconstruct_on_track_v4(u_sswt,data,cfg,k,true);
    timing.sswt_recon_s=toc(timer);

    % 无校准：把等时间采集强行当作等光频采集（故意有误的基线）。
    x_time=(0:N-1)'/N;
    time_window=spectral_window_v3(x_time,cfg.v3.window);
    uncal=fft(data.*time_window)/N;
    uncal=uncal(1:numel(k));

    spectra.fft_uncalibrated=uncal;
    spectra.nufft_truth=truth_recon.spectrum;
    spectra.interp_truth=truth_recon.linear;
    spectra.interp_sswt=sswt_recon.linear;
    spectra.pchip_sswt=sswt_recon.pchip;
    spectra.nufft_sswt=sswt_recon.spectrum;

    % STFT/CWT 作为可选消融实验。它们的累积偏差可能将坐标推至 [0,1)
    % 之外。不能静默归一化为真值；若超界，只跳过该可选支路。
    extra=struct();
    if cfg.v4.include_stft_cwt
        for j=1:2
            names={'stft','cwt'}; name=names{j};
            try
                [u,~]=prepare_frequency_coordinates_v4( ...
                     v2result.calibration.(name).nu_offset_Hz,cfg,upper(name));
                reco=reconstruct_on_track_v4(u,data,cfg,k,false);
                spectra.(['nufft_' name])=reco.spectrum;
                extra.(name)=reco;
            catch ME
                % 不影响 SSWT 核心对比；报告明确为什么跳过。
                warning('V4:OptionalMethodSkipped', ...
                        '跳过可选 %s→NUFFT：%s',upper(name),ME.message);
            end
        end
    end

    % 孤立反射点实验：用 V1 的真值单分量（无噪声）生成一条单峰谱。
    % 目的是测功率半高宽/非线性展宽，不用主干涉叠加谱冒充单峰 FWHM。
    iso=[];
    if cfg.v4.show_isolated_reflector
        j=cfg.v4.isolated_reflector_index;
        if ~(isscalar(j) && j>=1 && j<=numel(signals.z_true_m) && j==floor(j))
            error('isolated_reflector_index 超出反射点范围。');
        end
        one=signals.main_components(:,j);
        a=reconstruct_on_track_v4(u_true,one,cfg,k,false);
        b=reconstruct_on_track_v4(u_sswt,one,cfg,k,true);
        no=fft(one.*time_window)/N;
        iso.z_true_m=signals.z_true_m(j);
        iso.nufft_truth=a.spectrum;
        iso.nufft_sswt=b.spectrum;
        iso.interp_sswt=b.linear;
        iso.fft_uncalibrated=no(1:numel(k));
    end

    results.k=k;
    results.z_m=z;
    results.dz_m=dz;
    results.nominal_span_Hz=nominal_span;
    results.true_u=u_true;
    results.estimated_u=u_sswt;
    results.coordinate_details.true=meta_true;
    results.coordinate_details.sswt=meta_sswt;
    results.calibration_metrics=v2metrics;
    results.v2=v2result;
    results.reconstruction.truth=truth_recon;
    results.reconstruction.sswt=sswt_recon;
    results.reconstruction.extra=extra;
    results.spectra=spectra;
    results.isolated=iso;
    timing.v2_total_s=v2result.elapsed.total;
    timing.joint_total_s=toc(joint_timer);
    results.elapsed=timing;
    metrics=evaluate_joint_v4(results,truth,signals,cfg);

    fprintf('\n=============== V4 | SSWT + NUFFT joint OFDR ===============\n');
    fprintf('N=%d | bandwidth=%.4f GHz | dz=%.4f mm | alpha=%.2f | J=%d\n', ...
           N,nominal_span/1e9,dz*1e3,cfg.v3.alpha,cfg.v3.kernel_width);
    fprintf('SSWT beat RMSE (central 90%%) = %.3f Hz\n',v2metrics.sswt.beat_rmse_Hz);
    fprintf('SSWT optical-frequency RMSE = %.4f MHz; wavelength RMSE = %.4f fm\n', ...
           v2metrics.sswt.frequency_rmse_MHz,v2metrics.sswt.wavelength_rmse_fm);
    fprintf('Estimated coordinate error = %.4f MHz RMS, %.4f MHz maximum\n', ...
           metrics.scan_error_rmse_MHz,metrics.scan_error_max_MHz);
    fprintf('Method                      Magnitude rel.L2     Complex rel.L2\n');
    chosen={'fft_uncalibrated','interp_truth','nufft_truth','interp_sswt','nufft_sswt'};
    for j=1:numel(chosen)
        name=chosen{j}; q=metrics.(name);
        fprintf('%-27s %13.4e %17.4e\n',name,q.magnitude_relative_l2,q.complex_relative_l2);
    end
    fprintf('Reflector positions (m)    : '); fprintf('%.4f ',signals.z_true_m);fprintf('\n');
    fprintf('SSWT+NUFFT recovered peaks : '); fprintf('%.4f ',metrics.nufft_sswt.peaks_m);fprintf('\n');
    fprintf('True+NUFFT recovered peaks : '); fprintf('%.4f ',metrics.nufft_truth.peaks_m);fprintf('\n');
    if ~isempty(metrics.isolated)
        fprintf('Isolated corrected peak power FWHM (mm): truth NUFFT %.3f | SSWT NUFFT %.3f\n', ...
          metrics.isolated.nufft_truth.power_fwhm_m*1e3, ...
          metrics.isolated.nufft_sswt.power_fwhm_m*1e3);
        fprintf('Isolated reflector 90%% energy width (mm): raw FFT %.3f | truth NUFFT %.3f | SSWT NUFFT %.3f\n', ...
          metrics.isolated.fft_uncalibrated.energy90_width_m*1e3, ...
          metrics.isolated.nufft_truth.energy90_width_m*1e3, ...
          metrics.isolated.nufft_sswt.energy90_width_m*1e3);
    end
    fprintf('SSWT+NUFFT %0.4fs | Truth+NUFFT %0.4fs (includes interpolation baselines)\n', ...
           timing.sswt_recon_s,timing.truth_recon_s);
    fprintf('NOTE: MATLAB running time is measured locally; full spectral accuracy not implied by FWHM.\n');
    if cfg.v4.plot_enabled
        plot_v4_results(cfg,truth,signals,results,metrics);
    end
end
