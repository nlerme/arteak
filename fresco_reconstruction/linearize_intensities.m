% Function returning linearized intensities of an image.
% 
% Inputs:
%   * im_src:               multi-channels source image
%   * im_mask:              binary mask image
%   * nb_bins_per_channel:  number of bins per channels (in N_{>0})
% 
% Outputs:
%   * B:  linearized image intensities
function B = linearize_intensities( im_src, im_mask, nb_bins_per_channel )
    nb_channels = size(im_src,3);
    A = floor((double(im_src)*(nb_bins_per_channel-1))/255.0);
    B = A(:,:,1);
    if ~isempty(im_mask)
        B = B(im_mask>0);
    end
    for k=2:nb_channels
        C = A(:,:,k);
        if ~isempty(im_mask)
            C = C(im_mask>0);
        end
        B = B+C*nb_bins_per_channel^(k-1);
    end
    B = B+1;
end