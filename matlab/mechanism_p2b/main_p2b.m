function [cfg,results]=main_p2b(cfg)
%MAIN_P2B 开发期共模光频坐标方向灵敏度预测；冻结测试始终禁用。
% P2b使用Oracle坐标与共模误差仅作因果机制输入，不能部署。
    if nargin<1||isempty(cfg),cfg=config_p2b();end
    p2b_assert_protocol(cfg);
    started=tic;
    truth=simulate_laser_sweep(cfg);
    r=p2b_run_trials(cfg,truth);
    s=r.summary;
    results=struct;
    results.protocol=cfg.p2b.protocol_id;
    results.dataset='development';
    results.method='known-truth diagnostic finite directional derivative';
    results.development=r;
    results.elapsed_s=toc(started);
    fprintf('\n========== P2b | COMMON SENSITIVITY | DEVELOPMENT ==========\n');
    fprintf('Successful %d/%d, failures %d (%.2f%%)\n', ...
        s.n_success,s.n_total,s.n_failure,100*s.failure_rate);
    if s.n_success>0
        fprintf('Mean fixed ROI valid %.2f%%, mean Core Gauge %.1f\n', ...
            100*s.mean_common_valid_fraction,s.mean_common_core_count);
        fprintf('Mean common error trajectory RMS=%.6g MHz\n', ...
            s.mean_ec_rms_MHz);
        for j=1:numel(s.strains_microeps)
            fprintf('eps=%g ue | grad RMS=%.5g ue/alpha | h-gap RMS=%.5g\n', ...
                s.strains_microeps(j),s.mean_gradient_rms(j), ...
                s.mean_gradient_h_difference(j));
            for v=1:numel(s.test_alpha)
                fprintf('  alpha=%.2f | actual C=%.6g, predicted C=%.6g ue^2', ...
                    s.test_alpha(v),s.mean_C_actual(j,v),s.mean_C_pred(j,v));
                fprintf(' | signed error=%.6g [%.6g,%.6g] | MAE=%.6g | sign %d/%d\n', ...
                    s.mean_signed_error(j,v), ...
                    s.prediction_error_CI95(j,v,1),s.prediction_error_CI95(j,v,2), ...
                    s.mean_abs_error(j,v),s.n_sign_agree(j,v), ...
                    s.n_nonzero_actual(j,v));
                fprintf('    Zero predictor MAE=%.6g | paired absolute-error gain=%.6g [%.6g %.6g] | better %d worse %d\n', ...
                    s.mean_null_abs_error(j,v),s.mean_abs_gain_vs_zero(j,v), ...
                    s.gain_CI95(j,v,1),s.gain_CI95(j,v,2), ...
                    s.n_prediction_better(j,v),s.n_prediction_worse(j,v));
            end
        end
    end
    fprintf('Development only; frozen testing is locked; no algorithm improvement is claimed.\n');
    if cfg.p2b.save_results
        folder=cfg.p2b.output_dir;
        if ~isfolder(folder),mkdir(folder);end
        save(fullfile(folder,'P2B_DEVELOPMENT_results.mat'),'cfg','results','-v7.3');
        p2b_export_trials(cfg,r);
    end
    if cfg.p2b.make_plots
        p2b_plot_results(r);
    end
end