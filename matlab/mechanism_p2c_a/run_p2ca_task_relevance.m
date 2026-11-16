function r=run_p2ca_task_relevance()
%RUN_P2CA_TASK_RELEVANCE 完成P2c-A2确定性反例并独立存盘、绘图。
% 绝不调用P2b/P1/Rayleigh随机仿真或冻结测试。
    cfg=config_p2c_a();
    p2ca_assert_protocol(cfg);
    r=p2ca_task_relevant_nullmode(cfg);
    if cfg.p2ca.save_results
        folder=cfg.p2ca.output_dir;
        if ~isfolder(folder),mkdir(folder);end
        save(fullfile(folder,'P2CA_TASK_RELEVANCE_MATH_ONLY.mat'),'cfg','r','-v7.3');
    end
    if cfg.p2ca.make_plots
        p2ca_plot_task_relevance(r);
    end
end