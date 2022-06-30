% This function saves parameters used for generating fragment images
function save_fragments_generation_parameters( parameters_names, parameters_values, filename )
    % We check if input arguments are valid
    if numel(parameters_names)~=numel(parameters_values)
        error('parameters_names and parameters_values arrays must be of the same size');
    end

    % We open the file in writing mode
    fp = fopen(filename, 'w');

    if fp<0
        error('unable to write the text file %s', filename);
    end

    % We write values into the text file
    for k=1:numel(parameters_names)
        if isfloat(parameters_values{k})
            fprintf(fp, '%s %f\n', parameters_names{k}, parameters_values{k});
        elseif isinteger(parameters_values{k})
            fprintf(fp, '%s %d\n', parameters_names{k}, parameters_values{k});
        elseif isstring(parameters_values{k})
            fprintf(fp, '%s %s\n', parameters_names{k}, parameters_values{k});
        else
            error('unknown data type');
        end
    end

    % We close the file handler
    fclose(fp);
end