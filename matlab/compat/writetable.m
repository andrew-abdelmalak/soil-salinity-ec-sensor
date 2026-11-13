function writetable(T, filename)
% Write lightweight table struct T to CSV file.
    parent = fileparts(filename);
    if ~isempty(parent) && ~exist(parent, 'dir')
        mkdir(parent);
    end
    fid = fopen(filename, 'w');
    if fid < 0
        error('Cannot open file for writing: %s', filename);
    end
    names = T.Properties.VariableNames;
    cols = T.cols;
    n_cols = length(cols);
    for c = 1:n_cols
        if c > 1
            fprintf(fid, ',');
        end
        fprintf(fid, '%s', names{c});
    end
    fprintf(fid, '\n');
    n_rows = length(cols{1});
    for r = 1:n_rows
        for c = 1:n_cols
            if c > 1
                fprintf(fid, ',');
            end
            col = cols{c};
            if iscell(col)
                fprintf(fid, '%s', col{r});
            else
                fprintf(fid, '%.15g', col(r));
            end
        end
        fprintf(fid, '\n');
    end
    fclose(fid);
end
