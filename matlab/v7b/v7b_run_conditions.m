function r=v7b_run_conditions(cfg)
%V7B_RUN_CONDITIONS 事先声明的物理变量扫描；各组使用独立种子，组内严格配对。
% 本函数不修改 SAPC 超参数；每个条件还需报告失败率和有效位置率。
    v7b_assert_frozen(cfg);
    groups=struct('name',{},'family',{},'value',{},'range_m',{});
    for v=cfg.v7b.conditions_snr_dB
        groups(end+1)=entry(sprintf('SNR_%g_dB',v),'aux_snr_dB',v,[]);
    end
    for j=1:size(cfg.v7b.conditions_train_ranges_m,1)
        z=cfg.v7b.conditions_train_ranges_m(j,:);
        groups(end+1)=entry(sprintf('static_%.2f_%.2f_m',z),'train_range',j,z);
    end
    for v=cfg.v7b.conditions_strain_microeps
        groups(end+1)=entry(sprintf('strain_%g_ue',v),'strain_microeps',v,[]);
    end
    for v=cfg.v7b.conditions_gauge_mm
        groups(end+1)=entry(sprintf('gauge_%g_mm',v),'gauge_mm',v,[]);
    end
    for v=cfg.v7b.conditions_ripple_a
        groups(end+1)=entry(sprintf('ripple_%.3f',v),'ripple_a',v,[]);
    end
    r.conditions=groups;r.runs=cell(numel(groups),1);
    r.n_conditions=numel(groups);r.requested_repeats=cfg.v7b.condition_repeats;
    r.failed_conditions={};r.summary_table=nan(numel(groups),9);
    for k=1:numel(groups)
        local=cfg;local.v7b.make_plots=false;local.v7b.save_results=false;
        switch groups(k).family
            case 'aux_snr_dB'
                local.v6.aux_snr_dB=groups(k).value;
            case 'train_range'
                local.v7.train_static_m=groups(k).range_m;
            case 'strain_microeps'
                local.v7.strain_microeps=groups(k).value;
            case 'gauge_mm'
                local.v6.gauge_length_m=groups(k).value/1000;
            case 'ripple_a'
                local.laser.ripple_a=groups(k).value;
        end
        try
            run=v7b_run_trials(local,cfg.v7b.condition_repeats,k,groups(k).name);
            r.runs{k}=run;
            ss=run.summary;
            if ss.n_success>0
                b=ss.comparisons(2);r.summary_table(k,:)=[ss.n_success,ss.failures, ...
                    ss.mean_core(4),ss.mean_core(5),b.core_gain_mean, ...
                    b.core_gain_CI95,ss.mean_holdout(5),ss.mean_valid(5)];
            else
                r.summary_table(k,1:2)=[0,ss.failures];
            end
        catch ME
            r.failed_conditions{end+1}=sprintf('%s: %s',groups(k).name,ME.message);
        end
        fprintf('[V7b sweep] %2d/%2d %-22s valid=%d/%d gain-affine=%.5f ue\n',...
            k,numel(groups),groups(k).name,r.summary_table(k,1),...
            cfg.v7b.condition_repeats,r.summary_table(k,5));
    end
    % 不对跨组数值求均值作为方法的平均提升：不同物理条件不能混成同分布样本。
end
function x=entry(name,family,value,range_m)
    x=struct('name',name,'family',family,'value',value,'range_m',range_m);
end
