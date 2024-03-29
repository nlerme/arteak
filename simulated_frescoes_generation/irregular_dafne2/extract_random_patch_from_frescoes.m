% This function randomly extracts a [rectangular] region from a collection 
% of fresco images. The fresco image is chosen uniformly at random (modulo 
% the fact that it is large enough from which it is extracted).
% 
% Inputs:
%   * im_src_seg:          fragmentation image (matrix in uint32 format)
%   * frag_idx:            index of the fragment to extract in the fragmentation image (positive integer)
%   * filenames:           full filename of fresco images (cell array)
%   * nb_attempts:         number of attempts before exiting the function (>0)
%   * to_grayscale:        flag indicating if resulting image is converted to grayscale (true or false)
%   * scale_factor_range:  range of scale factor by which fragment image is scaled (2D vector of positive reals)
%   * padding_factor:      factor by which fragment images are enlarged before saving; e.g. 1.2 means 20% of enlargement (>=0)
%   * interpolation_type:  type of interpolation (nearest, bilinear, bicubic, etc.)
% 
% Outputs:
%   * im_frag_color:  multi-channels fragment color image (matrix in uint8 format)
%   * im_frag_alpha:  alpha channel of fragment image (matrix in uint8 format)
function [im_frag_color,im_frag_alpha] = extract_random_patch_from_frescoes( im_src_seg, frag_idx, filenames, nb_attempts, to_grayscale, ...
                                                                             scale_factor_range, padding_factor, interpolation_type )
    % We loop for a (expected small) couple of iterations
    src_fresco_size = size(im_src_seg);
    count           = 0;
    finished        = false;

    while ~finished
        % It the number of attempts is reached, we return an empty fragment image
        if count>=nb_attempts
            im_frag_color = [];
            im_frag_alpha = [];
            finished      = true;
            continue;
        end

        % We select a fresco image uniformly at random
        ri                  = randi([1,numel(filenames)]);
        [im_fresco_color,~] = load_image(filenames{ri}, to_grayscale);

        % If we are unable to load it, we retry
        if isempty(im_fresco_color)
            nb_attempts = nb_attempts+1;
            continue;
        end

        % We resize fresco image to approximately match the scale of 
        % fragment image from which it comes from (orientation of 
        % fresco images is assumed to be correct)
        fresco_size     = size(im_fresco_color, [1,2]);
        min_diff_size   = min(fresco_size-src_fresco_size);
        new_fresco_size = fresco_size-min_diff_size;
        im_fresco_color = imresize(im_fresco_color, new_fresco_size);

        % Finally, we randomly extract a patch from the resized fresco image
        rotation_angle                = rand_bounds(0.0, 360.0); % CAUTION: rotation is counterclockwise
        scale_factor                  = rand_bounds(scale_factor_range(1), scale_factor_range(2));
        [im_frag_color,im_frag_alpha] = create_fragment_image(im_fresco_color, im_src_seg, frag_idx, rotation_angle, scale_factor, padding_factor, interpolation_type);
        finished                      = true;
    end
end