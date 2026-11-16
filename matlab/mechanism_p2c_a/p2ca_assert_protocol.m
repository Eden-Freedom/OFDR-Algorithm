function p2ca_assert_protocol(cfg)
%P2CA_ASSERT_PROTOCOL 仅允许预设的纯数学审计；冻结开关禁用。
    baseline=config_p2c_a();
    if ~isfield(cfg,'p2ca') || ~isfield(cfg.p2ca,'frozen_enabled') || ...
       cfg.p2ca.frozen_enabled || ...
       ~isfield(cfg.p2ca,'dataset') || ...
       ~strcmp(cfg.p2ca.dataset,'math_only')
        error('P2CA:FrozenLocked','只允许理想数学示例，拒绝冻结测试。');
    end
    frozen_fields={'name','n_frequency_bins','dt_s','delay_1_bins', ...
                   'delay_2_bins','offset_phase_rad'};
    for k=1:numel(frozen_fields)
        f=frozen_fields{k};
        if ~isfield(cfg.p2ca,f)||~isequal(cfg.p2ca.(f),baseline.p2ca.(f))
            error('P2CA:ProtocolChanged','固定数学协议参数 %s 已被改变。',f);
        end
    end
end