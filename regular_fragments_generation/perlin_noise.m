% This function returns a perlin-like image as a sum of weighted Gaussian-filtered noise images.
% 
% Inputs:
%   * img_size:     output image size (2D column or row vector)
%   * nb_octaves:   number of octaves (>0)
%   * persistence:  scalar used for weighting filtered images (in [0,1])
% 
% Outputs:
%   * im_res:  resulting image with intensities in [0,1]
function im_res = perlin_noise( img_size, nb_octaves, persistence )
    % We allocate memory for storing results
    im_res = zeros(img_size);
    im_uni = rand(img_size);

    % We loop over octaves and add their contribution to the final result. 
    % Notice that the contribution decreases 
    for k=0:(nb_octaves-1)
        sigma       = 2^k;
        filter_size = 2*ceil(10*sigma)+1; % filter size is large to avoid block artifacts
        amplitude   = 1/(persistence^k);
        im_res      = im_res + amplitude*imgaussfilt(im_uni, sigma, 'FilterSize', filter_size, 'padding', 'symmetric');
    end

    % We normalize the output image and convert in uint8 format
    im_res = (im_res-min(im_res(:)))./(max(im_res(:))-min(im_res(:)));
end