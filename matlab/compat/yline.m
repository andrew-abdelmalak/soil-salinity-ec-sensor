function h = yline(y, linespec, varargin)
% Draw horizontal reference line in Octave.
    if nargin < 2 || isempty(linespec)
        linespec = 'k--';
    end
    xl = xlim();
    if xl(1) == xl(2)
        xl = [0, 1];
    end
    args = {};
    i = 1;
    while i <= length(varargin)
        if ischar(varargin{i}) && strcmpi(varargin{i}, 'Label')
            i = i + 2;
            continue;
        end
        args{end+1} = varargin{i}; %#ok<AGROW>
        i = i + 1;
    end
    was_hold = ishold();
    hold on;
    h = plot(xl, [y, y], linespec, args{:});
    if ~was_hold
        hold off;
    end
end
