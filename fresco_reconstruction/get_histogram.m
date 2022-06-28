% Function returning the histogram of an image.
% 
% Inputs:
%   * im_src:              multi-channels source image
%   * im_mask:             binary mask image
%   * nb_bin_per_channel:  number of channels per channel (in N_{>0})
% 
% Outputs:
%   * h:  histogram counts
%   * B:  linearized image intensities from [0,1]^3
function [h,B] = get_histogram( im_src, im_mask, nb_bins_per_channel )
    B = linearize_intensities(im_src, im_mask, nb_bins_per_channel);
    nb_channels = size(im_src,3);
    total_nb_bins = nb_bins_per_channel^nb_channels;
    h = accumarray(B(:), 1, [total_nb_bins 1]);
end