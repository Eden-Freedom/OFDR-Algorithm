function v7d_assert_protocol(cfg)
%V7D_ASSERT_PROTOCOL 防止开发期误触盲测或暗改原始V7c参数。
    v7c_assert_protocol(cfg);
    base=config_v7d();
    keys={'alpha_grid','max_extra_correction_MHz','max_total_correction_MHz', ...
          'cv_required_relative_gain','cv_required_absolute_rad', ...
          'min_data_rcond','dev_seed_base','test_seed_base', ...
          'scatter_stride','aux_stride','bootstrap_seed'};
    for k=1:numel(keys)
        f=keys{k};
        if ~isequal(cfg.v7d.(f),base.v7d.(f))
            error('V7d:ProtocolChange','V7d开发预设配置 %s 已改变，须更新版本与协议。',f);
        end
    end
    if ~strcmp(cfg.v7d.protocol_id,base.v7d.protocol_id)
        error('V7d:ProtocolID','协议ID不一致。');
    end
    if cfg.v7d.run_frozen_test || cfg.v7d.allow_frozen_test
        error('V7d:FrozenLocked', ...
           '当前仅允许开发集；V7d冻结集需独立审核后另行解锁，禁止直接运行。');
    end
    if any(cfg.v7d.dev_seed_base==cfg.v7c.dev_seed_base) || ...
       any(cfg.v7d.test_seed_base==cfg.v7c.test_seed_base)
        error('V7d:Seeds','发现与V7c种子重合。');
    end
    if cfg.v7d.development_repeats<1 || ...
       cfg.v7d.development_repeats~=floor(cfg.v7d.development_repeats)
        error('V7d:Repeats','development_repeats必须为正整数。');
    end
    if max(cfg.v7d.test_seed_base)+(cfg.v7d.frozen_test_repeats-1)* ...
            max(cfg.v7d.scatter_stride,cfg.v7d.aux_stride)>=2^32-1
        error('V7d:SeedRange','twister种子超范围。');
    end
end
