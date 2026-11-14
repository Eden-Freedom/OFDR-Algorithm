function p1p2_assert_protocol(cfg)
%P1P2_ASSERT_PROTOCOL 锁住机制实验预定的核、种子与冻结模式。
    base=config_p1p2();
    if ~strcmp(cfg.p1p2.protocol,base.p1p2.protocol) || ...
       ~strcmp(cfg.p1p2.phase,'development') || cfg.p1p2.frozen_enabled
        error('P1P2:FrozenLocked','仅允许开发机理试次，禁止冻结运行。');
    end
    keys={'strain_microeps','scatter_seed_base','aux_ref_seed_base', ...
          'aux_meas_seed_base','scatter_stride','aux_stride', ...
          'p1_scat_levels','p1_strain_microeps', ...
          'min_common_roi_fraction','min_common_core','min_common_static'};
    for j=1:numel(keys)
        key=keys{j};
        if ~isequal(cfg.p1p2.(key),base.p1p2.(key))
            error('P1P2:ProtocolChanged','固定机制配置 %s 被修改；需另立协议。',key);
        end
    end
    if cfg.p1p2.repeats<1 || ...
       cfg.p1p2.repeats~=floor(cfg.p1p2.repeats)
        error('P1P2:TrialCount','开发试次数必须为正整数。');
    end
    if cfg.v6c.phase_avg_bins~=9 || cfg.v6.scatter_step_m~=0.0015 || ...
       cfg.v6c.group_photoelastic_factor~=base.v6c.group_photoelastic_factor || ...
       cfg.v3.window~=base.v3.window
        error('P1P2:PhysicalChanged','物理模型或重构窗口被改变，需新版本。');
    end
    seeds=[cfg.p1p2.scatter_seed_base cfg.p1p2.aux_ref_seed_base ...
           cfg.p1p2.aux_meas_seed_base];
    if any(seeds<=0)||any(seeds>=2^32)
        error('P1P2:InvalidSeed','种子必须处于twister允许范围。');
    end
end