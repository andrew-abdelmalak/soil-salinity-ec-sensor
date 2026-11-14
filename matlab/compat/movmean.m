function m = movmean(x, k)
% Centered moving average matching MATLAB movmean(x, k) boundary behavior.
    is_row = isrow(x);
    xv = x(:);
    n = length(xv);
    left = floor(k / 2);
    right = k - 1 - left;
    cs = [0; cumsum(xv)];
    idx = (1:n).';
    lo = max(1, idx - left);
    hi = min(n, idx + right);
    mv = (cs(hi + 1) - cs(lo)) ./ (hi - lo + 1);
    if is_row
        m = mv.';
    else
        m = mv;
    end
end
