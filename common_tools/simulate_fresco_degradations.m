% This function simulates degradations of a fresco.
% 
% Inputs:
%   * im_fresco_color:       RGB/grayscale fresco image (matrix in uint8 format)
%   * noise_std:             standard deviation of Gaussian noise (>0)
%   * palette_size:          number of colors used for fading (integer in {1,...,256})
%   * missing_parts_rates:   range of degradation rates (vector of reals in [0,1])
%   * missing_parts_params:  parameters of the degradation (struct)
% 
% Outputs:
%   * im_noisy:   noisy RGB/grayscale fresco image (matrix in uint8 format)
%   * im_deg:     degradation map (uint8 image)
%   * im_alphas:  stack of degraded fresco images (uint8 images where pixel intensity is set to 255 when degradation rate is 0)
function [im_noisy,im_deg,im_alphas] = simulate_fresco_degradations( im_fresco_color, noise_std, palette_size, missing_parts_rates, missing_parts_params )
    % We get the size of the fresco image
    fresco_size = size(im_fresco_color, [1,2]);

    % We assign the output image wit the input one
    im_noisy = im_fresco_color;

    % We reduce the number of available image intensities on each channel of the fresco image to mimic image fading
    if palette_size~=256
        [im_seg,lab_centroids] = imsegkmeans(im2single(rgb2lab(im_noisy)), palette_size);
        rgb_centroids          = max(0,min(1,im2double(lab2rgb(lab_centroids))));
        im_noisy               = label2rgb(im_seg, rgb_centroids);
    end

    % We apply Gaussian noise on the fresco image
    if noise_std>0
        im_noisy = uint8(255.0*imnoise(im2double(im_noisy), 'gaussian', 0.0, noise_std));
    end

    % We allocate memory for storing output results
    im_alphas = zeros(fresco_size(1), fresco_size(2), numel(missing_parts_rates), 'uint8');

    % We compute the noise image
    if strcmp(missing_parts_params.type, 'perlin')
        im_noise = perlin_noise(fresco_size, missing_parts_params.nb_octaves, missing_parts_params.persistence);
    elseif strcmp(missing_parts_params.type, 'power_law')
        im_noise = power_law_noise(fresco_size, missing_parts_params.exponent);
    else
        error('The degradation rate must be in [0,1]');
    end

    % We compute the cumulative histogram of the noise image
    nb_bins = 256;
    [h,~]   = imhist(im_noise, nb_bins);
    ch      = cumsum(h / sum(h));

    % We loop over degradation rates
    for k=1:numel(missing_parts_rates)
        degradation_rate = missing_parts_rates(k);

        if degradation_rate<0.0 || degradation_rate>1.0
            error('The degradation rate must be in [0,1]');
        else
            % We look for bin for which the cumulative histogram is the closest to the degradation rate
            z             = abs(ch-degradation_rate);
            [~,threshold] = min(z);
            threshold     = threshold/nb_bins;

            % Finally, we return the input fresco image together with the thresholded noise image as alpha channel
            im_alphas(:,:,k) = uint8(255*(im_noise>=threshold));
        end
    end

    im_deg = uint8(255.0*im_noise);
end
