function geom = v6c_strain_geometry(cfg,z_scatter_m,applied_microeps)
%V6C_STRAIN_GEOMETRY 从轴向应变 ε(z) 积分得到位移 u(z)，构造相位与时延。
% 真实应变 ε 定义在*未形变*材料坐标 z；应变分布由两端 raised-cosine 平滑过渡。
% 载波相位: phi(z)=4*pi*n_eff*(1-p_e)*u(z)/lambda0
% 群时延改变量: dtau(z)=2*n_g*beta_g*u(z)/c (beta_g 为独立可调近似)。
    if ~isscalar(applied_microeps)||~isfinite(applied_microeps)
        error('V6c:InvalidStrain','应用应变必须为有限标量（με）。');
    end
    z=z_scatter_m(:);
    z1=cfg.v6c.strain_start_m;z2=cfg.v6c.strain_end_m;
    ramp=cfg.v6c.transition_m;step=cfg.v6c.integration_step_m;
    if z1<=0||z2<=z1||ramp<=0||2*ramp>=z2-z1||step<=0
        error('V6c:InvalidGeometry','应变区域、缓变段和积分步长不合理。');
    end
    zmax=max([z(:);cfg.v6.roi_m(:);z2])+2*cfg.v6.gauge_length_m;
    n=ceil(zmax/step)+1;
    zg=linspace(0,zmax,n).';
    t=ones(size(zg));
    left=(zg>=z1)&(zg<z1+ramp);
    right=(zg>z2-ramp)&(zg<=z2);
    t(zg<z1 | zg>z2)=0;
    t(left)=0.5-0.5*cos(pi*(zg(left)-z1)/ramp);
    t(right)=0.5-0.5*cos(pi*(z2-zg(right))/ramp);
    epsg=applied_microeps*1e-6*t;
    ug=cumtrapz(zg,epsg);
    u_s=interp1(zg,ug,z,'linear');
    if any(~isfinite(u_s)),error('V6c:IntegrationGrid','散射点超出应变积分网格');end
    n_eff=cfg.v6.phase_index;
    pe=cfg.v6.photoelastic_p;
    c=cfg.const.c_m_s;
    lambda=cfg.v6.lambda_ref_m;
    if n_eff<=0 || pe<0 || pe>=1 || cfg.v6c.group_photoelastic_factor<=0
        error('V6c:Material','相折射率或弹光系数无效。');
    end
    geom.z_grid_m=zg;
    geom.strain_grid=epsg;
    geom.strain_microeps=epsg*1e6;
    geom.displacement_grid_m=ug;
    geom.z_scatter_m=z;
    geom.displacement_scatter_m=u_s;
    geom.phase_carrier_rad=4*pi*n_eff*(1-pe)*u_s/lambda;
    geom.delta_group_delay_s=2*cfg.fut.group_index* ...
        cfg.v6c.group_photoelastic_factor*u_s/c;
    geom.applied_microeps=applied_microeps;
    geom.model='small axial strain; phase index vs group index treated separately';
end
