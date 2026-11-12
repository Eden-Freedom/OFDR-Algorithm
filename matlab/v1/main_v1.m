function [cfg, truth, signals, report] = main_v1()
%MAIN_V1 V1 完整入口：参数 -> TLS -> 辅助 MZI/主 OFDR -> 物理检查 -> 绘图。
% 运行：addpath('matlab/v1'); main_v1;
% 可取回所有中间数据：[cfg,truth,signals,report] = main_v1();
%
% 重要：V1 只生成信号和未校准 FFT，并未实现 SSWT/NUFFT。

    cfg = config_v1();
    truth = simulate_laser_sweep(cfg);
    signals = simulate_ofdr_signals(cfg, truth);
    report = validate_v1(cfg, truth, signals);

    fprintf('\n======= OFDR V1 signal simulation =======\n');
    fprintf('N = %d, fs = %.1f kHz, duration = %.2f ms\n', ...
            truth.N, truth.fs_Hz/1e3, cfg.laser.duration_s*1e3);
    fprintf('Optical sweep: %.3f GHz, %.0f -> %.0f nm\n', ...
            truth.delta_nu_Hz/1e9, cfg.laser.lambda_start_m*1e9, ...
            cfg.laser.lambda_end_m*1e9);
    fprintf('Auxiliary MZI delay: %.2f ns, max beat: %.2f kHz\n', ...
            cfg.aux.delay_s*1e9, report.max_aux_beat_Hz/1e3);
    fprintf('Main OFDR max beat: %.2f kHz, Nyquist: %.2f kHz\n', ...
            report.max_main_beat_Hz/1e3, report.nyquist_Hz/1e3);
    fprintf('Conservative unaliased range: %.3f m\n', report.conservative_max_range_m);
    fprintf('Ideal distance scale: %.3f mm\n', report.ideal_delta_z_m*1e3);
    fprintf('Reflectors (m): '); fprintf('%.3f ', signals.z_true_m); fprintf('\n');
    fprintf('Validation: monotonic sweep, finite data, Nyquist conditions PASS.\n');

    if cfg.plot.enabled
        plot_v1_results(cfg, truth, signals, report);
    end
end
