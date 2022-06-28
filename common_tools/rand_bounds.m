% Function returning a real random number between lower and upper bounds
% 
% Inputs:
%   * lb:  lower bound
%   * ub:  upper bound
% 
% Outputs:
%   * result:  pseudo randomly generated real number in [lb,ub]
function result = rand_bounds( lb, ub )
    result = (ub-lb).*rand(size(lb))+lb;
end