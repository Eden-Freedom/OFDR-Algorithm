function figs = plot_v1_results(cfg, truth, signals, report)
%PLOT_V1_RESULTS V1 的三组教学可视化，坐标均标注实际物理单位。
% 仅使用基础 MATLAB 绘图函数，不依赖其它工具箱。

    t_ms = 1e3*truth.t_s;
    f_nominal_Hz = truth.delta_nu_Hz/cfg.laser.duration_s;
    nu_linear_GHz = (f_nominal_Hz*truth.t_s)/1e9;
    nu_real_GHz = truth.nu_offset_Hz/1e9;
    N = truth.N;

    f1 = figure('Name', 'V1 | TLS Sweep', 'Color', 'w');
    subplot(2,2,1);
    plot(t_ms, nu_real_GHz, 'LineWidth', 1.3); hold on;
    plot(t_ms, nu_linear_GHz, '--', 'LineWidth', 1.1); hold off;
    xlabel('Time (ms)'); ylabel('Optical frequency offset (GHz)');
    legend('Nonlinear','Ideal linear','Location','northwest'); grid on;
    title('TLS frequency trajectory');

    subplot(2,2,2);
    plot(t_ms, truth.tuning_rate_Hz_s/1e12, 'LineWidth', 1.2);
    xlabel('Time (ms)'); ylabel('Tuning rate (THz/s)');
    title('Instantaneous tuning rate'); grid on;

    subplot(2,2,3);
    plot(t_ms, truth.lambda_m*1e9, 'LineWidth', 1.2);
    xlabel('Time (ms)'); ylabel('Wavelength (nm)');
    title('Instantaneous wavelength'); grid on;

    subplot(2,2,4);
    plot(t_ms(2:end), diff(truth.nu_offset_Hz)/1e6, 'LineWidth', 1.2);
    xlabel('Time (ms)'); ylabel('Adjacent frequency step (MHz)');
    title('Nonuniform optical-frequency sampling'); grid on;

    f2 = figure('Name', 'V1 | Auxiliary MZI', 'Color', 'w');
    nshort = min(N, max(16, round(0.5e-3*truth.fs_Hz)));
    subplot(2,1,1);
    plot(t_ms(1:nshort), signals.aux(1:nshort), 'LineWidth', 1.0); hold on;
    plot(t_ms(1:nshort), signals.aux_clean(1:nshort), '--', 'LineWidth', 1.0); hold off;
    xlabel('Time (ms)'); ylabel('Normalized detector output (a.u.)');
    legend('Noisy','Noise-free','Location','best');
    title('Auxiliary MZI interference: local view'); grid on;

    subplot(2,1,2);
    plot(t_ms, signals.aux_beat_Hz/1e3, 'LineWidth', 1.3);
    xlabel('Time (ms)'); ylabel('Beat frequency (kHz)');
    title('True auxiliary beat frequency = delay x tuning rate'); grid on;

    f3 = figure('Name', 'V1 | Main OFDR', 'Color', 'w');
    subplot(2,1,1);
    plot(t_ms(1:nshort), signals.main(1:nshort), 'LineWidth', 1.0); hold on;
    plot(t_ms(1:nshort), signals.main_clean(1:nshort), '--', 'LineWidth', 0.9); hold off;
    xlabel('Time (ms)'); ylabel('Normalized detector output (a.u.)');
    legend('Noisy','Noise-free','Location','best');
    title('Main OFDR interference: local view'); grid on;

    % 不做扫频校正，直接 FFT 的隐含假设是 ν(t) 正比于 t。
    % 第 k 个 FFT bin 的拍频 f_k = k/T，对应 z_k = c*f_k/(2*ng*dν/dt)。
    % 因 fs*T=N，化简为 z_k = c*k/(2*ng*DeltaNu)。
    Y = fft(signals.main);
    k = (0:floor(N/2)).';
    z_axis_m = cfg.const.c_m_s*k/(2*cfg.fut.group_index*truth.delta_nu_Hz);
    amp = abs(Y(1:numel(k)));
    amp_dB = 20*log10(max(amp/max(max(amp), eps), 1e-12));

    subplot(2,1,2);
    plot(z_axis_m, amp_dB, 'LineWidth', 1.1); hold on;
    for j = 1:numel(cfg.fut.z_m)
        xline(cfg.fut.z_m(j), '--', 'LineWidth', 0.9);
    end
    hold off;
    xlim([0, min(max(z_axis_m), 1.15*max(cfg.fut.z_m))]);
    ylim([-80, 5]);
    xlabel('Nominal distance (m)'); ylabel('Relative amplitude (dB)');
    title('UNCALIBRATED FFT: dashed lines indicate true reflector positions'); grid on;

    figs = [f1, f2, f3];
    if cfg.plot.save_png
        if ~exist(cfg.plot.output_dir, 'dir')
            mkdir(cfg.plot.output_dir);
        end
        names = {'01_tls_sweep.png','02_aux_mzi.png','03_main_ofdr_fft.png'};
        for i = 1:numel(figs)
            print(figs(i), fullfile(cfg.plot.output_dir, names{i}), '-dpng', '-r160');
        end
        fprintf('PNG 图像已保存至 %s\n', cfg.plot.output_dir);
    end

    fprintf('图 3 为未校准普通 FFT，对照用；V1 尚未实现 SSWT/NUFFT。\n');
    fprintf('理想距离尺度：%.3f mm，严格非均匀光频采样需后续重构算法处理。\n', ...
            report.ideal_delta_z_m*1e3);
end
