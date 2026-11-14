% Read-only reanalysis of already observed results. No fitting or new trials.
% Run from the repository root:
%   run('matlab/research_audit_20261114.m')
repo = fileparts(fileparts(mfilename('fullpath')));
S = load(fullfile(repo,'matlab','v7d','output','V7d_DEVELOPMENT_results.mat'));
cfg = S.cfg;
r = S.results.development;
assert(all(r.success) && numel(r.success)==24,'Expected the observed 24-trial development set.');
z = r.example.z(:);
N = numel(z);
roi = z>=cfg.v6.roi_m(1) & z<=cfg.v6.roi_m(2);
dz = median(diff(z));
lag = round(cfg.v6.gauge_length_m/dz);
L = lag*dz;
roiEndpoints = z-L/2>=cfg.v6.roi_m(1) & z+L/2<=cfg.v6.roi_m(2);
counts = r.common_valid_fraction(:)*N;
assert(max(abs(counts-round(counts)))<1e-7,'Common coverage must recover integer counts.');
exampleCommon = isfinite(r.example.strain{1});
assert(nnz(exampleCommon)==round(counts(1)),'Stored example must reproduce common count.');
assert(all(~exampleCommon | roi),'Common mask must lie inside the ROI.');
assert(all(abs(r.valid_fraction(:)*nnz(roi)-round(r.valid_fraction(:)*nnz(roi)))<1e-7), ...
    'Individual validity must use the ROI midpoint denominator.');
out = struct();
out.scope = 'Post-hoc reanalysis of previously observed development data; no new algorithm validation.';
out.coverage.total_grid_gauges=N;
out.coverage.roi_midpoint_gauges=nnz(roi);
out.coverage.roi_endpoint_gauges=nnz(roiEndpoints);
out.coverage.dz_mm=dz*1e3;
out.coverage.actual_gauge_mm=L*1e3;
out.coverage.boxcar_endpoint_support_mm=(lag+cfg.v6c.phase_avg_bins-1)*dz*1e3;
out.coverage.reported_common_full_grid=mean(r.common_valid_fraction);
out.coverage.common_roi_midpoint=mean(counts)/nnz(roi);
out.coverage.common_roi_endpoints=mean(counts)/nnz(roiEndpoints);
out.coverage.mean_individual_roi_midpoint=mean(r.valid_fraction,1);
out.coverage.mean_common_count=mean(counts);
out.coverage.example_common_count=nnz(exampleCommon);
out.coverage.extra_loss_vs_affine_pp=100*(mean(r.valid_fraction(:,4))-out.coverage.common_roi_midpoint);
out.v7d.mean_core=mean(r.core_rmse,1);
out.v7d.mean_holdout=mean(r.holdout_rmse,1);
out.v7d.max_core_c_d_difference=max(abs(r.core_rmse(:,6)-r.core_rmse(:,7)));
out.v7d.max_holdout_c_d_difference=max(abs(r.holdout_rmse(:,6)-r.holdout_rmse(:,7)));
out.v7d.exposed=sum(r.full_extra_peak_MHz>0.8);
out.v7d.exposure_zero_event_upper95_one_sided=1-0.05^(1/24);
out.v7d.full_candidates_removed_in_folds=find(sum(r.fold_candidate_ok(:,2:end),2)<4).';
A=r.core_rmse(:,4); F=r.core_rmse(:,5); G=r.core_rmse(:,7);
accepted=r.alpha_v7d>0;
tol=1e-12;
out.v7d.accepted=sum(accepted);
out.v7d.accepted_better_than_affine=sum(accepted & G<A-tol);
out.v7d.accepted_worse_than_affine=sum(accepted & G>A+tol);
out.v7d.rejected_full_would_be_better=sum(~accepted & F<A-tol);
out.v7d.rejected_full_would_be_worse=sum(~accepted & F>A+tol);
out.v7d.full_better_count=sum(F<A-tol);
out.v7d.full_worse_count=sum(F>A+tol);
out.v7d.affine_minus_full_mean=mean(A-F);
out.v7d.affine_minus_gate_mean=mean(A-G);
out.v7d.perfect_information_binary_selector_mean=mean(min(A,F));
out.v7d.binary_selector_gain_vs_affine=mean(A-min(A,F));
out.v7d.binary_selector_regret_of_gate=mean(G-min(A,F));
out.v7d.elapsed_s=r.elapsed_s;
out.v7d.mean_core_bias=mean(r.core_bias,1);
out.v7d.mean_squared_core_rmse=mean(r.core_rmse.^2,1);
S6=load(fullfile(repo,'matlab','v6c','output','V6c_nonzero_strain.mat'));
r6=S6.results;
order={'oracle','common_sswt','independent_sswt'};
fixedCore=true(size(r6.strain_tests{1}.trial.cases.oracle.metrics.core_valid));
for t=1:numel(r6.strain_tests)
    for k=1:3
        met=r6.strain_tests{t}.trial.cases.(order{k}).metrics;
        fixedCore=fixedCore & met.core_valid;
    end
