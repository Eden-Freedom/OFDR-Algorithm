function v6_export_metrics(cfg,results)
%V6_EXPORT_METRICS 无工具箱 CSV 导出：每个失败试次保留 NaN 和失败原因。
    p=fullfile(cfg.v6.output_dir,'V6a_case_metrics.csv');
    fid=fopen(p,'w');if fid<0,error('无法写入 CSV：%s',p);end
    fprintf(fid,['case,valid,coordinate_diff_rmse_MHz,gauge_phase_RMSE_rad,' ...
       'false_strain_RMSE_microeps,false_strain_bias_microeps,' ...
       'false_strain_P95abs_microeps,valid_fraction,near_wrap_count,failure_reason\n']);
    for j=1:numel(results.case_order)
        name=results.case_order{j};c=results.cases.(name);m=c.metrics;
        wrap=NaN;if isfield(m,'near_wrap_count'),wrap=m.near_wrap_count;end
        reason=strrep(c.failure_reason,'"','""');
        fprintf(fid,'%s,%d,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,"%s"\n', ...
           name,c.valid,c.diff_coordinate_rmse_MHz,m.gauge_phase_rmse_rad, ...
           m.false_strain_rmse_microeps,m.false_strain_bias_microeps, ...
           m.false_strain_p95_abs_microeps,m.valid_fraction,wrap,reason);
    end
    fclose(fid);
    p=fullfile(cfg.v6.output_dir,'V6a_correlation_metrics.csv');
    fid=fopen(p,'w');if fid<0,error('无法写入 CSV：%s',p);end
    fprintf(fid,'rho_target,rho_measured,diff_coord_RMSE_MHz,gauge_phase_RMSE_rad,false_strain_RMSE_microeps,valid_fraction\n');
    for j=1:numel(results.controlled.rho_target)
        rho=results.controlled.rho_target(j);
        name=sprintf('rho_%03d',round(rho*100));c=results.cases.(name);
        fprintf(fid,'%.8g,%.8g,%.12g,%.12g,%.12g,%.12g\n', ...
            rho,results.controlled.rho_empirical(j),c.diff_coordinate_rmse_MHz, ...
            c.metrics.gauge_phase_rmse_rad,c.metrics.false_strain_rmse_microeps,c.metrics.valid_fraction);
    end
    fclose(fid);
end
