function writematrix(M, filename)
% Write numeric matrix M to CSV file.
    parent = fileparts(filename);
    if ~isempty(parent) && ~exist(parent, 'dir')
        mkdir(parent);
    end
    fid = fopen(filename, 'w');
    if fid < 0
        error('Cannot open file for writing: %s', filename);
    end
    [rows, cols] = size(M);
    for r = 1:rows
        for c = 1:cols
            if c > 1
                fprintf(fid, ',');
            end
            fprintf(fid, '%.15g', M(r, c));
        end
        fprintf(fid, '\n');
    end
    fclose(fid);
end
