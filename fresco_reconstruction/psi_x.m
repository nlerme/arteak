% Psi activation function (sigmoid here).
% 
% Inputs:
%   * x:       input data (in [-1,1])
%   * lambda:  sharpness parameter (>0)
%   * mu:      shift parameter (in [-1,1])
% 
% Outputs:
%   * result:  output data (in [-1,1])
function result = psi_x( x, lambda, mu )
    result = 2/(1+exp(-lambda*(x-mu)))-1;
end