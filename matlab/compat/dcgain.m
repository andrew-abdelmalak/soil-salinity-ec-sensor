function k = dcgain(sys)
% Return DC gain H(0) of a transfer function struct.
    if sys.den(end) == 0
        k = Inf;
    else
        k = sys.num(end) / sys.den(end);
    end
end
