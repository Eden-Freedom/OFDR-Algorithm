function pair = v6c_forward_pair(cfg,truth,applied_microeps,source)
%V6C_FORWARD_PAIR 物理配对信号：相同 Rayleigh 系数，测量扫描真的改变光路。
% 参考 s_r(t)=Re{sum a_j exp(i*2*pi*tau_j*q_true(t))}
% 测量 s_m(t)=Re{sum a_j exp(i*phi_strain(z_j))*exp(i*2*pi*(tau_j+dtau_j)*q_true(t))}
% 注意：相位由绝对载波(1550 nm)变化产生，不能仅用相对扫频 q 代替。
% 假设两次真实 TLS 扫频相同、主探测噪声关闭；适合隔离校准误差。
    if nargin<4||isempty(source)
        [s_ref,scatter]=v6_rayleigh_signal(cfg,truth);
        source=struct('ref_signal',s_ref,'scatter',scatter);
    end
    scatter=source.scatter;
    geom=v6c_strain_geometry(cfg,scatter.z_m,applied_microeps);
    tau=scatter.delay_s(:)+geom.delta_group_delay_s(:);
    if max(truth.tuning_rate_Hz_s)*max(tau)>=truth.fs_Hz/2
        error('V6c:Aliasing','受应变光纤最远端拍频达到 Nyquist。');
    end
    a=scatter.coeff(:).*exp(1i*geom.phase_carrier_rad(:));
    q=truth.nu_offset_Hz(:);
    measured=zeros(truth.N,1);
    b=cfg.v6c.forward_block_size;
    if b<1||b~=floor(b),error('V6c:Block','forward_block_size 必须正整数');end
    for j=1:b:numel(tau)
        ind=j:min(numel(tau),j+b-1);
        measured=measured+real(exp(1i*2*pi*(q*tau(ind).'))*a(ind));
    end
    pair.reference_signal=source.ref_signal(:);
    pair.measurement_signal=measured;
    pair.scatter=scatter;
    pair.geometry=geom;
    pair.applied_microeps=applied_microeps;
    pair.same_scatterers=true;
    pair.main_noise_enabled=false;
    pair.true_sweep_shared=true;
end
