function z = zero(sys)
% Return zeros of a transfer function struct.
    z = roots(sys.num);
end
