% This function returns a set of non-uniformly sampled points. Starting
% from a uniform distribution, points are progressively evenly distributed
% using Lloyd's relaxation algorithm until the minimum distance between 
% them is larger than some threshold.
% 
% Inputs:
%   * image_size:  size of the image (2D vector of poisitive integers)
%   * min_dist:    targeted minimum distance between sampled (>=0)
%   * nb_points:   number of sampled points (positive integer)
% 
% Outputs:
%   * pts:  sampled points (Nx2 matrix of reals)
function pts = non_uniform_sampling_lloyd( image_size, min_dist, nb_points )
    % We initialize the array containing sampled points
    pts = [];

    % We check if the desired number of sampled points is valid
    if nb_points<1 || nb_points>prod(image_size)
        return;
    end

    % We randomly select the initial points
    max_nb_iterations = 10;
    p                 = randperm(prod(image_size));
    [rows,cols]       = ind2sub(image_size, p(1:nb_points)');
    pts               = [rows,cols];
    c_min_dist        = min(pdist(pts, 'euclidean'));
    iteration         = 0;

    disp(sprintf('+iteration 0 | current minimum distance=%f', c_min_dist));

    % We loop for a desired couple of iterations
    while c_min_dist<min_dist & iteration<max_nb_iterations
        % We draw the image of points
        im_pts       = zeros(image_size, 'uint32');
        pts2         = sub2ind(image_size, pts(:,1), pts(:,2));
        im_pts(pts2) = 1:nb_points;

        % We compute the nearest neighbors map and the number of regions
        [~,im_nn]  = bwdist(im_pts>0, 'euclidean');
        im_nn      = uint32(im_pts(im_nn));

        % We update centroids
        rp         = regionprops(im_nn, 'Centroid');
        pts        = round(fliplr(cat(1, rp.Centroid)));
        c_min_dist = min(pdist(pts, 'euclidean'));
        iteration  = iteration+1;

        % Message
        disp(sprintf('+iteration %d | current minimum distance=%f', iteration, c_min_dist));
    end

    %--- debug ---
    %im_pts = zeros(image_size, 'logical');
    %pts2 = sub2ind(image_size, pts(:,1), pts(:,2));
    %im_pts(pts2) = 1;
    %figure, imshow(im_pts,[]);
    %-------------
end