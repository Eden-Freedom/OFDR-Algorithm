function a=run_p1c_gauge_audit()
%RUN_P1C_GAUGE_AUDIT 只重算P1a已查看开发种子上的直接NUDFT Gauge核查。
% 不改旧P1/P2实验，不调用任何新独立种子或冻结测试。
    cfg=config_p1p2();
    p1p2_assert_protocol(cfg);
    a=p1c_gauge_nudft_audit(cfg);
    folder=fullfile(fileparts(mfilename('fullpath')),'output');
    if ~isfolder(folder),mkdir(folder);end
    save(fullfile(folder,'P1C_GAUGE_NUDFT_DEVELOPMENT.mat'),'cfg','a','-v7.3');
    T=table(a.core_gauge_ids,a.core_midpoint_m, ...
        a.direct_minus_nufft_phase_rad,a.direct_minus_nufft_strain_ue, ...
        'VariableNames',{'core_gauge_id','midpoint_m', ...
                         'direct_minus_nufft_phase_rad', ...
                         'direct_minus_nufft_strain_ue'});
    writetable(T,fullfile(folder,'P1C_GAUGE_NUDFT_DEVELOPMENT.csv'));
    fprintf('[P1c] saved MAT/CSV with full fixed-mask Gauge diagnostics.\n');
end