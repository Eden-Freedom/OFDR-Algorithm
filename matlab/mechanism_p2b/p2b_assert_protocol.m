function p2b_assert_protocol(cfg)
%P2B_ASSERT_PROTOCOL 保护物理模型/开发种子，拒绝冻结及参数事后改动。
% 允许减少开发试次数用于smoke；只允许预先固定的应变/步长/alpha与种子。
    base=config_p2b();
    if ~isfield(cfg,'p2b') || ~strcmp(cfg.p2b.phase,'development') || ...
       cfg.p2b.frozen_enabled || cfg.p2b.run_frozen_test || ...
       cfg.p2b.allow_frozen_test || ...
       ~strcmp(cfg.p2b.protocol_id,base.p2b.protocol_id)
        error('P2B:FrozenLocked','P2b仅能运行当前开发机制协议，冻结测试被锁定。');
    end
    keys={'strain_microeps','alpha_grid','primary_h','secondary_h', ...
          'test_alpha','scatter_seed_base','aux_ref_seed_base', ...
          'aux_meas_seed_base','scatter_stride','aux_stride', ...
          'min_common_core','min_common_static','min_common_roi_fraction'};
    for j=1:numel(keys)
        k=keys{j};
        if ~isequal(cfg.p2b.(k),base.p2b.(k))
            error('P2B:ProtocolChanged','关键字段 %s 被改动，须另立研究协议。',k);
        end
    end
    if cfg.p2b.development_repeats<1 || ...
       floor(cfg.p2b.development_repeats)~=cfg.p2b.development_repeats
        error('P2B:Repeats','试次数须为正整数。');
    end
    p1p2_assert_protocol(cfg);
    % 保留配置层物理假设，避免直接更改真实扫频或Gauge处理。
    fields={'fut','v3','v6','v6c'};
    for j=1:numel(fields)
        field=fields{j};
        if ~isequaln(cfg.(field),base.(field))
            error('P2B:PhysicalChanged','基础物理/重构配置 %s 已改变。',field);
        end
    end
end