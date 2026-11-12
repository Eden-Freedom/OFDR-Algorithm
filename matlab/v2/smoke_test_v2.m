function smoke_test_v2()
%SMOKE_TEST_V2 V2 最小数值正确性测试。
% 运行：addpath('matlab/v2'); smoke_test_v2;
% 由于当前工程尚未由作者在真实 MATLAB 环境执行，若失败请反馈报错行。
    cfg=config_v2();
    cfg.plot.enabled=false;
    cfg.sim.add_noise=false;
    fs=cfg.acq.fs_Hz;
    t=(0:cfg.acq.N-1)'/fs;

    % 测试 1：固定 50 kHz 纯余弦的 SSWT 脊线应接近真实频率。
    f0=50e3;
    tone=cos(2*pi*f0*t+0.32);
    cwt=cwt_morlet_fft(tone,fs,cfg.sswt);
    sst=synchrosqueeze_cwt(cwt,cfg.sswt);
    ridge=extract_sswt_ridge(sst,cwt,cfg.sswt);
    interior=(t>0.05*max(t)) & (t<0.95*max(t));
    err_tone=sqrt(mean((ridge.freq_Hz(interior)-f0).^2));
    assert(err_tone<250, '纯音测试失败：SSWT 脊线误差 %.2f Hz。',err_tone);
    assert(all(isfinite(ridge.freq_Hz)), 'SSWT 纯音脊线包含非有限值。');

    % 测试 2：扫频模型为无噪声时，SSWT 不能产生错误数量级的拍频。
    [~,truth,signals,results,metrics]=main_v2(cfg);
    assert(all(size(results.sswt.T)==[numel(results.sswt.freq_axis_Hz),truth.N]));
    assert(metrics.sswt.beat_rmse_Hz<1200, ...
           'V1 无噪声拍频回归失败：RMSE=%.1f Hz。',metrics.sswt.beat_rmse_Hz);
    assert(metrics.sswt.wavelength_rmse_fm<10000, ...
           'V1 无噪声波长回归失败：RMSE=%.1f fm。',metrics.sswt.wavelength_rmse_fm);

    % 测试 3：如果输入的拍频是真值，那么数值积分的相对光频误差应非常小。
    exact=recover_optical_frequency(signals.aux_beat_Hz,truth.t_s, ...
                    cfg.aux.delay_s,truth.nu_start_Hz,cfg.const.c_m_s);
    err_relative=max(abs(exact.nu_offset_Hz-truth.nu_offset_Hz))/truth.delta_nu_Hz;
    assert(err_relative<1e-6,'真实拍频积分误差过大: %.3g。',err_relative);
    fprintf('\nV2 smoke tests PASS. Pure tone RMSE %.3f Hz; true-integral relative error %.3g.\n', ...
             err_tone,err_relative);
end
