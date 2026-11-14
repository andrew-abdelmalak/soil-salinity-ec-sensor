function h = xline(x, linespec, varargin)
% Draw vertical reference line in Octave.
    if nargin < 2 || isempty(linespec)
        linespec = 'k--';
    end
    yl = ylim();
    if yl(1) == yl(2)
        yl = [0, 1];
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
    h = plot([x, x], yl, linespec, args{:});
    if ~was_hold
        hold off;
    end
end
