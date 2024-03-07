% This function simulates degradations on a set of fragment images.
% 
% Inputs:
%   * im_frags:       grayscale/RGB fragment images (cell array)
%   * erosion_radii:  erosion radius per fragment (vector of non-negative integers)
%   * noise_stds:     standard deviation of Gaussian noise per fragment (vector of positive reals)
% 
% Outputs:
%   * im_result:  degraded fragment images (cell array)
function im_result = simulate_fragments_degradations( im_frags, erosion_radii, noise_stds )
    % We check if the number of elements in all structures if the same
    if numel(im_frags)~=numel(erosion_radii) || numel(im_frags)~=numel(noise_stds)
        error('The number of elements in all arrays must be the same');
    end

    % We loop over fragment images
    im_result = im_frags;

    for k=1:numel(im_result)
        % Erosion
        if erosion_radii(k)>0
            im_result{k}.alpha = imerode(im_result{k}.alpha, strel('disk', erosion_radii(k), 0));
        end

        % Gaussian noise
        if noise_stds(k)>0
            im_result{k}.color = uint8(255.0*imnoise(im2double(im_result{k}.color), 'gaussian', 0.0, noise_stds(k)));
        end

        % Masking color channels with alpha channel
        im_result{k}.color = uint8(double(im_result{k}.color).*double(repmat(im_result{k}.alpha, [1,1,size(im_result{k}.color,3)])>0));
    end
end