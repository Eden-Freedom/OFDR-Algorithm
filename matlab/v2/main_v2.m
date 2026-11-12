function [cfg,truth,signals,results,metrics] = main_v2(cfg)
%MAIN_V2 V2 运行入口：V1 真实信号 -> STFT/CWT/SSWT -> 脊线 -> 光频恢复。
%
% 在仓库根目录运行：
%   addpath('matlab/v2');
%   [cfg,truth,signals,results,metrics] = main_v2();
%   cfg = config_v2(); cfg.sswt.voices_per_octave = 36; main_v2(cfg);
%
% 重要：V2 只做动态波长校准，NUFFT 将于 V3 实现。
    here=fileparts(mfilename('fullpath'));
    v1_dir=fullfile(fileparts(here),'v1');
    if exist('simulate_laser_sweep','file')~=2
        addpath(v1_dir);
    end
    if nargin<1 || isempty(cfg)
        cfg=config_v2();
    end
    truth=simulate_laser_sweep(cfg);
    signals=simulate_ofdr_signals(cfg,truth);
    report=validate_v1(cfg,truth,signals);  %#ok<NASGU>

    if ~(cfg.sswt.f_min_Hz < min(signals.aux_beat_Hz) && ...
         cfg.sswt.f_max_Hz > max(signals.aux_beat_Hz))
        warning('真实辅助拍频超出 SSWT 分析带；请调整 f_min_Hz/f_max_Hz。');
    end

    total_timer=tic;
    stft_timer=tic;
    stft=estimate_stft_ridge(signals.aux, truth.fs_Hz, cfg.stft, ...
                             cfg.sswt.smooth_points);
    if cfg.sswt.edge_extrapolate
        stft.freq_before_edge_correction_Hz=stft.freq_Hz;
        stft.freq_Hz=ridge_edge_extrapolate(stft.freq_Hz,truth.fs_Hz, ...
                    ceil(cfg.stft.window_length/2),ceil(cfg.sswt.edge_fit_s*truth.fs_Hz));
    end
    elapsed.stft=toc(stft_timer);

    cwt_timer=tic;
    cwt=cwt_morlet_fft(signals.aux, truth.fs_Hz, cfg.sswt);
    cwt_ridge=estimate_cwt_ridge(cwt, cfg.sswt);
    elapsed.cwt=toc(cwt_timer);

    sswt_timer=tic;
    sswt=synchrosqueeze_cwt(cwt, cfg.sswt);
    sswt_ridge=extract_sswt_ridge(sswt,cwt,cfg.sswt);
    elapsed.sswt_step_only=toc(sswt_timer);
    % 完整 SSWT 计算应将其依赖的 CWT 耗时计入。
    elapsed.sswt=elapsed.cwt+elapsed.sswt_step_only;

    calibration.stft=recover_optical_frequency(stft.freq_Hz,truth.t_s, ...
                cfg.aux.delay_s,truth.nu_start_Hz,cfg.const.c_m_s);
    calibration.cwt=recover_optical_frequency(cwt_ridge.freq_Hz,truth.t_s, ...
                cfg.aux.delay_s,truth.nu_start_Hz,cfg.const.c_m_s);
    calibration.sswt=recover_optical_frequency(sswt_ridge.freq_Hz,truth.t_s, ...
                cfg.aux.delay_s,truth.nu_start_Hz,cfg.const.c_m_s);
    elapsed.total=toc(total_timer);

    results.stft=stft;
    results.cwt=cwt;
    results.sswt=sswt;
    results.cwt_ridge=cwt_ridge;
    results.sswt_ridge=sswt_ridge;
    results.calibration=calibration;
    results.elapsed=elapsed;
    metrics=evaluate_calibration_v2(truth,signals,calibration,elapsed,cwt,sswt);

    fprintf('\n=========== OFDR V2 | SSWT calibration ===========\n');
    fprintf('Aux beat true range: %.3f to %.3f kHz | fs = %.1f kHz\n', ...
            min(signals.aux_beat_Hz)/1e3,max(signals.aux_beat_Hz)/1e3,truth.fs_Hz/1e3);
    fprintf('CWT scales: %d | SSWT bins: %d | valid reassignment: %.1f%%\n', ...
            numel(cwt.scales_s),numel(sswt.freq_axis_Hz),100*metrics.sswt_valid_fraction);
    fprintf('Method   Beat RMSE(Hz)*  Optical-freq RMSE(MHz)  Wavelength RMSE(fm)  Time(s)\n');
    names={'stft','cwt','sswt'};
    for j=1:numel(names)
        name=names{j}; q=metrics.(name);
        fprintf('%-7s %14.3f %23.3f %20.3f %8.3f\n',upper(name), ...
              q.beat_rmse_Hz,q.frequency_rmse_MHz,q.wavelength_rmse_fm,q.elapsed_s);
    end
    fprintf('* Beat RMSE excludes first/last 5%%; other RMSE includes full sweep.\n');
    fprintf('SSWT step (excluding CWT) time: %.3f s\n',elapsed.sswt_step_only);
    fprintf('Note: calibration accuracy is not spatial resolution; NUFFT not yet included.\n');

    if cfg.plot.enabled
        plot_v2_results(cfg,truth,signals,results,metrics);
    end
end
