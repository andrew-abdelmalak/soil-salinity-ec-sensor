function sys = tf(num, den)
% Lightweight continuous-time transfer function struct for Octave compatibility.
    sys = struct('num', num(:).', 'den', den(:).', 'is_tf', true);
end
