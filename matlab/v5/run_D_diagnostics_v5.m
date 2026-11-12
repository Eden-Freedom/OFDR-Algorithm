function D=run_D_diagnostics_v5(context)
%RUN_D_DIAGNOSTICS_V5 当前SSWT拍频与光频误差：积分、分段与权重分解。
% 补充边界、平滑、时延标定、拍频系统偏差的控制实验。
    cfg=context.cfg;
    D.experiment='D: SSWT integral/boundary/scale diagnostics';
    D.baseline=v5_beat_diagnostics(context,context.f_sswt_Hz);
    D.true_aux_delay_s=cfg.aux.delay_s;
    D.delay_error_ppm=cfg.v5.delay_error_ppm(:);
    D.delay_metrics=cell(numel(D.delay_error_ppm),1);
    for i=1:numel(D.delay_error_ppm)
        eta=D.delay_error_ppm(i)*1e-6;
        % 保持生成时的 delay 不变，仅恢复时引入参数误差。
        D.delay_metrics{i}=v5_beat_diagnostics(context,context.f_sswt_Hz,cfg.aux.delay_s*(1+eta));
    end
    D.beat_bias_Hz=cfg.v5.beat_bias_Hz(:);
    D.beat_bias_metrics=cell(numel(D.beat_bias_Hz),1);
    for i=1:numel(D.beat_bias_Hz)
        D.beat_bias_metrics{i}=v5_beat_diagnostics(context,context.f_sswt_Hz+D.beat_bias_Hz(i));
    end
    D.edge_smooth=cell(2,numel(cfg.v5.smooth_points));
    D.edge_smooth_status=cell(2,numel(cfg.v5.smooth_points));
    for edge=0:1
        for i=1:numel(cfg.v5.smooth_points)
            cc=cfg;cc.sswt.edge_extrapolate=logical(edge);
            cc.sswt.smooth_points=cfg.v5.smooth_points(i);
            try
                evalc('cx=v5_setup(cc,true);');
                D.edge_smooth{edge+1,i}=v5_beat_diagnostics(cx,cx.f_sswt_Hz);
                D.edge_smooth_status{edge+1,i}='ok';
            catch ME
                D.edge_smooth_status{edge+1,i}=ME.message;
            end
        end
    end
    fprintf('[D] baseline beat bias %.3f Hz | integrated offset %.4f MHz (endpoint)\n', ...
        D.baseline.beat_bias_Hz,D.baseline.q_error_Hz(end)/1e6);
end
