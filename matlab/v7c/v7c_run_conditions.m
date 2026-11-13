function r=v7c_run_conditions(cfg)
%V7C_RUN_CONDITIONS 独立种子物理条件预览：不可据此调本批冻测算法。
    specs=struct('name',{},'family',{},'value',{},'range',{});
    for v=[15 25 35]
        specs(end+1)=entry(sprintf('SNR_%g_dB',v),'snr',v,[]);
    end
    ranges=[0.55 0.98;0.62 0.85;0.78 1.02];
    for j=1:size(ranges,1)
        specs(end+1)=entry(sprintf('train_%.2f_%.2f',ranges(j,:)),'train',j,ranges(j,:));
    end
    for v=[0 1 5 10 20]
        specs(end+1)=entry(sprintf('strain_%g_ue',v),'strain',v,[]);
    end
    for v=[5 10 20]
        specs(end+1)=entry(sprintf('gauge_%g_mm',v),'gauge',v,[]);
    end
    r.specs=specs;r.runs=cell(numel(specs),1);r.summary=nan(numel(specs),10);
    r.n_groups=numel(specs);r.repeats=cfg.v7c.condition_repeats;
    for k=1:numel(specs)
        local=cfg;local.v7c.make_plots=false;local.v7c.save_results=false;
        s=specs(k);
        switch s.family
            case 'snr',local.v6.aux_snr_dB=s.value;
            case 'train',local.v7.train_static_m=s.range;
            case 'strain',local.v7.strain_microeps=s.value;
            case 'gauge',local.v6.gauge_length_m=s.value/1000;
        end
        % 开发与主盲测以外、每个条件完全不同的样本号。
        try
            rr=v7c_run_trials(local,local.v7c.condition_repeats,'development',k);
            r.runs{k}=rr;ss=rr.summary;
            if ss.n_success>0
                c=ss.comparisons(2);
                r.summary(k,:)=[ss.n_success,ss.failures,ss.mean_core(4),ss.mean_core(5), ...
                    ss.mean_core(6),c.core_gain_mean,c.core_gain_CI95, ...
                    ss.gate_rate,ss.mean_valid(6)];
            else
                r.summary(k,1:2)=[0 ss.failures];
            end
        catch ME
            r.runs{k}=struct('error',ME.message,'identifier',ME.identifier);
        end
        fprintf('[V7c cond] %2d/%2d %-20s accepted=%g/%d gain-affine=%.5f ue\n', ...
            k,numel(specs),s.name,r.summary(k,1),local.v7c.condition_repeats,r.summary(k,6));
    end
end
function x=entry(n,f,v,range)
    x=struct('name',n,'family',f,'value',v,'range',range);
end
