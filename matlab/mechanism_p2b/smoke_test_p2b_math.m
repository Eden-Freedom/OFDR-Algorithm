function smoke_test_p2b_math()
%SMOKE_TEST_P2B_MATH 纯合成线性响应核验方向导数预测，不消耗任何光学种子。
    r0=[.3;-.2;.1;-.1];
    g=[.05;-.03;.02;.01];
    for alpha=[.5 1]
        h=.05;
        fminus=-h*g;fplus=h*g;
        o=p2b_predict_local(r0,fminus,fplus,h,alpha);
        pred=mean((r0+alpha*g).^2)-mean(r0.^2);
        assert(abs(o.C_pred-pred)<1e-13, ...
            'P2B:MathPrediction','线性响应下平方误差预测恒等式不成立。');
        assert(abs(o.C_pred-o.linear_term-o.quadratic_term)<1e-13, ...
            'P2B:MathDecomp','线性/二次项计算不一致。');
    end
    cfg=config_p2b();
    cfg.p2b.frozen_enabled=true;
    locked=false;
    try
        p2b_assert_protocol(cfg);
    catch ME
        locked=strcmp(ME.identifier,'P2B:FrozenLocked');
    end
    assert(locked,'P2B:FrozenUnit','冻结安全锁无效。');
    cfg=config_p2b();
    cfg.p2b.test_alpha=[.25 .5];
    locked=false;
    try
        p2b_assert_protocol(cfg);
    catch ME
        locked=strcmp(ME.identifier,'P2B:ProtocolChanged');
    end
    assert(locked,'P2B:AlphaUnit','预设测试α被修改时必须报错。');
    fprintf('[P2b math unit] PASS: directional derivative, squared error, protocol and frozen locks.\n');
end