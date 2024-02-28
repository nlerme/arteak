% Function returning a random real number between lower and upper bounds.
% 
% Inputs:
%   * lb:  lower bound(s)
%   * ub:  upper bound(s)
% 
% Outputs:
%   * result:  pseudo randomly generated real number in [lb,ub]
function result = rand_bounds( lb, ub )
    result = (ub-lb).*rand(size(lb))+lb;
end