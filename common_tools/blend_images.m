% Superimposes a mask on an image with a desired amount of transparency. 
% Please note that the resulting image is the same that im_input when im_mask<=0.
% 
% Input arguments
%   * input:  multi-channels source image (uint8 format)
%   * mask:   mask image (uint8 format)
%   * alpha:  level of transparency (in [0,1])
% 
% Output arguments
%   * output : superimposed image
%
function output = blend_images( im_src, im_mask, alpha )
    %if any(size(im_src)~=size(im_mask))
    %    output = [];
    %    return;
    %end

    c = im2double(ind2rgb(double(im_mask), get_colormap()));
    if size(im_src,3)==1
        output = im2double(cat(3, im_src, im_src, im_src));
    else
        output = im2double(im_src);
    end
    alphas = alpha*ones(size(im_mask));
    alphas(im_mask<=0) = 1.0;
    alphas = cat(3, alphas, alphas, alphas);
    output = alphas.*output + (1.0-alphas).*c;
end