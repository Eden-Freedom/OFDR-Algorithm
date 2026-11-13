function v7c_assert_protocol(cfg)
%V7C_ASSERT_PROTOCOL 校验核心算法参数锁定、空间隔离及种子不重叠。
    v7b_assert_frozen(cfg);
    baseline=config_v7c();
    keys={'cv_frac','cv_guard_m','min_validation_gauges', ...
        'min_training_gauges','alpha_grid','cv_required_relative_gain', ...
        'cv_required_absolute_rad','min_data_rcond', ...
        'max_extra_correction_MHz','dev_seed_base','test_seed_base', ...
        'scatter_stride','aux_stride','group_seed_stride'};
    for k=1:numel(keys)
        f=keys{k};
        if ~isequal(cfg.v7c.(f),baseline.v7c.(f))
            error('V7c:Frozen','V7c 冻结参数 %s 已被修改；新方法需新协议与测试种子。',f);
        end
    end
    if any(cfg.v7c.cv_frac(:)<0)||any(cfg.v7c.cv_frac(:)>1)|| ...
            any(cfg.v7c.cv_frac(:,2)<=cfg.v7c.cv_frac(:,1))
        error('V7c:CV','无效的静态训练段空间留出比例。');
    end
    if any(cfg.v7c.test_seed_base <= cfg.v7c.dev_seed_base)
        error('V7c:Seed','测试种子必须独立于开发集。');
    end
    allbases=[cfg.v7c.dev_seed_base(:);cfg.v7c.test_seed_base(:)];
    if max(allbases) + (max(cfg.v7c.development_repeats, ...
            cfg.v7c.frozen_test_repeats)-1)*max(cfg.v7c.scatter_stride,cfg.v7c.aux_stride) ...
            +20*cfg.v7c.group_seed_stride >= 2^32-1
        error('V7c:Seed','twister 种子超过有效范围。');
    end
end
