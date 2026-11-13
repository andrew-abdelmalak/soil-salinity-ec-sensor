function T = table(varargin)
% Lightweight table struct for Octave compatibility with writetable.
    n_cols = nargin;
    cols = cell(1, n_cols);
    names = cell(1, n_cols);
    for i = 1:n_cols
        col = varargin{i};
        if iscell(col)
            cols{i} = col(:);
        else
            cols{i} = col(:);
        end
        names{i} = sprintf('Var%d', i);
    end
    T = struct('cols', {cols}, 'Properties', struct('VariableNames', {names}));
end
