% This function returns a perlin-like image as a sum of weighted Gaussian-filtered noise images.
% 
% Inputs:
%   * image_size:   output image size (2D vector of integers)
%   * nb_octaves:   number of octaves (>0)
%   * persistence:  scalar used for weighting filtered images (in [0,1])
% 
% Outputs:
%   * im_result:  resulting image with intensities in [0,1]
function im_result = perlin_noise( image_size, nb_octaves, persistence )
    % We generate Gaussian noise with intensities in [0,1]
    im_noise = rescale(randn(image_size), 0.0, 1.0);

    % We loop over octaves and add their (decreasing) contribution
    im_result = zeros(image_size);

    for k=0:(nb_octaves-1)
        sigma_g     = 2^k;
        filter_size = 2*ceil(10*sigma_g)+1; % filter size is set large enough to avoid block artifacts
        amplitude   = 1/(persistence^k);
        im_result   = im_result + amplitude*imgaussfilt(im_noise, sigma_g, 'FilterSize', filter_size, 'padding', 'symmetric');
    end

    % We normalize the output image in [0,1]
    im_result = rescale(im_result, 0.0, 1.0);
end