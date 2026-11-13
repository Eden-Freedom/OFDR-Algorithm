function cfg=config_v6d()
%CONFIG_V6D V6d 配对误差分量消融：真值只参与诊断/评分，绝不作为新校正器。
    here=fileparts(mfilename('fullpath'));
    addpath(fullfile(fileparts(here),'v6c'));
    cfg=config_v6c();
    cfg.v6c.save_results=false;cfg.v6c.make_plots=false;cfg.v6c.run_mc=false;
    cfg.v6d.repeats=36;
    cfg.v6d.applied_microeps=5;
    cfg.v6d.scatter_stride=109;
    cfg.v6d.aux_stride=127;
    cfg.v6d.bootstrap_reps=2000;
    cfg.v6d.bootstrap_seed=20261113;
    cfg.v6d.save_results=true;
    cfg.v6d.make_plots=true;
    cfg.v6d.verbose=false;
    cfg.v6d.output_dir=fullfile(here,'output');
    cfg.v6d.minimum_common_valid=0.20;
end
