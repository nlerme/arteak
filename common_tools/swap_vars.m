% Functiong swapping the content of two variables.
% 
% Inputs:
%   * a:  first variable
%   * b:  second variable
% 
% Outputs:
%   * b:  first variable
%   * a:  second variable
function [b,a] = my_swap( a, b )
    c = a;
    a = b;
    b = c;
end