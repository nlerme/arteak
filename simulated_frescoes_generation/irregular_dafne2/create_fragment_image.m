% This function create a rotated and scaled small image of a fragment with 
% alpha channel according to a provided region of a fragmentation. Fresco
% image is assumed to be larger than the fragmentation image. Most often,
% both are expected to be of the same size.
% 
% Inputs:
%   * im_fresco_color:     multi-channels fresco image (matrix in uint8 format)
%   * im_seg:              fragmentation image (matrix in uint32 format)
%   * frag_idx:            index of the fragment to extract in the fragmentation image (positive integer)
%   * rotation_angle:      angle of rotation of fragment image (in [0,360[)
%   * scale_factor:        scale factor of fragment image (>0)
%   * padding_factor:      factor by which fragment images are enlarged before saving; e.g. 1.2 means 20% of enlargement (>=0)
%   * interpolation_type:  type of interpolation (nearest, bilinear, bicubic, etc.)
% 
% Outputs:
%   * im_frag_color:  multi-channels fragment color image (matrix in uint8 format)
%   * im_frag_alpha:  alpha channel of fragment image (matrix in uint8 format)
%   * translation:    location of the fragment center in the fresco image (2D vector of reals)
function [im_frag_color,im_frag_alpha,translation] = create_fragment_image( im_fresco_color, im_seg, frag_idx, rotation_angle, ...
                                                                            scale_factor, padding_factor, interpolation_type )
    % We get the number of channels of the fresco image and the size of the fragmentation image
    img_seg_size = size(im_seg,[1,2]);
    nb_channels  = size(im_fresco_color,3);

    % We construct the binary image of the desired fragment in the fresco 
    % image and store pixel coordinates belonging to it
    im_fresco_frag_alpha = (im_seg==frag_idx);
    [rows,cols]          = find(im_fresco_frag_alpha);

    % We compute the centroid and of that region and the distance of the farthest pixel
    frag_centroid = round(mean([rows,cols]));
    frag_size     = max(sqrt(sum((frag_centroid-[rows,cols]).^2,2)));
    translation   = frag_centroid;

    % We set the half size of the fragment image as an even integer to avoid rounding with translation vector (see below)
    half_img_frag_size = 2*round(0.5*padding_factor*frag_size);

    % We compute the bounding box encompassing the fragment in the fresco image
    ul_corner = round(frag_centroid-half_img_frag_size);
    lr_corner = round(frag_centroid+half_img_frag_size);
    p         = max([1,1],ul_corner);
    q         = min(img_seg_size,lr_corner);

    % We compute the pixel coordinates in the fragment image encompassing the fragment
    img_frag_size   = lr_corner-ul_corner+1;
    img_frag_center = round(0.5*img_frag_size);
    pp              = p-frag_centroid+img_frag_center;
    qq              = q-frag_centroid+img_frag_center;

    % Finally, we construct the resulting image
    im_frag                              = zeros(img_frag_size(1), img_frag_size(2), nb_channels+1, 'uint8');
    im_frag(pp(1):qq(1),pp(2):qq(2),end) = im_fresco_frag_alpha(p(1):q(1),p(2):q(2));
    im_frag_alpha                        = double(im_frag(:,:,end));
    im_frag(:,:,end)                     = uint8(255.0*im_frag(:,:,end));

    for c=1:nb_channels
       im_frag(pp(1):qq(1),pp(2):qq(2),c) = im_fresco_color(p(1):q(1),p(2):q(2),c);
       im_frag(:,:,c)                     = uint8(double(im_frag(:,:,c)).*im_frag_alpha);
    end

    if rotation_angle~=0
        im_frag = imrotate(im_frag, rotation_angle, 'crop', interpolation_type);
    end

    if scale_factor~=1
       im_frag = imresize(im_frag, scale_factor, interpolation_type);
    end

    im_frag_color = im_frag(:,:,1:(end-1));
    im_frag_alpha = im_frag(:,:,end);
end