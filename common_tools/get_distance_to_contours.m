% This function computes the distance map to the contours of a labeled image.
% 
% Inputs:
%   * im_seg:  partition image (2D matrix with uint8, uint16 or uint32 format)
%   * metric:  name of metric used for computing distances ('euclidean', etc.)
% 
% Outputs:
%   * im_dmap:    distance map (2D matrix with reals)
%   * max_dists:  maximum distance to the contours per region (column vector of non-negative reals)
function [im_dmap,max_dists] = get_distance_to_contours( im_seg, metric )
    % We get the number of regions in the partition image
    nb_regions = max(im_seg(:));

    if nb_regions<=0
        im_dmap   = [];
        max_dists = [];
        return;
    end

    % We build the distance map to the contours of the partition image
    im_bnd  = imgradient(im_seg, 'central')>0;
    im_dmap = bwdist(im_bnd, metric)+1;

    % We compute the minimum
    stats     = regionprops(im_seg, im_dmap, 'MaxIntensity');
    max_dists = stats.MaxIntensity;
end