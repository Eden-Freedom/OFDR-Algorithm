function z=v5_fine_grid(cfg,z_center,step)
% 细网格中心包含给定真反射位置；所有对照使用相同绝对距离轴。
    half=cfg.v5.fine_halfwidth_m;
    M=round(half/step);
    z=z_center + (-M:M)'*step;
end
