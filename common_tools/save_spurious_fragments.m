% This function saves the information about spurious fragments (i.e. not
% belonging to the available ground truth).
% 
% Inputs:
%   * spurious_idx:  indexes of spurious fragments (array)
%   * filename:      name of the file to be saved (string)
% 
% Outputs:
%   None
function save_spurious_fragments( spurious_idx, filename )
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