end
assert(nnz(fixedCore)>15,'Insufficient common core for descriptive V6c comparison.');
out.v6c.scope='One previously observed scatter/aux realization; fixed core across all 6 strain levels and 3 methods.';
out.v6c.methods=order;
out.v6c.strain_microeps=r6.strain_sweep_microeps;
out.v6c.fixed_core_count=nnz(fixedCore);
out.v6c.core_rmse=zeros(numel(r6.strain_tests),3);
out.v6c.raw_core_rmse=zeros(numel(r6.strain_tests),3);
for t=1:numel(r6.strain_tests)
    for k=1:3
        met=r6.strain_tests{t}.trial.cases.(order{k}).metrics;
        out.v6c.core_rmse(t,k)=sqrt(mean(met.strain_error_microeps(fixedCore).^2));
        out.v6c.raw_core_rmse(t,k)=sqrt(mean(met.raw_strain_error_microeps(fixedCore).^2));
    end
end
S6d=load(fullfile(repo,'matlab','v6d','output','V6d_component_ablation.mat'));
out.v6d.n=sum(S6d.results.trial_success);
out.v6d.labels=S6d.results.labels;
out.v6d.mean_core=mean(S6d.results.core_rmse(S6d.results.trial_success,:),1);
out.v6d.mean_static=mean(S6d.results.static_rmse(S6d.results.trial_success,:),1);
out.v6d.full_minus_no_diff_core=out.v6d.mean_core(4)-out.v6d.mean_core(1);
out.v6d.full_minus_no_diff_static=out.v6d.mean_static(4)-out.v6d.mean_static(1);
out.checks_passed={'integer common counts','example mask match','common inside ROI', ...
    'integer individual counts with ROI denominator','fixed V6c core across methods and strains'};
target=fullfile(repo,'docs','research-audit-2026-11-14.json');
fid=fopen(target,'w','n','UTF-8');
assert(fid>=0,'Cannot open audit output.');
fwrite(fid,jsonencode(out,PrettyPrint=true),'char');
fclose(fid);
fig=figure('Visible','off','Color','w','Position',[100 100 1180 450]);
tiledlayout(fig,1,2,'Padding','compact','TileSpacing','compact');
nexttile;
bar([out.v6d.mean_core([4 1]);out.v6d.mean_static([4 1])]);
set(gca,'XTickLabel',{'Strained core','Static region'},'FontSize',11);
ylabel('Mean trial RMSE (microstrain)');
legend({'Independent coordinates','Same reference coordinates'}, ...
    'Location','southoutside','Orientation','horizontal','FontSize',9);
title({'V6d: 36 paired trials','Same coordinates leave substantial core error'});
grid on;
nexttile;
plot(out.v6c.strain_microeps,out.v6c.core_rmse,'-o','LineWidth',1.5);
xlabel('Applied strain (microstrain)');
ylabel('Core RMSE (microstrain)');
legend({'Oracle','Common SSWT','Independent SSWT'}, ...
    'Location','southoutside','Orientation','horizontal','FontSize',9);
title({'V6c: one existing realization','500 fixed core gauges across all methods and strains'});
set(gca,'FontSize',11);grid on;
exportgraphics(fig,fullfile(repo,'docs','research-audit-2026-11-14.png'),'Resolution',180);
close(fig);
disp(jsonencode(out,PrettyPrint=true));
fprintf('READ_ONLY_REANALYSIS_COMPLETE\n');
