function q=v7_smooth_aux(cfg,truth,cal)
%V7_SMOOTH_AUX 基线：对SSWT拍频额外平滑后积分，不利用真实光频。
    beat=movmean(cal.f_hat_Hz(:),cfg.v7.smooth_points);
    if any(~isfinite(beat)) || any(beat<=0)
        error('V7:Smooth','平滑后拍频非正/非有限');
    end
    q=cumtrapz(truth.t_s(:),beat)/cfg.aux.delay_s;
    q=q-q(1);
end
