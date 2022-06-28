% Function mapping coordinates from fragment1 to fragment2.
% 
% Inputs:
%   * p:             pixel coordinates (n x 2 matrix of reals [py_1,px_1;...;py_n,px_n])
%   * translation1:  vector of displacement of first fragment (column vector [ty,tx] in R^2)
%   * angle1:        angle of rotation of first fragment (in degrees)
%   * center1:       center of first fragment (column vector [y,x] in R^2)
%   * translation2:  vector of displacement of second fragment (column vector [ty,tx] in R^2)
%   * angle2:        angle of rotation of second fragment (in degrees)
%   * center2:       center of second fragment (column vector [y,x] in R^2)
% 
% Outputs:
%   * q:  pixel coordinates (n x 2 matrix [py_1,px_1;...;py_1,px_n])
function q = apply_forward_backward_transforms( p, translation1, angle1, center1, translation2, angle2, center2 )
    angle1_r    = deg2rad(angle1);
    angle2_r    = deg2rad(angle2);
    sc1         = cos(angle1_r-angle2_r);
    ss1         = sin(angle1_r-angle2_r);
    sc2         = cos(-angle2_r);
    ss2         = sin(-angle2_r);
    translation = -center1*[sc1,-ss1;ss1,sc1] + (translation1-translation2)*[sc2,-ss2;ss2,sc2];
    R2          = [sc1,-ss1;ss1,sc1;translation];
    q           = double([p,ones(size(p,1),1)]*R2)+center2;
end