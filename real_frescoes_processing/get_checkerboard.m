% This function returns the pixel coordinates and the size (in pixels) of 
% the checkerboard.
% 
% Inputs:
%   * img_fn:             filename of the image (string)
%   * checkerboard_dims:  expected dimensions of the checkerboard for checking consistency (2D vector of non negative integers)
% 
% Outputs:
%   * cb_pts:   pixel coordinates of the N detected corners of the checkerboard (matrix of reals of size Nx2)
%   * cb_size:  dimensions of the detected checkerboard (2D vector of non negative integers)
function [cb_pts,cb_size] = get_checkerboard( img_fn, checkerboard_dims )
    [cb_pts,cb_dims] = detectCheckerboardPoints(img_fn, 'PartialDetections', false);

    if isempty(cb_pts) || isempty(cb_dims)
        error(sprintf('Checkerboard not detected or partially detect on image %s', img_fn));
    end

    if any(cb_dims~=checkerboard_dims)
        error(sprintf('The checkerboard in image %s must be of size %dx%d', img_fn, checkerboard_dims(1), checkerboard_dims(2)))
    end

    % We set the checkerboard size as the mean distance between all pairs of detected corner points
    cb_size = mean(pdist(cb_pts));
end