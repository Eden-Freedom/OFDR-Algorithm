function [gauge_ids,site_ids]=p1c_required_sites(core_ids,n_spec,lag,w)
%P1C_REQUIRED_SITES 为指定Gauge及9-bin复相位平均寻找全部必须的复谱点。
% 输入 core_ids：Gauge的1-based索引；n_spec：谱长度；lag：gauge跨度bin；
%     w：复phasor平滑宽度（必须为正奇整数）。
% 输出 gauge_ids：被平滑涉及的所有Gauge索引；
%     site_ids：上述Gauge两端涉及的全部复谱bin(1-based)，已排序去重。
% 不使用光频真值或应变真值作为选取算法校正的依据；本函数只管理索引。
    if ~isscalar(n_spec)||~isscalar(lag)||~isscalar(w)|| ...
       ~isfinite(n_spec)||~isfinite(lag)||~isfinite(w)|| ...
       n_spec<3||n_spec~=floor(n_spec)|| ...
       lag<1||lag>=n_spec||lag~=floor(lag)|| ...
       w<1||w~=floor(w)||mod(w,2)~=1
        error('P1C:Geometry','复谱长度、lag或平滑宽度不合法。');
    end
    G=n_spec-lag;
    core_ids=core_ids(:);
    if isempty(core_ids)||any(~isfinite(core_ids))|| ...
       any(core_ids~=floor(core_ids))||any(core_ids<1)||any(core_ids>G)
        error('P1C:CoreIDs','没有合法Core Gauge索引。');
    end
    half=(w-1)/2;
    all_idx=zeros(numel(core_ids)*w,1);
    for j=-half:half
        ix=(j+half)*numel(core_ids)+(1:numel(core_ids));
        all_idx(ix)=core_ids+j;
    end
    gauge_ids=unique(all_idx(all_idx>=1 & all_idx<=G));
    site_ids=unique([gauge_ids;gauge_ids+lag]);
end