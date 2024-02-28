% This function save neighboring relationships between fragments.
% 
% Inputs:
%   * frags_sol:  solution composed of fragments (cell array)
%   * filename:   name of the saved file (string)
% 
% Outputs:
%   None
function save_fragment_neighbors( frags_sol, filename )
    % We check if input arguments are valid
    if isempty(frags_sol) || isempty(filename)
        error('Fragments solution and filename must be non empty');
    end

    % We open the file in writing mode
    fp = fopen(filename, 'w');

    if fp<0
        error('Unable to write the text file %s', filename);
    end

    % We write values into the text file
    for i=1:numel(frags_sol)
        if isfield(frags_sol{i}, 'neighbors')
            for j=frags_sol{i}.neighbors
                fprintf(fp, '%d %d\n', frags_sol{i}.idx-1, frags_sol{j}.idx-1);
            end
        end
    end

    % We close the file handler
    fclose(fp);
end