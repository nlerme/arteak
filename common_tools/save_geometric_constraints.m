% This function saves the available translations and angles constraining the placement of fragments.
% 
% Inputs:
%   * geometric_constraints:  geometric constraints (struct)
%     * geometric_constraints.locations:     matrix of Nx2 reals
%     * geometric_constraints.orientations:  row vector of reals
%   * filename:  name of the saved file (string)
% Outputs:
%   None
function save_geometric_constraints( geometric_constraints, filename )
    % We open the file in writing mode
    fp = fopen(filename, 'w');

    if fp<0
        error('Unable to write the text file %s', filename);
    end

    % We write values into the text file
    locations    = geometric_constraints.locations;
    orientations = geometric_constraints.orientations;

    fprintf(fp, '%d\n', size(locations,1));

    for i=1:size(locations,1)
        fprintf(fp, '%f %f\n', locations(i,2), locations(i,1));
    end

    fprintf(fp, '%d\n', numel(orientations));

    for i=1:numel(orientations)
        angle = -orientations(i); % CAUTION: opposite angle is taken
        fprintf(fp, sprintf('%f\n', angle));
    end

    % We close the file handler
    fclose(fp);
end
