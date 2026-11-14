function smoke_test_p2c_a_math()
%SMOKE_TEST_P2C_A_MATH 无随机数的数学单元测试；检验时延积分算子。
    N=16;dt=1e-6;m=4;
    [A,t]=p2ca_integral_matrix(N,dt,m*dt);
    assert(isequal(size(A),[N-m+1,N]), ...
        'P2CA:UnitShape','完整延迟窗口数错误。');
    assert(max(abs(sum(A,2)-m))<1e-10, ...
        'P2CA:UnitConstant','常频率应产生2πτν的相位。');
    for j=1:N-m+1
        expected=zeros(1,N);expected(j:j+m-1)=1;
        assert(max(abs(A(j,:)-expected))<1e-10, ...
            'P2CA:UnitKernel','整数延迟积分窗不等于m点滚动和。');
    end
    assert(max(abs(t-(m:N).'*dt))<1e-10, ...
        'P2CA:UnitClock','观测时间网格不正确。');
    [B,~]=p2ca_integral_matrix(N,dt,3.5*dt);
    assert(max(abs(sum(B,2)-3.5))<1e-10 && ...
           all(B(:)>=-1e-10), ...
           'P2CA:UnitFractional','非整数延迟分段积分错误。');
    s=p2ca_numerical_rank(A);
    assert(s.rank==N-m+1 && s.nullity==m-1, ...
        'P2CA:UnitRank','秩/核空间维度错误。');
    blind=sin(2*pi*(0:N-1)'/m);
    assert(norm(A*blind)<1e-10, ...
        'P2CA:UnitBlind','零均值周期盲方向应被积分消去。');
    locked=false;
    cfg=config_p2c_a();
    cfg.p2ca.frozen_enabled=true;
    try
        p2ca_assert_protocol(cfg);
    catch ME
        locked=strcmp(ME.identifier,'P2CA:FrozenLocked');
    end
    assert(locked,'P2CA:UnitFrozen','冻结锁未触发。');
    % 只运行默认确定性数学审计，不保存、不绘图、不占用随机种子。
    cfg=config_p2c_a();
    cfg.p2ca.make_plots=false;cfg.p2ca.save_results=false;
    rng0=rng;
    [~,r]=main_p2c_a(cfg);
    assert(isequal(rng0,rng),'P2CA:UnitRng','数学审计不应使用MATLAB随机数。');
    assert(r.rank_two_known_offsets.rank==cfg.p2ca.n_frequency_bins && ...
           r.rank_two_unknown_offsets.nullity==1, ...
           'P2CA:UnitTwoDelay','双延迟辨识维度错误。');
    fprintf('[P2c-A math unit] PASS: integer/fractional windows, rank, blind mode, offset/delay ambiguity and frozen lock.\n');
end