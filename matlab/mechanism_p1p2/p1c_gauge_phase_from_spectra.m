function [phi,phi_raw]=p1c_gauge_phase_from_spectra(ref,meas,lag,w,ids)
%P1C_GAUGE_PHASE_FROM_SPECTRA 复制V6c原有Gauge相位定义，不改数值核。
% 与v6c_demodulate_strain完全相同的复phasor、conv(...,'same')和angle。
% 输入ref/meas：同一距离网格上的复数光纤空间迹线；
% lag：Gauge端点间隔（bin）；w：奇数复平均宽度；ids：要读取的Gauge索引。
    ref=ref(:);meas=meas(:);ids=ids(:);
    if numel(ref)~=numel(meas)||numel(ref)<=lag|| ...
       any(ids<1)||any(ids>numel(ref)-lag)||any(ids~=floor(ids))|| ...
       mod(w,2)~=1||w<1
        error('P1C:PhaseInput','Gauge复谱尺寸、索引或窗口不合法。');
    end
    I=(1:numel(ref)-lag).';J=I+lag;
    C=meas.*conj(ref);
    phasor=C(J).*conj(C(I));
    phi_raw=angle(phasor(ids));
    if w>1
        phasor=conv(phasor,ones(w,1)/w,'same');
    end
    phi=angle(phasor(ids));
end