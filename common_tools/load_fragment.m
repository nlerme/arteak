% This function loads and returns information about a fragment
function frag_info = load_fragment( filename, fresco_nb_channels, mean_inter_fragments_distance, interpolation_type )
    % We allocate memory for output result
    frag_info = struct();

    % We load fragment image
    [im_frag_color,im_frag_alpha] = load_image(filename, false);

    if isempty(im_frag_color) || isempty(im_frag_alpha)
        return;
    end

    % We pad fragment image with zeros
    im_frag_color = padarray(im_frag_color, [1,1], 'both');
    im_frag_alpha = padarray(im_frag_alpha, [1,1], 'both');

    % We check if the number of channels of the fragment image is the same as the fresco image
    if fresco_nb_channels ~= size(im_frag_color,3)
        error('The number of channels of any fragment image must be the same as the fresco image');
    end

    % We threshold alpha channel to ensure that it is a binary image
    im_frag_alpha = (im_frag_alpha>0);

    % We slightly erode the fragment to cope with interpolation issues
    im_frag_alpha = imerode(im_frag_alpha, strel('disk', 1));
    frag_idx      = find(im_frag_alpha==0);

    for c=1:nb_channels
        im_tmp               = im_frag_color(:,:,c);
        im_tmp(frag_idx)     = 0;
        im_frag_color(:,:,c) = im_tmp;
    end

    % We compute area and mean standard deviation of fragment
    frag_area_t = sum(im_frag_alpha(:));
    [rows,cols] = find(im_frag_alpha);
    frag_int    = get_intensities(im_frag_color, [rows,cols], interpolation_type);
    frag_std    = mean(std(frag_int, 0, 1));

    % We compute inscribed and circumscribed circles
    [outer_circle_center,outer_circle_radius] = get_outer_circle(im_frag_alpha, 200, false); % nb_iterations = 200
    [inner_circle_center,inner_circle_radius] = get_inner_circle(im_frag_alpha, outer_circle_center);

    % If the fragment is too small, we pad it again and update centers of circles
    extrapolation_distance = (3*mean_inter_fragments_distance);      % extrapolation gap (must be larger than 2*mean_inter_fragments_distance)
    margin                 = (2*extrapolation_distance);             % overall gap (must be larger than 2*extrapolation_distance)
    d                      = get_largest_distance(inner_circle_center, im_frag_alpha);
    fs                     = round(d+margin-0.5*min(size(im_frag_alpha)));

    if fs>0
        padding             = double([fs,fs]);
        im_frag_color       = padarray(im_frag_color, padding, 'both');
        im_frag_alpha       = padarray(im_frag_alpha, padding, 'both');
        inner_circle_center = inner_circle_center + padding;
        outer_circle_center = outer_circle_center + padding;
    end

    % We shift fragment to the inner circle center for convenience
    frag_size           = size(im_frag_alpha);
    offset              = round(0.5*frag_size)-inner_circle_center;
    im_frag_alpha       = imtranslate(im_frag_alpha, flip(offset), 'method', interpolation_type);
    im_frag_color       = imtranslate(im_frag_color, flip(offset), 'method', interpolation_type);
    outer_circle_center = outer_circle_center-inner_circle_center+round(0.5*frag_size);
    inner_circle_center = round(0.5*frag_size);

    % We convert fragment image in grayscale levels
    im_frag_gray = im2double(rgb2gray(im_frag_color));

    % We compute the dilated domain of the fragment
    im_frag_alpha_d = imdilate(im_frag_alpha, strel('disk', extrapolation_distance));

    % We do color extrapolation on resulting fragment
    im_frag_color_ext = inpaintExemplar(im2double(im_frag_color), ~im_frag_alpha, 'FillOrder', 'tensor', 'PatchSize', [5,5]);
    frag_idx          = find(im_frag_alpha_d==0);
    for c=1:nb_channels
       im_tmp = im_frag_color_ext(:,:,c);
       im_tmp(frag_idx) = 0;
       im_frag_color_ext(:,:,c) = im_tmp;
    end

    % We convert extrapolated fragment image in grayscale levels
    im_frag_gray_ext = rgb2gray(im_frag_color_ext);

    % We compute gradients of grayscale extrapolated fragment image
    [im_frag_gray_ext_grad_x,im_frag_gray_ext_grad_y] = imgradientxy(im_frag_gray_ext, 'sobel');

    % We compute nearest-neighbor transform to the domain of the fragment
    [~,im_frag_alpha_nn]                  = bwdist(im_frag_alpha, 'euclidean');
    [im_frag_alpha_nny,im_frag_alpha_nnx] = ind2sub(size(im_frag_alpha_nn), im_frag_alpha_nn);

    % We store and display the extracted elements
    frag_info = struct('alpha', im_frag_alpha, 'alpha_d', im_frag_alpha_d, 'color', im_frag_color, 'gray', im_frag_gray, 'gray_ext', im_frag_gray_ext, ...
                       'nny', im_frag_alpha_nny, 'nnx', im_frag_alpha_nnx, 'gray_ext_grad_x', im_frag_gray_ext_grad_x, 'gray_ext_grad_y', im_frag_gray_ext_grad_y, 'area', frag_area_t, ...
                       'std', frag_std, 'size', frag_size, 'outer_circle_center', outer_circle_center, 'outer_circle_radius', outer_circle_radius, ...
                       'inner_circle_center', inner_circle_center, 'inner_circle_radius', inner_circle_radius, 'offset', offset);
end