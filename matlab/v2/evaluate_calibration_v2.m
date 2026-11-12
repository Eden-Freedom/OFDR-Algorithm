function metrics = evaluate_calibration_v2(truth, signals, calibrations, elapsed_s, cwt, sswt)
%EVALUATE_CALIBRATION_V2 分开评价瞬时拍频、累积光频和波长误差。
% RMSE(f) 在去掉前后 5% 边界后计算，以避免时频变换边界误差掩盖主体。
% 光频/波长 RMSE 在全程计算，因为积分在起点锚定后会积累误差。
    t=truth.t_s;
    keep=t>=t(1)+0.05*(t(end)-t(1)) & ...
         t<=t(1)+0.95*(t(end)-t(1));
    f_true=signals.aux_beat_Hz;
    f_names={'stft','cwt','sswt'};
    for j=1:numel(f_names)
        name=f_names{j};
        pred=calibrations.(name);
        err_f=pred.freq_Hz(keep)-f_true(keep);
        err_nu=pred.nu_offset_Hz-truth.nu_offset_Hz;
        err_lambda=(pred.lambda_m-truth.lambda_m)*1e15; % m => fm
        item.beat_rmse_Hz=sqrt(mean(err_f.^2));
        item.beat_bias_Hz=mean(err_f);
        item.frequency_rmse_MHz=sqrt(mean(err_nu.^2))/1e6;
        item.wavelength_rmse_fm=sqrt(mean(err_lambda.^2));
        item.wavelength_max_abs_fm=max(abs(err_lambda));
        item.elapsed_s=elapsed_s.(name);
        metrics.(name)=item;
    end
    metrics.cwt_renyi_order2=renyi_order2(abs(cwt.W).^2);
    metrics.sswt_renyi_order2=renyi_order2(abs(sswt.T).^2);
    metrics.sswt_valid_fraction=sswt.valid_fraction;
    metrics.interior_mask=keep;
    metrics.elapsed_total_s=elapsed_s.total;
end

function ent = renyi_order2(power)
% 将整个时间-频率分布归一化成概率，再计算二阶 Rényi 熵。
% 注意：比较不同离散网格的熵值需要统一频率刻度和时间采样网格，
% 这里仅作为显示的描述量，不能据此直接声称两种方法谁更集中。
    p=power(:);
    p=p/sum(p);
    ent=-log2(sum(p.^2));
end
