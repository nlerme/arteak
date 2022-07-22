% This function generates a binary image indicating degraded areas.
% Currently, the function does not realy on the image content. This task is
% left for future work.
% 
% Inputs:
%   * im_src:            RGB fresco image (uint8)
%   * degradation_rate:  number indicating the amount of degradation of the fresco (in [0,1])
% 
% Outputs:
%   * im_alpha:  degradation map taking for instance 255 when
%                degradation_rate is 0 and 0 when degradation_rate is 1
function im_alpha = get_degraded_fresco_parts( im_src, degradation_rate )
    % We check if input arguments are valid
    if degradation_rate<0.0 || degradation_rate>1.0
        error('The degradation rate must be in [0,1]');
    end

    fresco_size = [size(im_src,1), size(im_src,2)];

    if degradation_rate==0
        im_alpha = 255*ones(fresco_size, 'uint8');
        return;
    end

    if degradation_rate==1
        im_alpha = zeros(fresco_size, 'uint8');
        return;
    end

    % We compute the perlin-like image using default parameters
    im_noise = perlin_noise(fresco_size, 8, 0.3);

    % We compute the cumulative histogram of the noise image
    nb_bins = 256;
    [h,~]   = imhist(im_noise, nb_bins);
    ch      = cumsum(h / sum(h));

    % We look for the scalar for which the cumulative histogram of the image noise is the closest from the desired fresco degradation rate
    z             = abs(ch-degradation_rate);
    [~,threshold] = min(z);
    threshold     = threshold/nb_bins;

    % Finally, we return the input fresco image together with the thresholded noise image as alpha channel
    im_alpha = uint8(255*(im_noise>=threshold));
end