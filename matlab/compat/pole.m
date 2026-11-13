function p = pole(sys)
% Return poles of a transfer function struct.
    p = roots(sys.den);
end
