% This function returns a set of non-uniformly sampled points based on 
% the Mitchell's algorithm using kd-trees as spatial data structure for 
% speeding-up nearest neighbors searches.
% 
% Inputs:
%   * image_size:  size of the image (2D vector of positive integers)
%   * min_dist:    targeted minimum distance between sampled points (>=0)
%   * nb_points:   number of sampled points (positive integer)
% 
% Outputs:
%   * pts:  sampled points (Nx2 matrix of reals)
function pts = non_uniform_sampling_mitchell( image_size, min_dist, nb_points )
    % We initialize the array containing sampled points
    pts = [];

    % We check if the desired number of sampled points is valid
    if nb_points<1 || nb_points>prod(image_size)
        return;
    end

    % We randomly select the first point in the image plane
    pts = rand_bounds([1,1], image_size);

    % We loop until the desired number of sampled points is reached or if we cannot reach such number
    nb_candidates = 100;
    max_nb_tries  = 3;
    nb_tries      = 0;

    while true
        % If we reach the desired number of sampled points, we stop
        if size(pts,1)==nb_points
            break;
        end

        % We randomly select an increasing number of candidates among those locations
        candidates = rand_bounds(repmat([1,1],nb_candidates,1),repmat(image_size,nb_candidates,1));

        % We compute the nearest neighbors of the candidates to the previously sampled points
        [~,dists] = knnsearch(pts, candidates, 'Distance', 'euclidean', 'NSMethod', 'kdtree');

        % If the maximum distance is smaller than the minimum distance, we continue
        [max_dist,m] = max(dists);

        if max_dist<=min_dist && nb_tries<max_nb_tries
            nb_tries = nb_tries+1;
            continue;
        else
            nb_tries = 0;
        end

        % We look for the the farthest one and add it the sampled points
        pts = [pts;candidates(m,:)];
    end

    %--- debug ---
    %pts = round(pts);
    %pts = sub2ind(image_size, pts(:,1), pts(:,2));
    %im_pts = zeros(image_size, 'logical');
    %im_pts(pts) = 1;
    %figure, imshow(im_pts,[]);
    %-------------
end