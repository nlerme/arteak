% This function returns a processed fresco image with its alpha channel.
% 
% Inputs:
%   * fresco_fn:             filename of the fresco image (string)
%   * cb_pts:                pixel coordinates of the N detected corners of the checkerboard (matrix of reals of size Nx2)
%   * scaling_factor:        fresco image is typically downscaled by this factor to speed up computations (!=0)
%   * grayscale_conversion:  convert fresco image in grayscale if true (true or false)
%   * detection_threshold:   threshold for detecting fragments in fresco image (in [0,255])
%   * connectivity:          connectivity used for morphological operators (4 or 8)
% 
% Outputs:
%   * im_fresco_color:  RGB/grayscale fresco image (uint8 matrix)
%   * im_fresco_alpha:  alpha channel of fresco image (boolean matrix)
function [im_fresco_color,im_fresco_alpha] = process_fresco_image( fresco_fn, cb_pts, scaling_factor, grayscale_conversion, detection_threshold, connectivity )
    % We load fresco image
    [im_fresco_color,~] = load_image(fresco_fn, grayscale_conversion);

    if isempty(im_fresco_color)
        error(sprintf('Unable to find the fresco image %s', fresco_fn));
    end

    % We resize the image to speed up computations
    if scaling_factor~=1
        im_fresco_color = imresize(im_fresco_color, scaling_factor);
        cb_pts          = scaling_factor*cb_pts;
    end

    % We get size and number of channels of fresco image
    img_size    = size(im_fresco_color, [1,2]);
    nb_channels = size(im_fresco_color,3);

    % We roughly estimate the boundaries of fragments by thresholding the grayscale fresco image 
    % and applying morphological operators. The connected component including the corners is discarded
    im_fresco_alpha = rgb2gray(im_fresco_color)>detection_threshold;
    im_fresco_alpha = imopen(im_fresco_alpha, strel('disk', double(round(0.005*min(img_size))), 0));
    im_fresco_alpha = imfill(im_fresco_alpha, connectivity, 'holes');
    im_markers      = zeros(img_size, 'logical');
    idx             = sub2ind(img_size, round(cb_pts(:,2)), round(cb_pts(:,1)));
    im_markers(idx) = 1;
    im_fresco_alpha = im_fresco_alpha-imreconstruct(im_markers, im_fresco_alpha, connectivity);
    im_fresco_alpha = uint8(255*im_fresco_alpha);

    % We assign a null intensity for pixels in masked regions
    im_fresco_color = uint8(double(im_fresco_color).*repmat(double(im_fresco_alpha>0), [1,1,nb_channels]));
end