function [cfg,results]=main_v7c(cfg)
%MAIN_V7C 可运行研究入口：开发集、显式启用的冻结测试、条件泛化。
% 冻结测试的样本不得在看到结果后重新调门限；变更必须发布新协议和种子。
    here=fileparts(mfilename('fullpath'));
    addpath(fullfile(fileparts(here),'v7b'));
    if nargin<1||isempty(cfg),cfg=config_v7c();end
    v7c_assert_protocol(cfg);
    results=struct();results.protocol_id=cfg.v7c.protocol_id;
    results.algorithm='Blocked static-region cross-validated confidence-gated SAPC';
    results.seed_policy='v7b historical seeds excluded; dev/test/conditions separated';
    results.leakage_policy='Only known upstream static segment used; downstream and strained Core used solely for score';
    results.alpha_grid=cfg.v7c.alpha_grid;
    results.frozen_thresholds=[cfg.v7c.cv_required_relative_gain, ...
        cfg.v7c.cv_required_absolute_rad,cfg.v7c.min_data_rcond, ...
        cfg.v7c.max_extra_correction_MHz];
    start=tic;
    if cfg.v7c.run_development
        results.development=v7c_run_trials(cfg,cfg.v7c.development_repeats,'development',0);
        print_summary('DEVELOPMENT',results.development.summary);
    end
    if cfg.v7c.run_frozen_test
        results.frozen_test=v7c_run_trials(cfg,cfg.v7c.frozen_test_repeats,'frozen_test',0);
        print_summary('FROZEN INDEPENDENT TEST',results.frozen_test.summary);
    end
    if cfg.v7c.run_conditions
        results.conditions=v7c_run_conditions(cfg);
    end
    results.elapsed_s=toc(start);
    fprintf('V7c actual elapsed time %.2fs. Samples with failures remain in the denominator.\n',results.elapsed_s);
    fprintf('Restrictions: known static upstream, common physical TLS sweep, detector noise OFF.\n');
    fprintf('Development and frozen testing must NEVER use the same sample seeds.\n');
    if cfg.v7c.save_results
        folder=cfg.v7c.output_dir;
        if ~exist(folder,'dir'),mkdir(folder);end
        if isfield(results,'development') && isfield(results,'frozen_test')
            name='V7c_development_and_frozen_results.mat';
        elseif isfield(results,'frozen_test')
            name='V7c_frozen_test_results.mat';
        elseif isfield(results,'development')
            name='V7c_development_results.mat';
        else
            name='V7c_conditions_results.mat';
        end
        save(fullfile(folder,name),'cfg','results','-v7.3');
        if isfield(results,'development')
            v7c_export_trials(folder,results.development,'V7c_DEVELOPMENT_trials.csv');
        end
        if isfield(results,'frozen_test')
            v7c_export_trials(folder,results.frozen_test,'V7c_FROZEN_TEST_trials.csv');
        end
        if isfield(results,'conditions')
            fid=fopen(fullfile(folder,'V7c_conditions.csv'),'w');
            if fid<0,error('V7c:CSV','conditions CSV 无法写入');end
            cleaner=onCleanup(@()fclose(fid));
            fprintf(fid,'name,family,n_valid,failures,affine_core,sapc_core,adaptive_core,gain,ci_lo,ci_hi,gate_rate,adaptive_valid\n');
            for k=1:results.conditions.n_groups
                p=results.conditions.specs(k);vals=results.conditions.summary(k,:);
                fprintf(fid,'%s,%s,',p.name,p.family);
                fprintf(fid,'%.12g,',vals(1:end-1));fprintf(fid,'%.12g\n',vals(end));
            end
            for k=1:results.conditions.n_groups
                rr=results.conditions.runs{k};
                if isstruct(rr)&&isfield(rr,'n_trials')
                    v7c_export_trials(folder,rr,sprintf('V7c_condition_%02d_trials.csv',k));
                end
            end
        end
    end
    if cfg.v7c.make_plots,v7c_plot_results(cfg,results);end
end
function print_summary(name,s)
    fprintf('\n========== V7c | %s =========\n',name);
    fprintf('Successful %d/%d | failures %d (%.2f%%) | non-affine accepted %.1f%%\n', ...
        s.n_success,s.total,s.failures,100*s.failure_rate,100*s.gate_rate);
    if s.n_success<1,return;end
    fprintf('Method         Oracle     Raw SSWT   Smoothed    Affine     SAPC     CV-SAPC\n');
    fprintf('Core RMSE(ue)  ');fprintf('  %.5f',s.mean_core);fprintf('\n');
    fprintf('Holdout RMS    ');fprintf('  %.5f',s.mean_holdout);fprintf('\n');
    for k=1:numel(s.comparisons)
        c=s.comparisons(k);
        fprintf('CV-SAPC vs %s: core gain %.6f ue [%.6f %.6f], wins %d, losses %d, worst regression %.6f ue\n', ...
            c.versus,c.core_gain_mean,c.core_gain_CI95,c.wins,c.losses,c.worst_regression);
        fprintf('    holdout gain %.6f ue [%.6f %.6f], validity gain %.3f pp\n', ...
            c.holdout_gain_mean,c.holdout_gain_CI95,100*c.valid_gain_mean);
    end
    fprintf('alpha [0 .25 .5 .75 1] counts: ');fprintf('%d ',s.selection_alpha_counts);fprintf('\n');
end
