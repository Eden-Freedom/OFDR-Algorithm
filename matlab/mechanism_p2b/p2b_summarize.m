function s=p2b_summarize(r,cfg)
%P2B_SUMMARIZE 对每个完整trial的预测-实际共模MSE对比作配对统计。
% 不将同一散射体下的多个应变/Gauge视为独立随机重复。
    good=logical(r.success(:));
    K=numel(r.strains_microeps);
    A=numel(r.test_alpha);
    s=struct;
    s.n_total=r.n_trials;
    s.n_success=nnz(good);
    s.n_failure=s.n_total-s.n_success;
    s.failure_rate=s.n_failure/max(s.n_total,1);
    s.strains_microeps=r.strains_microeps;
    s.test_alpha=r.test_alpha;
    s.mean_C_actual=nan(K,A);
    s.mean_C_pred=nan(K,A);
    s.mean_signed_error=nan(K,A);
    s.mean_abs_error=nan(K,A);
    s.worst_abs_error=nan(K,A);
    s.prediction_error_CI95=nan(K,A,2);
    s.actual_C_CI95=nan(K,A,2);
    s.sign_agreement=nan(K,A);
    s.n_sign_agree=zeros(K,A);
    s.n_nonzero_actual=zeros(K,A);
    s.mean_gradient_rms=nan(K,1);
    s.mean_gradient_h_difference=nan(K,1);
    s.mean_gradient_h_relative=nan(K,1);
    s.mean_baseline_MSE=nan(K,1);
    s.mean_common_valid_fraction=NaN;
    s.mean_common_core_count=NaN;
    s.mean_ec_rms_MHz=NaN;
    if ~any(good),return;end
    s.mean_common_valid_fraction=mean(r.common_valid_fraction(good));
    s.mean_common_core_count=mean(r.common_core_count(good));
    s.mean_ec_rms_MHz=mean(r.ec_rms_MHz(good));
    for j=1:K
        gr=r.gradient_rms(good,j);
        hd=r.gradient_h_difference(good,j);
        s.mean_gradient_rms(j)=mean(gr);
        s.mean_gradient_h_difference(j)=mean(hd);
        s.mean_gradient_h_relative(j)=mean(hd./max(gr,1e-12));
        s.mean_baseline_MSE(j)=mean(r.baseline_MSE(good,j));
        for v=1:A
            ca=reshape(r.C_actual(good,j,v),[],1);
            cp=reshape(r.C_pred(good,j,v),[],1);
            residual=ca-cp;
            s.mean_C_actual(j,v)=mean(ca);
            s.mean_C_pred(j,v)=mean(cp);
            s.mean_signed_error(j,v)=mean(residual);
            s.mean_abs_error(j,v)=mean(abs(residual));
            s.worst_abs_error(j,v)=max(abs(residual));
            % 对实际C=0的trial，不使用符号预测准确率而单独报告。
            use=abs(ca)>1e-12;
            s.n_nonzero_actual(j,v)=nnz(use);
            s.n_sign_agree(j,v)=nnz(sign(ca(use))==sign(cp(use)));
            if any(use)
                s.sign_agreement(j,v)=s.n_sign_agree(j,v)/nnz(use);
            end
            if nnz(good)>=2
                [lo,hi]=v6b_bootstrap_ci(residual,cfg.p2b.bootstrap_reps, ...
                    cfg.p2b.bootstrap_seed+1000*j+19*v);
                s.prediction_error_CI95(j,v,:)=reshape([lo,hi],1,1,2);
                [lo,hi]=v6b_bootstrap_ci(ca,cfg.p2b.bootstrap_reps, ...
                    cfg.p2b.bootstrap_seed+2000*j+23*v);
                s.actual_C_CI95(j,v,:)=reshape([lo,hi],1,1,2);
            end
        end
    end
end