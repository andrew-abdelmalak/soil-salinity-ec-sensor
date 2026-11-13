function writecell(C, filename)
% Write 2D cell array C to CSV file.
    parent = fileparts(filename);
    if ~isempty(parent) && ~exist(parent, 'dir')
        mkdir(parent);
    end
    fid = fopen(filename, 'w');
    if fid < 0
        error('Cannot open file for writing: %s', filename);
    end
    [rows, cols] = size(C);
    for r = 1:rows
        for c = 1:cols
            if c > 1
                fprintf(fid, ',');
            end
            val = C{r, c};
            if ischar(val)
                if ~isempty(strfind(val, ',')) || ~isempty(strfind(val, '"'))
                    escaped = strrep(val, '"', '""');
                    fprintf(fid, '"%s"', escaped);
                else
                    fprintf(fid, '%s', val);
                end
            elseif isnumeric(val) || islogical(val)
                if isempty(val)
                    % empty
                else
                    fprintf(fid, '%.15g', double(val(1)));
                end
            end
        end
        fprintf(fid, '\n');
    end
    fclose(fid);
end
