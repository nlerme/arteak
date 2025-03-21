% This function returns distance map and nearest neighbors map of given 
% size from given points and using given distance name.
% 
% Inputs:
%   * pts:         coordinates of marker points (Nx2 matrix of reals in [1,M]x[1,N])
%   * image_size:  size of the output images (row vector of positive integers)
%   * dist_name:   name of the distance function used ('euclidean', mahalanobis', 'cityblock', 'minkowski', 'chebychev', etc.)
%   * weights:     weights used in distance (row vector of reals; can be empty)
% 
% Outputs:
%   * im_dmap:  distance map (MxN matrix of reals)
%   * im_nn:    nearest neighbors map (MxN uint32 matrix of positive integers)
function [im_dmap,im_nn] = get_distance_map( pts, image_size, dist_name, weights )
    % We check if the number of marker points and weights is the same
    if ~isempty(weights) && size(pts,1)~=size(weights,2)
        error('The number of marker points and weights must be the same');
    end

    % We create vectors storing pixel coordinates over the whole image
    [x,y] = meshgrid(1:image_size(2), 1:image_size(1));
    x     = x(:);
    y     = y(:);

    % We compute the distance and nearest neighbors betwen pixels and marker points
    dists = pdist2([y,x], pts, dist_name);

    if ~isempty(weights)
        dists = dists+repmat(weights,[size(x,1),1]);
    end

    [min_dists,argmin_dists] = min(dists,[],2);

    % We create the resulting images
    im_nn        = zeros(image_size, 'uint32');
    im_dmap      = zeros(image_size);
    idx          = sub2ind(image_size, y, x);
    im_nn(idx)   = argmin_dists;
    im_dmap(idx) = min_dists;
end