function cfg=config_v7()
%CONFIG_V7 V7 非oracle静止参考段相位一致性校正（探索性原型）。
% 注意：本原型只适用于预先知道静止参考段、双扫描共带、扫描模型可观测的条件。
    here=fileparts(mfilename('fullpath'));
    addpath(fullfile(fileparts(here),'v6d'));
    cfg=config_v6d();cfg.v6d.save_results=false;cfg.v6d.make_plots=false;
    cfg.v7.output_dir=fullfile(here,'output');
    cfg.v7.save_results=true;cfg.v7.make_plots=true;
    cfg.v7.repeats=8;cfg.v7.strain_microeps=5;
    cfg.v7.scatter_stride=109;cfg.v7.aux_stride=127;
    cfg.v7.smooth_points=81;        % base MATLAB movmean, 只用辅助脊线
    cfg.v7.train_static_m=[0.55 0.98]; % 光纤上游预知不受应变，优化唯一可见的段
    cfg.v7.test_static_m=[1.78 2.23];  % 下游静态段只评分，绝不参与拟合
    cfg.v7.training_stride=3;
    cfg.v7.min_train_gauges=30;
    cfg.v7.finite_diff_MHz=0.50;
    cfg.v7.max_correction_MHz=5;
    cfg.v7.regularization=2e-5;    % rad^2 per MHz^2, 事先固定而非用应变真值调参
    cfg.v7.max_iterations=4;
    cfg.v7.min_condition_rcond=1e-10;
    cfg.v7.verbose=false;
    cfg.v7.bootstrap_reps=600;
    cfg.v7.bootstrap_seed=2607;
    cfg.v7.minimum_common_valid=0.20;
end
