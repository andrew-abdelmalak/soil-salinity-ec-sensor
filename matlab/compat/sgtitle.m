function sgtitle(str, varargin)
% Octave compatibility shim for sgtitle.
    if exist('suptitle', 'file')
        suptitle(str);
    end
end
