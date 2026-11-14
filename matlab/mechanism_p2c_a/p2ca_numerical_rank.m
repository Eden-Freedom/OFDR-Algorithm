function s=p2ca_numerical_rank(A)
%P2CA_NUMERICAL_RANK 根据明确固定的相对SVD阈值报告矩阵秩。
% 仅用于低维合成数值算子；不等同于有噪声条件下的信息可辨识性。
    singular=svd(A);
    if isempty(singular)
        error('P2CA:Empty','无法对空矩阵计算SVD。');
    end
    tol=max(size(A))*eps(max(singular))*20;
    r=nnz(singular>tol);
    s=struct();
    s.rows=size(A,1);
    s.cols=size(A,2);
    s.rank=r;
    s.nullity=s.cols-r;
    s.tolerance=tol;
    s.singular_values=singular;
    if r>0
        s.smallest_nonzero=singular(r);
        s.largest=singular(1);
        s.observable_condition=singular(1)/singular(r);
    else
        s.smallest_nonzero=NaN;
        s.largest=NaN;
        s.observable_condition=NaN;
    end
end