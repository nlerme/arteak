% Function returning the confidence map of a fragment based on color matching.
% 
% Inputs:
%   * fresco_hist_n:        normalized histogram of the fresco image
%   * fresco_hist_idx:      histogram indexes of the fresco image
%   * nb_bins_per_channel:  number of bins ber channel in fragment histogram (in N_{>0})
%   * im_frag_color:        multi-channels fragment image
%   * im_inner_circle:      binary image of the inscribed circle of fragment
%   * inner_circle_radius:  radius of the inscribed circle of fragment (in N_{>0})
%   * nb_rectangles:        number of rectangles used for approximating the shape of inscribed circle of fragment (in N_{>0})
% 
% Outputs
%   * im_map:  resulting confidence map (intensities are in [0,1])
function im_map = get_confidence_map( fresco_hist_n, fresco_hist_idx, nb_bins_per_channel, im_frag_color, im_inner_circle, inner_circle_radius, nb_rectangles )
    % We compute normalized histogram of inscribed circle of fragment image
    [frag_hist,~] = get_histogram(im_frag_color, im_inner_circle, nb_bins_per_channel);
    frag_hist_n = frag_hist / sum(frag_hist);

    % We compute intersection histogram between fresco histogram and fragment histogram
    inter_hist_n = min(frag_hist_n ./ (eps+fresco_hist_n), 1);

    % We back project the intersection histogram to the fresco image
    im_bp = inter_hist_n(fresco_hist_idx);

    % We compute the integral image of back projected image (in [0,1]) for multiple rectangular regions
    im_int = get_integral_images(im_bp);
    im_int = im_int{1};

    theta_range = linspace(0,pi/2,nb_rectangles+2);
    sx_range    = floor(inner_circle_radius*cos(theta_range(2:(end-1))));
    sy_range    = floor(inner_circle_radius*sin(theta_range(2:(end-1))));
    areas_range = (2*sx_range+1).*(2*sy_range+1);
    half_sx     = sx_range(1);
    half_sy     = sy_range(1);
    total_area  = areas_range(1);

    im_tmp1 = circshift(im_int, [-half_sx,-half_sy]);
    im_tmp2 = circshift(im_int, [-half_sx,half_sy+1]);
    im_tmp3 = circshift(im_int, [half_sx+1,-half_sy]);
    im_tmp4 = circshift(im_int, [half_sx+1,half_sy+1]);
    im_map  = (im_tmp1-im_tmp2-im_tmp3+im_tmp4);

    for k=2:nb_rectangles
        half_sx    = sx_range(k);
        half_sy    = sy_range(k);
        inter_sx   = sx_range(k);
        inter_sy   = sy_range(k-1);
        inter_area = (2*inter_sx+1)*(2*inter_sy+1);

        im_tmp1 = circshift(im_int, [-inter_sy,-inter_sx]);
        im_tmp2 = circshift(im_int, [-inter_sy,inter_sx+1]);
        im_tmp3 = circshift(im_int, [inter_sy+1,-inter_sx]);
        im_tmp4 = circshift(im_int, [inter_sy+1,inter_sx+1]);
        im_tmp5 = (im_tmp1-im_tmp2-im_tmp3+im_tmp4);

        im_tmp1 = circshift(im_int, [-half_sy,-half_sx]);
        im_tmp2 = circshift(im_int, [-half_sy,half_sx+1]);
        im_tmp3 = circshift(im_int, [half_sy+1,-half_sx]);
        im_tmp4 = circshift(im_int, [half_sy+1,half_sx+1]);
        im_map  = im_map + (im_tmp1-im_tmp2-im_tmp3+im_tmp4) - im_tmp5;

        total_area = total_area + areas_range(k) - inter_area;
    end

    im_map = max(0,im_map) / total_area;

    % We assign null confidence to pixels on image border (modulo some margin error)
    a       = ones(1,2)*round(inner_circle_radius)+2;
    b       = size(im_map)-round(inner_circle_radius)-2;
    im_mask = zeros(size(im_map));
    im_mask(a(1):b(1),a(2):b(2)) = 1;
    im_map(im_mask==0) = 0;
end