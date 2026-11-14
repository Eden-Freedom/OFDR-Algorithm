function smoke_test_p1p2_math()
%SMOKE_TEST_P1P2_MATH 不涉及任何光学仿真的代数与软件门禁测试。
    eR=[1;4;6];eM=[3;8;9];
    ec=(eR+eM)/2;ed=eM-eR;
    assert(max(abs((ec-ed/2)-eR))<1e-14 && ...
           max(abs((ec+ed/2)-eM))<1e-14, ...
           'P1P2:DecompUnit','共模/差模无法重构原始误差。');
    M=[1 4 9 16];
    interaction=M(4)-M(2)-M(3)+M(1);
    assert(interaction==4,'P1P2:InteractionUnit','交互项符号错误。');
    cfg=config_p1p2();
    cfg.p1p2.frozen_enabled=true;
    lock=false;
    try
        p1p2_assert_protocol(cfg);
    catch ME
        lock=strcmp(ME.identifier,'P1P2:FrozenLocked');
    end
    assert(lock,'P1P2:FrozenUnit','冻结安全锁没有生效。');
    fprintf('[P1P2 algebra unit] PASS: ec/ed reconstruction, signed interaction, frozen lock.\n');
end