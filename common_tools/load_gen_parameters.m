% This function loads parameters used for reconstruction
function gen_parameters = load_gen_parameters( filename )
    % We read the text file
    gen_parameters                     = struct();
    [parameters_name,parameters_value] = textread(filename, '%s %f');

    % We set the corresponding field of the resulting structure
    for k=1:numel(parameters_name)
        setfield(gen_parameters, parameters_name{k}, parameters_value{k});
    end
end