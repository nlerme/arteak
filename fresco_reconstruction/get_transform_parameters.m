% Function extracting the geometric parameters from an affine transform matrix.
% 
% Inputs:
%   * tform:       2x2 real matrix of affine transform (in R^{2x2})
%   * image_size:  2D size of fresco image (vector in N_{>0}^2)
% 
% Outputs:
%   * translation:     2D vector ([ty,tx] in R^2)
%   * angle:           rotation angle (in degrees)
%   % scaling_factor:  scaling factor in R_{>0}
function [translation,angle,scaling_factor] = get_transform_parameters( tform, image_size )
    ss = tform.T(2,1);
    sc = tform.T(1,1);
    half_size = 0.5*image_size;
    translation = [tform.T(3,2)+half_size(2)*(sc-ss),tform.T(3,1)+half_size(1)*(sc+ss)];
    scaling_factor = sqrt(ss^2+sc^2);
    angle = -rad2deg(atan2(ss,sc));
end