function [cfg,results]=main_v7d(cfg)
%MAIN_V7D 仅运行V7d-PF开发集；冻结开关被协议函数强制锁定。
% 输出 results.development：七方法同一试次配对，失败计入分母。
    here=fileparts(mfilename('fullpath'));
    addpath(fullfile(fileparts(here),'v7c'));
    if nargin<1||isempty(cfg),cfg=config_v7d();end
    v7d_assert_protocol(cfg);
    results=struct();
    results.protocol_id=cfg.v7d.protocol_id;
    results.algorithm='V7d-PF: per-candidate constrained blocked-CV SAPC';
    results.restrictions=['known upstream static segment; same physical TLS sweep; ' ...
       'main detector noise OFF; oracle only for scoring'];
    t0=tic;
    if cfg.v7d.run_development
        results.development=v7d_run_trials(cfg,cfg.v7d.development_repeats);
        s=results.development.summary;
        fprintf('\n========== V7d-PF | DEVELOPMENT ONLY ==========\n');
        fprintf('Successful %d/%d | failures %d (%.2f%%)\n', ...
            s.n_success,s.total,s.failures,100*s.failure_rate);
        if s.n_success>0
            fprintf('Method order: Oracle, Raw SSWT, Smoothed, Affine, Full SAPC, V7c, V7d-PF\n');
            fprintf('Core RMSE(ue): ');fprintf(' %.6f',s.mean_core);fprintf('\n');
            fprintf('Holdout RMS:  ');fprintf(' %.6f',s.mean_holdout);fprintf('\n');
            fprintf('Mean validity:');fprintf(' %.4f',s.mean_valid);fprintf('\n');
            fprintf('Alpha V7c [0 .25 .5 .75 1]: ');fprintf('%d ',s.alpha_counts_v7c);fprintf('\n');
            fprintf('Alpha V7d [0 .25 .5 .75 1]: ');fprintf('%d ',s.alpha_counts_v7d);fprintf('\n');
            fprintf('Changed alpha decisions: %d/%d valid trials\n', ...
                s.changed_decision_count,s.n_success);
            for k=1:numel(s.comparisons)
                c=s.comparisons(k);
                fprintf('V7d vs %s: Core gain %.6f ue [%.6f, %.6f], ', ...
                    c.versus,c.mean_core_gain,c.core_CI95);
                fprintf('wins %d losses %d ties %d worst regression %.6f ue\n', ...
                    c.wins,c.losses,c.ties,c.worst_regression);
                fprintf('  Holdout gain %.6f ue [%.6f, %.6f], mean valid gain %.5f pp\n', ...
                    c.mean_holdout_gain,c.holdout_CI95,100*c.mean_valid_gain);
            end
        end
    end
    results.elapsed_s=toc(t0);
    fprintf('V7d-PF elapsed %.2f s. All failures remain in trial denominator.\n', ...
        results.elapsed_s);
    fprintf('FROZEN TEST LOCKED. Development results are NOT independent evidence.\n');
    if cfg.v7d.save_results
        folder=cfg.v7d.output_dir;
        if ~exist(folder,'dir'),mkdir(folder);end
        save(fullfile(folder,'V7d_DEVELOPMENT_results.mat'),'cfg','results','-v7.3');
        if isfield(results,'development')
            v7d_export_trials(folder,results.development);
        end
    end
    if cfg.v7d.make_plots && isfield(results,'development')
        v7d_plot_results(results.development,cfg);
    end
end
