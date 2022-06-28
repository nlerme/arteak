% Function applying a windowing function on pixel coordinates related to a 
% rectangular image domain P. Each pixel is assigned with a null weight if 
% it lies inside P, otherwise with a smoothly decreasing weight as it goes 
% away from P.
% 
% Inputs:
%   * image_size:  spatial size of the image (2D integer vector)
%   * coords:      pixel coordinates (n x 2 matrix of reals [py_1,px_1;...;py_n,px_n])
%   * wf:          windowing function (anonymous bivariate function)
% 
% Outputs:
%   * weights:  output weights (column vector with reals in [0,1] of size n)
function weights = apply_windowing( image_size, coords, wf )
    a       = 1-coords(:,1);
    b       = coords(:,1)-image_size(1);
    c       = 1-coords(:,2);
    d       = coords(:,2)-image_size(2);
    weights = wf(sqrt(a.^2.*(a>0) + b.^2.*(b>0) + c.^2.*(c>0) + d.^2.*(d>0)));
end