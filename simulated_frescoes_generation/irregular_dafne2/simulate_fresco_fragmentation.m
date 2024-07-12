% This function generates a fragmentation given an image size and a couple 
% of parameters. The following steps are sequentially executed:
% 
% 1) Random sampling of seeds (Poisson or non-uniform)
% 2) Generation of normalized power law noise image
% 3) Computation of Voronoi diagram from seeds
% 4) Computation of distance map to the contours of Voronoi diagram
% 5) Erosion of Voronoi cells based on the the distance map
% 6) Normalization of distance map
% 7) Watershed-based segmentation between eroded Voronoi cells
% 
% Inputs:
%   * image_size:  output image size (2D vector of positive integers)
%   * parameters:
%     - sampling_type:          type of sampling used for random seeds ('non-uniform-mitchell', 'non-uniform-lloyd' or 'poisson').
%     - sampling_min_dist:      minimum distance separating sampled points (>=0)
%     - sampling_nb_points:     number of sampled points (non-negative integer; can be empty)
%     - noise_exponent:         exponent used in power law noise generation (in ]0,3]). The amount of emphasis placed on lower frequencies is controlled by this parameter. 
%                               Larger values result in greater influence from low spatial frequencies which result in smoother noise transitions with less detailed texture. 
%                               The value of this parameter is used to define several classifications of noise: white noise (=0), pink noise (=1) or Brownian noise (=2).
%     - uncertainty_band_size:  size of the uncertainty band between adjacent fragments for generating new boundaries, relatively to the smallest fragment (in [0,1]). 
%                               This parameter controls the degree of freedom where fragments boundaries can be generated.
%     - beta:                   weighting parameter balancing between Euclidean distance and gradient of noise image (in [0,1]). When beta=1, fragments boundaries are the 
%                               same as the Voronoi diagram. As beta tends to zero, the fragments boundaries become more and more jaggy.
%     - metric:                 name of the metric used for computing distance maps ('cityblock', 'chessboard', 'euclidean', etc.). This parameter controls the global shape 
%                               of the generated fragment.
% 
% Outputs:
%   * im_result:  resulting fragmentation with integer intensities (2D matrix in uint32)
%   * im_noise:   resulting noise image with normalized intensities (2D matrix of reals)
function [im_result,im_noise] = simulate_fresco_fragmentation( image_size, parameters )
    % We get parameters
    sampling_type          = parameters.sampling_type;
    sampling_min_dist      = parameters.sampling_min_dist;
    sampling_nb_points     = parameters.sampling_nb_points;
    noise_exponent         = parameters.noise_exponent;
    uncertainty_band_size  = parameters.uncertainty_band_size;
    beta                   = parameters.beta;
    metric                 = parameters.metric;

    % We randomly sample seeds
    if strcmp(sampling_type, 'poisson')
        pts = poisson_disc_sampling(image_size, sampling_min_dist, sampling_nb_points);
    elseif strcmp(sampling_type, 'non-uniform-mitchell')
        pts = non_uniform_sampling_mitchell(image_size, sampling_min_dist, sampling_nb_points);
    elseif strcmp(sampling_type, 'non-uniform-lloyd')
        pts = non_uniform_sampling_lloyd(image_size, sampling_min_dist, sampling_nb_points);
    else
        error('unknown sampling type');
    end

    % We round coordinates of sampled points to the nearest integer
    pts = round(pts);

    % We construct the image containing points
    im_pts       = zeros(image_size, 'uint32');
    pts2         = sub2ind(image_size, pts(:,1), pts(:,2));
    im_pts(pts2) = 1:numel(pts2);

    % We compute the Voronoi diagram from this set of points
    [im_dmap,im_nn] = bwdist(im_pts>0, metric);
    im_seg1         = uint32(im_pts(im_nn));

    if beta==1
        im_result = im_seg1;
        im_noise  = [];
        return;
    end

    % We generate a power law noise image
    im_noise = power_law_noise(image_size, noise_exponent);

    % We build the distance map to the contours of the diagram
    im_bnd   = imgradient(im_seg1, 'central')>0;
    im_dmap2 = bwdist(im_bnd, metric)+1;

    % We compute the half diameter of the smallest Voronoi cell
    min_dist = inf;

    for k=1:size(pts,1)
        im_tmp   = im_dmap2.*(im_seg1==k);
        min_dist = min(min_dist, max(im_tmp(:)));
    end

    % We slightly erode all the pieces of the Voronoi diagram
    threshold = uncertainty_band_size*min_dist;
    im_cells  = (im_dmap2>=threshold);

    % We normalize the values of the initial distance map
    im_dmap = rescale(im_dmap, 0.0, 1.0);

    % We generate the partition of irregularly shaped fragments
    im_weights = (1.0-beta)*im_noise + beta*im_dmap + eps;
    im_weights = imimposemin(im_weights, im_cells);
    im_seg2     = uint32(watershed(im_weights));

    % We renumber fragments based on their initial labels
    im_seg3 = zeros(size(im_seg2), 'uint32');

    for k=1:size(pts,1)
        label   = im_seg2(pts(k,1),pts(k,2));
        im_seg3 = im_seg3 + uint32((im_seg2==label)*k);
    end

    % We fill boundaries between fragments
    [~,im_nn2]        = bwdist(im_seg3>0, metric);
    im_tmp            = (im_seg3==0);
    im_result         = im_seg3;
    im_result(im_tmp) = im_seg3(im_nn2(im_tmp));
end
