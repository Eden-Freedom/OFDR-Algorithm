function out = run_v6b_correlation_mc(cfg,truth)
%RUN_V6B_CORRELATION_MC 多散射实现/多随机误差下的等单扫RMSE-相关性实验。
% 相同 trial 的所有 rho 使用同一静态光纤、同一参考坐标、相同主信号。
% 强制使用所有有效 rho 工况共同的 gauge-mask，另存每组本来的有效率。
    rhos=cfg.v6b.rho_values(:);
    nr=numel(rhos);nt=cfg.v6b.repeats;
    nanmat=nan(nr,nt);
    out.rho_target=rhos;out.repeats=nt;
    out.diff_rmse_MHz=nanmat;out.gauge_rmse_rad=nanmat;
    out.false_proxy_rmse_microeps=nanmat;out.valid_fraction=nanmat;
    out.common_gauge_rmse_rad=nanmat;
    out.common_false_proxy_rmse_microeps=nanmat;
    out.common_valid_fraction=nanmat;
    out.empirical_rho=nanmat;
    out.diff_weighted_mean_MHz=nanmat;
    out.diff_scale_ppm=nanmat;
    out.diff_nonlinear_rmse_MHz=nanmat;
    out.near_wrap_count=nanmat;
    out.valid=false(nr,nt);out.failure_reason=cell(nr,nt);
    out.scatter_seed=zeros(nt,1);out.error_seed_ref=zeros(nt,1);
    out.error_seed_meas=zeros(nt,1);
    out.example=struct();
    for trial=1:nt
        local=cfg;
        local.v6.scatter_seed=cfg.v6.scatter_seed+(trial-1)*cfg.v6b.scatter_seed_stride;
        local.v6.inject_seed_ref=cfg.v6.inject_seed_ref+(trial-1)*cfg.v6b.inject_seed_stride;
        local.v6.inject_seed_independent=cfg.v6.inject_seed_independent+(trial-1)*cfg.v6b.inject_seed_stride;
        local.v6.rho_values=rhos.';
        out.scatter_seed(trial)=local.v6.scatter_seed;
        out.error_seed_ref(trial)=local.v6.inject_seed_ref;
        out.error_seed_meas(trial)=local.v6.inject_seed_independent;
        [main_signal,scatter]=v6_rayleigh_signal(local,truth);
        oracle=v6_reconstruct_trace(local,truth,main_signal,truth.nu_offset_Hz);
        controlled=v6_controlled_residuals(local,truth.N,truth.fs_Hz);
        qref=truth.nu_offset_Hz(:)+controlled.e_ref_Hz(:);
        try
            reference=v6_reconstruct_trace(local,truth,main_signal,qref);
        catch ME
            for i=1:nr,out.failure_reason{i,trial}=['reference: ' ME.message];end
            continue;
        end
        all_metrics=cell(nr,1);
        allvalid=true;
        e=controlled.e_ref_Hz;
        for i=1:nr
            qmeas=truth.nu_offset_Hz(:)+controlled.e_meas_Hz{i};
            differr=controlled.e_meas_Hz{i}-e;
            out.diff_rmse_MHz(i,trial)=sqrt(mean(differr.^2))/1e6;
            out.empirical_rho(i,trial)=controlled.rho_empirical(i);
            try
                dec=v6b_decompose_error(truth.nu_offset_Hz,differr, ...
                    reference.window.*reference.density);
                out.diff_weighted_mean_MHz(i,trial)=dec.weighted_mean_Hz/1e6;
                out.diff_scale_ppm(i,trial)=dec.scale_ppm;
                out.diff_nonlinear_rmse_MHz(i,trial)=dec.nonlinear_weighted_rmse_Hz/1e6;
                measurement=v6_reconstruct_trace(local,truth,main_signal,qmeas);
                metrics=v6_demodulate_zero_strain(local,reference,measurement,oracle);
                if ~metrics.valid, error('V6b:InvalidGauge','%s',metrics.failure_reason);end
                all_metrics{i}=metrics;
                out.valid(i,trial)=true;
                out.gauge_rmse_rad(i,trial)=metrics.gauge_phase_rmse_rad;
                out.false_proxy_rmse_microeps(i,trial)=metrics.false_strain_rmse_microeps;
                out.valid_fraction(i,trial)=metrics.valid_fraction;
                out.near_wrap_count(i,trial)=metrics.near_wrap_count;
                out.failure_reason{i,trial}='';
            catch ME
                allvalid=false;out.failure_reason{i,trial}=ME.message;
            end
        end
        % 共同有效掩码：所有工况比较完全相同的 gauge 位置，避免门限选择偏差。
        if allvalid
            mask=all_metrics{1}.valid_gauge;
            for i=2:nr,mask=mask & all_metrics{i}.valid_gauge;end
            zz=all_metrics{1}.z_m(:);
            lag=all_metrics{1}.gauge_lag_bins;
            I=(1:(numel(zz)-lag)).';
            J=I+lag;
            eligible=(zz(I)>=local.v6.roi_m(1)) & (zz(I)<=local.v6.roi_m(2)) & ...
                     (zz(J)>=local.v6.roi_m(1)) & (zz(J)<=local.v6.roi_m(2));
            common_frac=nnz(mask)/max(1,nnz(eligible));
            for i=1:nr
                out.common_valid_fraction(i,trial)=common_frac;
                if any(mask)
                    ph=all_metrics{i}.gauge_phase_rad(mask);
                    pr=all_metrics{i}.equivalent_false_strain_microeps(mask);
                    out.common_gauge_rmse_rad(i,trial)=sqrt(mean(ph.^2));
                    out.common_false_proxy_rmse_microeps(i,trial)=sqrt(mean(pr.^2));
                end
            end
        end
        if trial==1
            out.example.truth=truth;
            out.example.scatterers=scatter;
            out.example.main_signal=main_signal;
            out.example.reference_error_Hz=controlled.e_ref_Hz;
            out.example.measurement_errors_Hz=controlled.e_meas_Hz;
            out.example.metrics=all_metrics;
            out.example.reference_trace=reference;
            out.example.oracle_trace=oracle;
            out.example.reconstruction_gauge_m=local.v6.gauge_length_m;
        end
        if cfg.v6b.verbose
            fprintf('[V6b corr] trial %d/%d, valid %d/%d, common valid %.1f%%\n', ...
                trial,nt,nnz(out.valid(:,trial)),nr, ...
                100*out.common_valid_fraction(1,trial));
        end
    end
    for i=1:nr
        good=out.valid(i,:) & isfinite(out.common_false_proxy_rmse_microeps(i,:));
        out.summary.n_success(i,1)=nnz(good);
        out.summary.failure_rate(i,1)=1-nnz(out.valid(i,:))/nt;
        out.summary.matched_failure_rate(i,1)=1-nnz(good)/nt;
        vals=out.common_false_proxy_rmse_microeps(i,good);
        vals2=out.common_gauge_rmse_rad(i,good);
        dm=out.diff_rmse_MHz(i,good);
        out.summary.mean_proxy_microeps(i,1)=mean_or_nan(vals);
        out.summary.mean_gauge_rad(i,1)=mean_or_nan(vals2);
        out.summary.mean_diff_MHz(i,1)=mean_or_nan(dm);
        [lo,hi]=v6b_bootstrap_ci(vals,cfg.v6b.bootstrap_reps,cfg.v6b.bootstrap_seed+i);
        out.summary.proxy_CI95_microeps(i,:)=[lo hi];
    end
    % 配对效应：与 rho=1 的差值逐 trial 计算，再对 trial 做 bootstrap。
    one=find(abs(rhos-1)<1e-12,1);
    out.summary.paired_vs_rho1_mean_microeps=nan(nr,1);
    out.summary.paired_vs_rho1_CI95_microeps=nan(nr,2);
    out.summary.paired_vs_rho1_count=zeros(nr,1);
    if ~isempty(one)
        for i=1:nr
            good=out.valid(i,:)&out.valid(one,:) & ...
                 isfinite(out.common_false_proxy_rmse_microeps(i,:)) & ...
                 isfinite(out.common_false_proxy_rmse_microeps(one,:));
            delta=out.common_false_proxy_rmse_microeps(i,good) - ...
                  out.common_false_proxy_rmse_microeps(one,good);
            out.summary.paired_vs_rho1_count(i)=numel(delta);
            if ~isempty(delta)
                out.summary.paired_vs_rho1_mean_microeps(i)=mean(delta);
                [lo,hi]=v6b_bootstrap_ci(delta,cfg.v6b.bootstrap_reps, ...
                    cfg.v6b.bootstrap_seed+100+i);
                out.summary.paired_vs_rho1_CI95_microeps(i,:)=[lo hi];
            end
        end
    end
end
function m=mean_or_nan(x)
    if isempty(x),m=NaN;else,m=mean(x);end
end
