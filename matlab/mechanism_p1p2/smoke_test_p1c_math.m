function smoke_test_p1c_math()
%SMOKE_TEST_P1C_MATH 纯合成复光谱验证索引并集、9-bin卷积与同掩码结果。
% 不模拟OFDR、不读取真实扫频、不消耗开发/冻结种子。
    n=200;lag=9;w=9;
    ids=[1;2;13;77;180;191]; % 包含Gauge数组两端，验证conv 'same'边界
    k=(0:n-1).';
    R=(1+.2*sin(k*.1)).*exp(1i*.03*k);
    M=(1+.1*cos(k*.07)).*R.*exp(1i*(.12*sin(k*.13)+.001*k));
    [neighbor,sites]=p1c_required_sites(ids,n,lag,w);
    assert(all(ismember(ids,neighbor)) && all(sites>=1 & sites<=n), ...
        'P1C:SitesUnit','所需Gauge邻域或频谱bin未被正确包含。');
    [phiFull,rawFull]=p1c_gauge_phase_from_spectra(R,M,lag,w,ids);
    Rs=complex(zeros(n,1));Ms=complex(zeros(n,1));
    Rs(sites)=R(sites);Ms(sites)=M(sites);
    [phiSparse,rawSparse]=p1c_gauge_phase_from_spectra(Rs,Ms,lag,w,ids);
    d=angle(exp(1i*(phiSparse-phiFull)));
    dr=angle(exp(1i*(rawSparse-rawFull)));
    assert(max(abs(d))<1e-12 && max(abs(dr))<1e-12, ...
        'P1C:SparseUnit','9-bin稀疏并集未复现完整复谱的Gauge相位。');
    [phiSelf,rawSelf]=p1c_gauge_phase_from_spectra(R,R,lag,w,ids);
    assert(max(abs(phiSelf))<1e-12 && max(abs(rawSelf))<1e-12, ...
        'P1C:SameTraceUnit','相同参考/测量复谱的Gauge相位应该为零。');
    rejected=false;
    try
        p1c_required_sites(201,n,lag,w);
    catch ME
        rejected=strcmp(ME.identifier,'P1C:CoreIDs');
    end
    assert(rejected,'P1C:InvalidSiteUnit','越界Gauge未被拒绝。');
    fprintf('[P1c gauge math unit] PASS: sparse bin union, 9-bin conv, equal-trace and bounds.\n');
end