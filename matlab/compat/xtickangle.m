function xtickangle(angle_deg)
% Octave compatibility shim for xtickangle.
    set(gca, 'XTickLabelRotation', angle_deg);
end
