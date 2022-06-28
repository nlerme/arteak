% This function saves the indexes of spurious fragments
function save_spurious_fragments_idx( spurious_idx, filename )
    % We open the file in writing mode
    fp = fopen(filename, 'w');

    if fp<0
        error('unable to write the text file %s', filename);
        return;
    end

    % We write values into the text file
    for n=spurious_idx
        fprintf(fp, '%d\n', n-1);
    end

    % We close the file handler
    fclose(fp);
end