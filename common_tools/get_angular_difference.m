% Function returning the absolute angular difference of two angles expressed in degrees
% 
% Inputs:
%   * angle1:  first angle measured in degrees
%   * angle2:  second angle measured in degrees
% 
% Outputs
%   * result:  absolute angular difference between angle1 and angle2
function result = get_angular_difference( angle1, angle2 )
    n      = mod(angle1 - angle2, 360);
    result = min(n, 360-n);
end