function a=p1c_gauge_nudft_audit(cfg)
%P1C_GAUGE_NUDFT_AUDIT 真实坐标Oracle下，对Gauge两端+9bin作直接NUDFT。
% 目的：检验NUFFT复谱近似误差能否放大为应变Gauge相位误差。
% 不研发校正器、不选择参数、不运行任何冻结随机试次。
%
% 完全重现P1a已查看的开发种子 scatter_seed_base + 200000，
% 以数值上相同的reference/measurement物理信号比对两种重构。
% 不能将同一seed的重算称作新的独立验证。
%
% 流程：
% 1. 用原V6光学前向与真q重构Reference/Measurement；
% 2. 保留V6c NUFFT定义的Core有效Gauge掩码作为固定比较集合；
% 3. 求出每个Gauge两端、平滑窗口内所有所需频率bin的并集；
% 4. 对这些bin以同窗、同密度权重做直接NUDFT；
% 5. 原样实施两个距离端点复比值、9bin复平均与angle；
% 6. 输出圆周相位误差及Core应变RMSE，不因NUDFT幅度变化筛点。
    if nargin<1||isempty(cfg),cfg=config_p1p2();end
    p1p2_assert_protocol(cfg);
    oldrng=rng;
    cleanup=onCleanup(@()rng(oldrng)); %#ok<NASGU> 恢复MATLAB调用前随机数状态

    truth=simulate_laser_sweep(cfg);
    local=cfg;
    local.v6.scatter_seed=cfg.p1p2.scatter_seed_base+200000;
    [reference,scatter]=v6_rayleigh_signal(local,truth);
    pair=v6c_forward_pair(local,truth,cfg.p1p2.p1_strain_microeps, ...
          struct('ref_signal',reference,'scatter',scatter));
    qtrue=truth.nu_offset_Hz(:);
    R=v6_reconstruct_trace(local,truth,reference,qtrue);
    M=v6_reconstruct_trace(local,truth,pair.measurement_signal,qtrue);
    metric=v6c_demodulate_strain(local,R,M,R,pair.geometry);
    if ~metric.valid
        error('P1C:GaugeInvalid','原NUFFT的Oracle Gauge解调无效：%s', ...
              metric.failure_reason);
    end
    ids=find(metric.core_valid);
    if numel(ids)<cfg.p1p2.min_common_core
        error('P1C:CoreCount','固定Core有效Gauge数量不足。');
    end
    lag=metric.gauge_lag_bins;
    w=cfg.v6c.phase_avg_bins;
    nSpec=numel(R.spectrum);
    [neighbor,sites]=p1c_required_sites(ids,nSpec,lag,w);
    k=sites-1; % 直接NUDFT使用从0开始的空间频率下标

    directR=nudft_reference_v3(R.u,reference(:).*R.window(:), ...
                             R.density(:),k,32);
    directM=nudft_reference_v3(M.u,pair.measurement_signal(:).*M.window(:), ...
                             M.density(:),k,32);
    % 没有参与任何被评估Gauge平滑邻域的谱点可以为0；
    % 所有会对ids产生非零conv贡献的两端谱点已放入sites。
    Rd=complex(zeros(nSpec,1));
    Md=complex(zeros(nSpec,1));
    Rd(sites)=directR;
    Md(sites)=directM;
    [phiN,rawN]=p1c_gauge_phase_from_spectra(R.spectrum,M.spectrum,lag,w,ids);
    [phiD,rawD]=p1c_gauge_phase_from_spectra(Rd,Md,lag,w,ids);
    oldPhi=metric.gauge_phase_rad(ids);
    check=angle(exp(1i*(phiN-oldPhi)));
    if max(abs(check))>1e-10
        error('P1C:GaugeDefinition','独立Gauge实现与原V6c数值定义不一致。');
    end
    phaseDifference=angle(exp(1i*(phiD-phiN)));
    rawDifference=angle(exp(1i*(rawD-rawN)));
    strainScale=metric.gauge_scale_microeps_per_rad;
    trueStrain=metric.true_gauge_strain_microeps(ids);
    strainN=phiN*strainScale;
    strainD=phiD*strainScale;
    gap=strainD-strainN; % 只用于固定集合上的应变数值差，不作模糊真值回归
    if ~all(isfinite(phaseDifference))||~all(isfinite(gap))
        error('P1C:Nonfinite','数值Gauge比较产生非有限相位或应变。');
    end
    a=struct();
    a.dataset='development';
    a.audit='P1c same known P1a seed, direct NUDFT vs NUFFT at all required sites';
    a.scatter_seed=local.v6.scatter_seed;
    a.strain_microeps=cfg.p1p2.p1_strain_microeps;
    a.n_core_gauges=numel(ids);
    a.n_required_neighbor_gauges=numel(neighbor);
    a.n_unique_spectral_sites=numel(sites);
    a.core_roi_denominator=nnz(metric.core_eligible);
    a.core_valid_fraction=numel(ids)/max(1,a.core_roi_denominator);
    a.gauge_length_m=metric.gauge_length_actual_m;
    a.phase_average_bins=w;
    a.effective_spatial_support_m=metric.effective_spatial_support_m;
    a.spectrum_relative_L2=[ ...
        norm(R.spectrum(sites)-directR)/max(norm(directR),eps), ...
        norm(M.spectrum(sites)-directM)/max(norm(directM),eps)];
    a.gauge_phase_difference_RMS_rad=sqrt(mean(phaseDifference.^2));
    a.gauge_phase_difference_max_abs_rad=max(abs(phaseDifference));
    a.raw_gauge_difference_RMS_rad=sqrt(mean(rawDifference.^2));
    a.gauge_numerical_difference_RMS_ue=sqrt(mean((phaseDifference*strainScale).^2));
    a.strain_difference_direct_minus_nufft_RMS_ue=sqrt(mean(gap.^2));
    a.oracle_core_NUFFT_RMSE_ue=sqrt(mean((strainN-trueStrain).^2));
    a.oracle_core_NUDFT_RMSE_ue=sqrt(mean((strainD-trueStrain).^2));
    a.oracle_rmse_difference_ue=a.oracle_core_NUDFT_RMSE_ue- ...
                                a.oracle_core_NUFFT_RMSE_ue;
    % 记录在原NUFFT已被判为有效的位置，直接NUDFT的两端是否降至幅度门限以下。
    endpoints=unique([ids;ids+lag]);
    a.direct_below_original_gate_site_count=nnz( ...
        abs(Rd(endpoints))<=metric.threshold | ...
        abs(Md(endpoints))<=metric.threshold);
    a.n_original_eligible_endpoint_sites=numel(endpoints);
    a.core_gauge_ids=ids;
    a.core_midpoint_m=metric.z_gauge_mid_m(ids);
    a.direct_minus_nufft_phase_rad=phaseDifference;
    a.direct_minus_nufft_strain_ue=gap;

    fprintf('\n========== P1c | DEV NUMERICAL GAUGE AUDIT ==========\n');
    fprintf('Known prior seed %d | Core %d/%d | 9-bin neighbor Gauge %d | direct sites %d\n', ...
        a.scatter_seed,a.n_core_gauges,a.core_roi_denominator, ...
        a.n_required_neighbor_gauges,a.n_unique_spectral_sites);
    fprintf('Complex spectra relative L2 [reference measurement]=[%.4g %.4g]\n', ...
        a.spectrum_relative_L2(1),a.spectrum_relative_L2(2));
    fprintf('Gauge numerical phase RMS=%.6g rad, max=%.6g rad, strain RMS difference=%.6g ue\n', ...
        a.gauge_phase_difference_RMS_rad,a.gauge_phase_difference_max_abs_rad, ...
        a.gauge_numerical_difference_RMS_ue);
    fprintf('Oracle Core RMSE NUFFT=%.6g ue | direct NUDFT=%.6g ue | delta=%+.6g ue\n', ...
        a.oracle_core_NUFFT_RMSE_ue,a.oracle_core_NUDFT_RMSE_ue, ...
        a.oracle_rmse_difference_ue);
    fprintf('Direct below original amplitude gate: %d/%d required endpoint sites\n', ...
        a.direct_below_original_gate_site_count,a.n_original_eligible_endpoint_sites);
    fprintf('Only known-development-seed numerical check; no calibration parameters were fitted.\n');
end