% Function correcting image intensities of a fragment based on its alpha channel
% 
% Inputs:
%   * im_frag_color_in:  uint8 color image of fragment
%   * im_frag_alpha   :  uint8 alpha channel of fragment
% 
% Outputs:
%   * im_frag_color_out:  uint8 color image of fragment
function im_frag_color_out = correct_fragment_image_intensities( im_frag_color_in, im_frag_alpha )
    if isempty(im_frag_color_in) || isempty(im_frag_alpha)
        im_frag_color_out = [];
    end

    im_frag_color_out = im_frag_color_in;

    for c=1:size(im_frag_color_out,3)
        im_tmp                   = double(im_frag_color_out(:,:,c));
        fresco_idx_t             = find(im_frag_alpha>0);
        im_tmp(fresco_idx_t)     = im_tmp(fresco_idx_t)./(1+double(im_frag_alpha(fresco_idx_t)));
        im_frag_color_out(:,:,c) = uint8(255.0*im_tmp);
    end
end