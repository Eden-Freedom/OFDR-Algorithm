function v7b_assert_frozen(cfg)
%V7B_ASSERT_FROZEN 避免盲测期间改变 SAPC/affine 的算法超参数。
% 参考段是预先定义的物理实验变量，可以在 conditions 中改变。
    checks={ 'smooth_points',81; 'regularization',2e-5; ...
             'finite_diff_MHz',0.50; 'max_correction_MHz',5; ...
             'max_iterations',4; 'training_stride',3; ...
             'min_train_gauges',30; 'min_condition_rcond',1e-10 };
    for k=1:size(checks,1)
        key=checks{k,1};expected=checks{k,2};
        if ~isfield(cfg.v7,key) || ~isequal(cfg.v7.(key),expected)
            error('V7b:FrozenParameter','V7b 冻结参数 %s 改变：不得在盲测结果上调参。',key);
        end
    end
    if cfg.v6c.phase_avg_bins~=9
        error('V7b:FrozenFilter','固定的 phase_avg_bins 必须为9');
    end
    if cfg.v7.train_static_m(1)>=cfg.v7.train_static_m(2) || ...
       cfg.v7.train_static_m(2)>=cfg.v6c.strain_start_m
        error('V7b:TrainingOverlap','上游静态训练段不能进入应变区');
    end
    if cfg.v7.test_static_m(1)<=cfg.v6c.strain_end_m || ...
       cfg.v7.test_static_m(1)>=cfg.v7.test_static_m(2)
        error('V7b:HoldoutOverlap','持出下游静态段设置无效');
    end
    if any(cfg.v7b.scatter_seed_base+(cfg.v7b.blind_repeats-1)*cfg.v7b.scatter_stride > 2^32-1)
        error('V7b:Seeds','随机种子超过 twister 可用范围');
    end
end
