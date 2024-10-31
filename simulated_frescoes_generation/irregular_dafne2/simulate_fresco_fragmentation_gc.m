% This function generates a fragmentation given an image size and a couple 
% of parameters. The following steps are sequentially executed:
% 
% 1) Random sampling of seeds (Poisson or non-uniform)
% 2) Generation of normalized power law noise image
% 3) Computation of Voronoi diagram from seeds
% 4) Computation of distance map to the contours of Voronoi diagram
% 5) Erosion of Voronoi cells based on the the distance map
% 6) Normalization of distance map
% 7) Graph cuts-based segmentation between eroded Voronoi cells
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
function [im_result,im_noise] = simulate_fresco_fragmentation_gc( image_size, sampling_min_dist, parameters )
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
    [im_dmap,m_nn] = bwdist(im_pts>0, metric);
    im_seg = uint32(im_pts(m_nn));

    if beta==1
        im_result = im_seg;
        im_noise  = [];
        return;
    end

    % We generate a power law noise image
    im_noise = power_law_noise(image_size, noise_exponent);

    % We build the distance map to the boundaries of the diagram
    im_bnd   = imgradient(im_seg,'central')>0;
    im_dmap2 = bwdist(im_bnd, metric);

    % We compute the half diameter of the smallest Voronoi cell
    min_dist = inf;

    for k=1:size(pts,1)
        im_tmp   = im_dmap2.*(im_seg==k);
        min_dist = min(min_dist,max(im_tmp(:)));
    end

    % We slightly erode the cells of the Voronoi diagram
    threshold = round(uncertainty_band_size*min_dist);
    im_pts2   = (im_dmap2<=(threshold+sqrt(2)));
    im_pts3   = (im_dmap2<=threshold);

    % We normalize the values of the distance map
    im_dmap2 = rescale(im_dmap2, 0.0, 1.0);

    % We estimate the standard deviation of the exponential term used in graph cuts segmentation
    im_noise_grad = imgradient(im_noise, 'central');
    sigma_n       = mean(im_noise_grad(:));

    % We generate the partition of irregularly shaped fragments
    connectivity = 1; % graph connectivity (8-nearest neighbors)
    im_n_sites   = zeros(image_size, 'uint32');
    [rs,cs]      = find(im_pts2>0);
    nb_sites     = numel(rs);
    nb_labels    = size(pts,1);
    h            = GCO_Create(nb_sites, nb_labels);

    dc            = double(zeros(nb_labels, nb_sites));
    large_const   = 1000000.0;
    init_labeling = ones(nb_sites,1);

    for idx=1:numel(rs)
        i                    = rs(idx)-1;
        j                    = cs(idx)-1;
        offset_p             = j*image_size(1)+i+1;
        im_n_sites(offset_p) = idx;

        if im_pts3(offset_p)==0
            dc(:,idx)                        = large_const;
            dc(double(im_seg(offset_p)),idx) = 0.0;
            init_labeling(idx)               = im_seg(offset_p);
        end
    end

    GCO_SetDataCost(h, dc);

    sc = double(~diag(ones(1,nb_labels)));
    GCO_SetSmoothCost(h, sc);

    image_nb_pixels = prod(image_size);

    if connectivity==0
        nb_non_null_values = 4*image_nb_pixels;
    else
        nb_non_null_values = 8*image_nb_pixels;
    end

    offsets_p = zeros(1, nb_non_null_values);
    offsets_q = zeros(1, nb_non_null_values);
    costs     = double(zeros(1, nb_non_null_values));
    count     = 1;

    for idx=1:numel(rs)
        i        = rs(idx)-1;
        j        = cs(idx)-1;
        offset_p = j*image_size(1)+i+1;

        for ii=max(i-1,0):min(i+1,image_size(1)-1)
            for jj=max(j-1,0):min(j+1,image_size(2)-1)
                offset_q = jj*image_size(1)+ii+1;

                if im_pts2(offset_q)==0 || offset_p>=offset_q || (connectivity==0 && (abs(i-ii)+abs(j-jj))>1)
                    continue;
                end

                d_cost           = 0.5*(im_dmap2(offset_p)+im_dmap2(offset_q));
                n_cost           = exp(-0.5*(im_noise(offset_p)-im_noise(offset_q))^2/sigma_n^2);
                cost             = beta*d_cost + (1.0-beta)*n_cost + eps;
                offsets_p(count) = im_n_sites(offset_p);
                offsets_q(count) = im_n_sites(offset_q);
                costs(count)     = cost;
                count            = count+1;
            end
        end
    end

    index = find(offsets_p>0, 1, 'last');
    offsets_p = offsets_p(1:index);
    offsets_q = offsets_q(1:index);
    costs     = costs(1:index);
    n         = sparse(offsets_p, offsets_q, costs, nb_sites, nb_sites);
    GCO_SetNeighbors(h, n);

    GCO_SetVerbosity(h, 0);
    GCO_SetLabeling(h, init_labeling);
    GCO_Expansion(h, 1);
    %[E,D,S,~] = GCO_ComputeEnergy(h);

    labeling = uint32(GCO_GetLabeling(h));

    for idx=1:numel(labeling)
        i           = rs(idx);
        j           = cs(idx);
        im_seg(i,j) = labeling(idx);
    end

    GCO_Delete(h);

    im_result = im_seg;
end