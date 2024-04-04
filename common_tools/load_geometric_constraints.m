% This function loads geometric constraints for placing fragments.
% 
% Inputs:
%   * filename:  name of the file containing geometric constraints (string)
% 
% Outputs:
%   * geometric_constraints:  resulting geometric constraints (struct)
%       * geometric_constraints.locations:     matrix of Nx2 reals
%       * geometric_constraints.orientations:  row vector of reals
function geometric_constraints = load_geometric_constraints( filename )
    % We allocate memory for result
    geometric_constraints = struct('locations', [], 'orientations', []);

    % We check if the file exists
    if ~isfile(filename)
        return;
    end

    % We open the text file
    fp = fopen(filename, 'r');

    if fp<0
        return;
    end

    % We read the text file
    nb_locations = str2num(fgetl(fp));

    for k=1:nb_locations
        location = sscanf(fgetl(fp), '%f %f');
        geometric_constraints.locations = [geometric_constraints.locations;location'];
    end

    nb_orientations = str2num(fgetl(fp));

    for k=1:nb_orientations
        orientation = sscanf(fgetl(fp), '%f');
        geometric_constraints.orientations = [geometric_constraints.orientations;orientation];
    end
end
