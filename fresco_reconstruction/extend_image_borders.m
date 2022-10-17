% Function extending image borders of a color image outside a delimited region.
% 
% Inputs:
%   * im_frag_alpha:  binary image
%   * im_frag_color:  multi-channels image
% 
% Outputs:
%   * im_result: resulting image
function im_result = extend_image_borders( im_frag_alpha, im_frag_color )
    [~,im_idx] = bwdist(im_frag_alpha, 'euclidean');
    im_result  = im_frag_color;

    for k=1:size(im_result,3)
        im_tmp                   = im_frag_color(:,:,k);
        im_tmp(im_frag_alpha==0) = 0;
        im_result(:,:,k)            = im_tmp(im_idx);
    end
end