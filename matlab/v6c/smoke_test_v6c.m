function smoke_test_v6c()
%SMOKE_TEST_V6C 三重物理验收：零应变严格不变、真值符号、非零量值。
% 无声称 MATLAB 端已运行；使用者在本地执行并保存控制台输出。
    here=fileparts(mfilename('fullpath'));addpath(here);
    cfg=config_v6c();cfg.v6c.save_results=false;cfg.v6c.make_plots=false;
    truth=simulate_laser_sweep(cfg);
    [sig,scatter]=v6_rayleigh_signal(cfg,truth);
    source=struct('ref_signal',sig,'scatter',scatter);
    pair0=v6c_forward_pair(cfg,truth,0,source);
    rel=norm(pair0.measurement_signal-pair0.reference_signal)/norm(pair0.reference_signal);
    assert(rel<1e-11,'V6c: Zero-strain forward signal is not equal to reference');
    oracle=v6_reconstruct_trace(cfg,truth,sig,truth.nu_offset_Hz);
    r0=v6_reconstruct_trace(cfg,truth,pair0.measurement_signal,truth.nu_offset_Hz);
    m0=v6c_demodulate_strain(cfg,oracle,r0,oracle,pair0.geometry);
    assert(m0.valid && m0.full_strain_rmse_microeps<1e-7, ...
        'V6c: Zero-strain oracle should return zero response');
    p5=v6c_forward_pair(cfg,truth,5,source);
    m5=v6c_demodulate_strain(cfg,oracle, ...
        v6_reconstruct_trace(cfg,truth,p5.measurement_signal,truth.nu_offset_Hz), ...
        oracle,p5.geometry);
    assert(m5.valid,'V6c: nonzero physical oracle gauge invalid');
    assert(m5.core_true_mean_microeps>4.8 && m5.core_true_mean_microeps<5.2, ...
        'V6c: gauge-averaged analytic strain plateau is incorrect');
    assert(m5.core_measured_mean_microeps>0, ...
        'V6c: reconstructed strain sensitivity sign is incorrect');
    assert(abs(m5.core_measured_mean_microeps-5)<1.0, ...
        'V6c: oracle recovered strain differs by more than 1 microstrain');
    assert(m5.core_strain_rmse_microeps<1.0, ...
        'V6c: oracle spatial strain RMSE too large: check group-delay vs carrier phase');
    fprintf('[V6c smoke] PASS: zero oracle rel %.3e, nonzero 5 ue mean %.4f ue, core RMSE %.4f ue, valid %.1f%%\n', ...
        rel,m5.core_measured_mean_microeps,m5.core_strain_rmse_microeps,100*m5.valid_fraction);
end
