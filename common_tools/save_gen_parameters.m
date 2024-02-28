% This function saves parameters used for generating fragment images.
% 
% Inputs:
%   * parameters_names:   name of parameters (cell array)
%   * parameters_values:  value of parameters (cell array)
%   * filename:           name of saved file (string)
% 
% Outputs:
%   None
function save_gen_parameters( parameters_names, parameters_values, filename )
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
        name  = parameters_names{k};
        value = parameters_values{k};

        if isfloat(value)
            fprintf(fp, '%s %f\n', name, value);
        elseif isinteger(value)
            fprintf(fp, '%s %d\n', name, value);
        elseif ischar(value)
            fprintf(fp, '%s %s\n', name, value);
        elseif isstruct(value)
            fns = fieldnames(value);
            for i=1:numel(fns)
                value2 = getfield(value, fns{i});
                if isfloat(value2)
                    fprintf(fp, '%s %f\n', fns{i}, value2);
                elseif isinteger(value2)
                    fprintf(fp, '%s %d\n', fns{i}, value2);
                elseif ischar(value2)
                    fprintf(fp, '%s %s\n', fns{i}, value2);
                else
                    error('unknown data type');
                end
            end
        end
    end

    % We close the file handler
    fclose(fp);
end