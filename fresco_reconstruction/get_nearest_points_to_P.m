% Function returning both the nearest points to and distances to a 
% rectangular image domain P.
% 
% Inputs:
%   * image_size:  spatial size of the image (2D integer vector)
%   * coords:      pixel coordinates (n x 2 matrix of reals [py_1,px_1;...;py_n,px_n])
% 
% Outputs:
%   * d:  distance to nearest points (column vector of size n)
%   * np: pixel coordinates of nearest points (n x 2 matrix of reals [py_1,px_1;...;py_n,px_n])
function [dists,np] = get_nearest_points_to_P( image_size, coords )
    % Computation of nearest neighbors
    a = coords(:,1)-1;
    b = image_size(1)-coords(:,1);
    c = coords(:,2)-1;
    d = image_size(2)-coords(:,2);

    c1 = (a<0 & b>=0 & c<0 & d>=0);
    c2 = (a<0 & b>=0 & c>=0 & d>=0);
    c3 = (a<0 & b>=0 & c>=0 & d<0);
    c4 = (a>=0 & b>=0 & c<0 & d>=0);
    c5 = (a>=0 & b>=0 & c>=0 & d<0);
    c6 = (a>=0 & b<0 & c<0 & d>=0);
    c7 = (a>=0 & b<0 & c>=0 & d>=0);
    c8 = (a>=0 & b<0 & c>=0 & d<0);

    np        = coords;
    np(c1, 1) = 1;             np(c1, 2) = 1;             % top left corner
    np(c3, 1) = 1;             np(c3, 2) = image_size(2); % top right corner
    np(c6, 1) = image_size(1); np(c6, 2) = 1;             % bottom left corner
    np(c8, 1) = image_size(1); np(c8, 2) = image_size(2); % bottom right corner

    np(c2, 1) = 1;             % middle top
    np(c4, 2) = 1;             % middle left
    np(c5, 2) = image_size(2); % middle right
    np(c7, 1) = image_size(1); % middle bottom

    % Computation of distances
    dists = sqrt(sum((np-coords).^2,2));
end