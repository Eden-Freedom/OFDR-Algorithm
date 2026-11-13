function [cfg,results]=main_v7b(cfg)
%MAIN_V7B 冻结 V7 SAPC 参数、全新种子盲测与失效机理（仅事后观察）。
% 入口只调用既有 V7 run_v7_trial；没有使用 oracle 光频拟合修正。
    here=fileparts(mfilename('fullpath'));
    addpath(fullfile(fileparts(here),'v7'));
    if nargin<1||isempty(cfg),cfg=config_v7b();end
    v7b_assert_frozen(cfg);
    results=struct();results.protocol_id=cfg.v7b.analysis_id;
    results.frozen_parameters=struct('regularization',cfg.v7.regularization, ...
        'iterations',cfg.v7.max_iterations,'basis','[x,x(1-x),sin(2pix),sin(4pix)]',...
        'smooth_points',cfg.v7.smooth_points,'phase_avg_bins',cfg.v6c.phase_avg_bins,...
        'training_stride',cfg.v7.training_stride,'max_correction_MHz',cfg.v7.max_correction_MHz);
    results.seed_policy='new disjoint blind seeds; independent scatterer and auxiliary noise per trial';
    t0=tic;
    if cfg.v7b.run_blind
        results.blind=v7b_run_trials(cfg,cfg.v7b.blind_repeats,0,'BLIND');
        results.blind_diagnostics=v7b_failure_diagnostics(results.blind);
    end
    if cfg.v7b.run_conditions
        results.conditions=v7b_run_conditions(cfg);
    end
    results.elapsed_s=toc(t0);
    if isfield(results,'blind')
        s=results.blind.summary;
        fprintf('\n========== V7b | FROZEN independent-seed blind validation =========\n');
        fprintf('Protocol %s | completed %d/%d | failures %d (%.1f%%)\n',...
            results.protocol_id,s.n_success,s.total,s.failures,100*s.failure_rate);
        if s.n_success>0
            for j=1:2
                c=s.comparisons(j);
                fprintf('SAPC vs %-6s: Core gain %.6f ue, 95%%CI [%.6f,%.6f], wins %d/%d, worst regression %.6f ue\n',...
                    c.versus,c.core_gain_mean,c.core_gain_CI95,c.wins,s.n_success,c.worst_regression);
                fprintf('                  Holdout gain %.6f ue, 95%%CI [%.6f,%.6f], Valid gain %.3f pp\n',...
                    c.holdout_gain_mean,c.holdout_gain_CI95,100*c.valid_gain_fraction_mean);
            end
            fprintf('Oracle/SSWT/Affine/SAPC core: %.4f / %.4f / %.4f / %.4f ue\n',...
                s.mean_core([1 2 4 5]));
        end
    end
    fprintf('NOTE: BLIND results must NEVER be reused to tune this frozen model; future models require fresh test seeds.\n');
    fprintf('Assumptions: known upstream static reference, same true TLS sweep, main detector noise OFF.\n');
    if cfg.v7b.save_results
        folder=cfg.v7b.output_dir;
        if ~exist(folder,'dir'),mkdir(folder);end
        save(fullfile(folder,'V7b_frozen_results.mat'),'cfg','results','-v7.3');
        if isfield(results,'blind')
            v7b_export_csv(folder,results.blind,'V7b_blind_trial_data.csv');
        end
        if isfield(results,'conditions')
            for j=1:results.conditions.n_conditions
                rr=results.conditions.runs{j};
                if ~isempty(rr)
                    v7b_export_csv(folder,rr,sprintf('V7b_condition_%02d.csv',j));
                end
            end
            f=fopen(fullfile(folder,'V7b_condition_summary.csv'),'w');
            if f<0,error('V7b:Save','无法写条件汇总CSV');end
            fprintf(f,'name,family,value,n_success,failures,affine_core,sapc_core,core_gain,ci_lo,ci_hi,sapc_holdout,sapc_valid_fraction\n');
            for j=1:results.conditions.n_conditions
                g=results.conditions.conditions(j);a=results.conditions.summary_table(j,:);
                fprintf(f,'%s,%s,%.9g,',g.name,g.family,g.value);
                fprintf(f,'%.9g,',a(1:end-1));fprintf(f,'%.9g\n',a(end));
            end
            fclose(f);
        end
    end
    if cfg.v7b.make_plots,v7b_plot_results(cfg,results);end
end
