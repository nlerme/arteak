% Function returning a random integer between lower and upper bounds.
% 
% Inputs:
%   * lb:  lower bound(s)
%   * ub:  upper bound(s)
% 
% Outputs:
%   * result:  pseudo randomly generated integer in [lb,ub]
function result = randi_bounds( lb, ub )
    result = arrayfun(@(x,y) randi([x,y]), lb, ub);
end