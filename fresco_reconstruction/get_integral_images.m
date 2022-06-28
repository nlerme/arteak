% Function returning integral images per channel.
% 
% Inputs:
%   * im_src:  multi-channels source image
% 
% Outputs:
%   * im_sums:  cell array with integral images (one per channel)
function im_sums = get_integral_images( im_src )
    nb_channels = size(im_src,3);
    im_sums     = cell(1, nb_channels);

    for c=1:nb_channels
        im_tmp1    = im_src(:,:,c);
        im_tmp2    = integralImage(im_tmp1);
        im_sums{c} = im_tmp2(2:end,2:end);
    end
end