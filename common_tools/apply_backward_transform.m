% Function mapping coordinates from fresco to fragment.
% 
% Inputs:
%   * p:            pixel coordinates (n x 2 matrix of reals [py_1,px_1;...;py_n,px_n])
%   * translation:  vector of displacement (column vector [ty,tx] in R^2)
%   * angle:        angle (in degrees)
%   * center:       center of fragment (column vector [y,x] in R^2)
% 
% Outputs:
%   * q:  pixel coordinates (n x 2 matrix [py_1,px_1;...;py_1,px_n])
function q = apply_backward_transform( p, translation, angle, center )
    %angle_r = deg2rad(-angle);
    %sc      = cos(angle_r);
    %ss      = sin(angle_r);
    sc      = cosd(-angle);
    ss      = sind(-angle);
    R       = [sc,-ss;ss,sc];
    q       = double([p,ones(size(p,1),1)]*[R;-translation*R])+center;
end