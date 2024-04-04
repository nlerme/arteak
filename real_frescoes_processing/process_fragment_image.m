% This function returns a processed fragment image with its alpha channel.
% 
% Inputs:
%   * frag_fn:               filename of the fragment image (string)
%   * cb_pts:                pixel coordinates of the N detected corners of the checkerboard (matrix of reals of size Nx2)
%   * scaling_factor:        fragment image is typically downscaled by this factor to speed up computations (!=0)
%   * grayscale_conversion:  convert fragment image in grayscale if true (true or false)
%   * detection_threshold:   threshold for detecting fragment in fragment image (in [0,255])
%   * connectivity:          connectivity used for morphological operators (4 or 8)
%   * padding_factor:        the size of the resulting image is enlarged by factor (>=1)
% 
% Outputs:
%   * im_frag_color:  RGB/grayscale fragment image (uint8 matrix)
%   * im_frag_alpha:  alpha channel of fragment image (boolean matrix)
function [im_frag_color,im_frag_alpha] = process_fragment_image( frag_fn, cb_pts, scaling_factor, grayscale_conversion, detection_threshold, connectivity, padding_factor )
    % We load the fragment image
    [im_frag_color,~] = load_image(frag_fn, grayscale_conversion);

    if isempty(im_frag_color)
        error(sprintf('Unable to load fragment image %s', frag_fn));
    end

    % We resize the image to speed up computations
    if scaling_factor~=1
        im_frag_color = imresize(im_frag_color, scaling_factor);
        cb_pts        = scaling_factor*cb_pts;
    end

    % We get size and number of channels of fragment image
    img_size    = size(im_frag_color, [1,2]);
    nb_channels = size(im_frag_color,3);

    % We roughly estimate the boundaries of objects by thresholding the grayscale fragment image 
    % and applying morphological operators. The connected component including the corners is discarded
    im_frag_alpha   = rgb2gray(im_frag_color)>detection_threshold;
    im_frag_alpha   = imopen(im_frag_alpha, strel('disk', double(round(0.005*min(img_size))), 0));
    im_frag_alpha   = imfill(im_frag_alpha, connectivity, 'holes');
    im_markers      = zeros(img_size, 'logical');
    idx             = sub2ind(img_size, round(cb_pts(:,2)), round(cb_pts(:,1)));
    im_markers(idx) = 1;
    im_frag_alpha   = im_frag_alpha-imreconstruct(im_markers, im_frag_alpha, connectivity);

    % We only keep the largest connected component
    cc                           = bwconncomp(im_frag_alpha, connectivity);
    nb_pixels                    = cellfun(@numel, cc.PixelIdxList);
    [~,idx]                      = max(nb_pixels);
    im_tmp                       = zeros(img_size, 'logical');
    im_tmp(cc.PixelIdxList{idx}) = 1;
    im_frag_alpha                = im_tmp;

    % We look pixel coordinates of the fragment and compute its centroid and size
    [rows,cols]   = find(im_frag_alpha>0);
    frag_centroid = round(mean([rows,cols]));
    frag_size     = max(sqrt(sum(([rows,cols]-frag_centroid).^2,2)));

    % We set the half size of the fragment image as an even integer to avoid rounding artifacts with translation vector (see below)
    half_img_frag_size = 2*round(0.5*padding_factor*frag_size);

    % We compute the bounding box encompassing the fragment
    ul_corner = round(frag_centroid-half_img_frag_size);
    lr_corner = round(frag_centroid+half_img_frag_size);
    p         = max([1,1],ul_corner);
    q         = min(img_size,lr_corner);

    % We compute the pixel coordinates of the fragment image encompassing the fragment
    img_frag_size   = lr_corner-ul_corner+1;
    img_frag_center = round(0.5*img_frag_size);
    pp              = p-frag_centroid+img_frag_center;
    qq              = q-frag_centroid+img_frag_center;

    % We trim borders on alpha channel
    im_tmp                          = zeros(img_frag_size, 'logical');
    im_tmp(pp(1):qq(1),pp(2):qq(2)) = im_frag_alpha(p(1):q(1),p(2):q(2));
    im_frag_alpha                   = uint8(255*im_tmp);

    % We trim borders on remaining ones
    im_tmp = zeros(img_frag_size(1), img_frag_size(2), nb_channels, 'uint8');

    for c=1:nb_channels
        im_tmp2                          = zeros(img_frag_size(1), img_frag_size(2), 'uint8');
        im_tmp2(pp(1):qq(1),pp(2):qq(2)) = im_frag_color(p(1):q(1),p(2):q(2),c);
        im_tmp(:,:,c)                    = uint8(double(im_tmp2).*double(im_frag_alpha>0));
    end

    im_frag_color = im_tmp;
end