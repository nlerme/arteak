% This function returns the value of a parameter in a cell array with structs
% 
% Inputs:
%   * ca:    set of parameters (cell array with structs)
%   * name:  name of the parameter (non empty string)
% 
% Outputs:
%   * value:  value of the parameter
function value = get_parameter_value( parameters, name )
    if isempty(parameters) || isempty(name)
        value = [];
        return;
    end

    idx = find(cellfun(@(x) strcmp(x.name, name), parameters)>0);

    if isempty(idx)
        value = [];
        return;
    end

    value = parameters{idx}.value;
end