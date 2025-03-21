% This function computes the distance map to the contours of a labeled image.
% 
% Inputs:
%   * im_map:           labeled image (2D matrix with uint8, uint16 or uint32 format)
%   * metric:           name of metric used for computing distances ('euclidean', etc.)
%   * is_segmentation:  indicates if the map is a segmentation or its contours (true or false)
% 
% Outputs:
%   * im_dmap:    distance map (2D matrix with reals)
%   * max_dists:  maximum distance to the contours per region (column vector of non-negative reals)
function [im_dmap,max_dists] = get_distance_to_contours( im_map, metric, is_segmentation )
    % We get the number of regions in the partition image
    nb_regions = max(im_map(:));

    if nb_regions<=0
        error('The number of labels in the map must be positive');
    end

    % We build the distance map to the contours of the partition image
    if is_segmentation
        im_bnd  = imgradient(im_map, 'central')>0;
        im_dmap = bwdist(im_bnd, metric)+1;
    else
        im_dmap = bwdist(im_map==0, metric);
    end

    % We compute the maximum distance per region
    stats     = regionprops(im_map, im_dmap, 'MaxIntensity');
    max_dists = stats.MaxIntensity;
end