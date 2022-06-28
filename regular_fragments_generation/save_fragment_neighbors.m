% This function save neighboring relationships between fragments as a text file
function save_fragment_neighbors( frag_neighbors, filename )
    % We check if input arguments are valid
    if isempty(frag_neighbors)
        error('neighbors array must be not empty');
    end

    % We open the file in writing mode
    fp = fopen(filename, 'w');

    if fp<0
        error('unable to write the text file %s', filename);
    end

    % We write values into the text file
    for idx1=1:size(frag_neighbors,1)
        for idx2=1:size(frag_neighbors,2)
            if frag_neighbors(idx1,idx2)==0
                continue;
            end

            fprintf(fp, '%d %d\n', idx1-1, idx2-1);
        end
    end

    % We close the file handler
    fclose(fp);
end