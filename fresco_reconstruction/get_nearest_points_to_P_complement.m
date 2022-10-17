% Function returning both the nearest points to and distances to the 
% complement of a rectangular image domain P.
% 
% Inputs:
%   * image_size:  spatial size of the image (2D integer vector)
%   * coords:      pixel coordinates (n x 2 matrix of reals [py_1,px_1;...;py_n,px_n])
% 
% Outputs:
%   * d:  distance to nearest points (column vector of size n)
%   * np: pixel coordinates of nearest points (n x 2 matrix of reals [py_1,px_1;...;py_n,px_n])
function [dists,np] = get_nearest_points_to_P_complement( image_size, coords )
    % Rounding
    coords = round(coords);

    % Computation of distances
    a           = coords(:,1)-1;
    b           = image_size(1)-coords(:,1);
    c           = coords(:,2)-1;
    d           = image_size(2)-coords(:,2);
    [dists,idx] = min(abs([a+1,b+1,c+1,d+1]),[],2);
    dists       = dists.*(a>=0 & b>=0 & c>=0 & d>=0);

    % Computation of nearest points
    np                     = coords;
    np(dists>0 & idx==1,1) = 0;
    np(dists>0 & idx==2,1) = image_size(1)+1;
    np(dists>0 & idx==3,2) = 0;
    np(dists>0 & idx==4,2) = image_size(2)+1;
end