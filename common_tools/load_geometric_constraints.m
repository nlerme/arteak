% This function loads geometric constraints for placing fragments
function geometric_constraints = load_geometric_constraints( filename )
    % We open the text file
    geometric_constraints = struct('locations', [], 'orientations', []);

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