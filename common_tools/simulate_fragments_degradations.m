% This function simulates degradations on a set of fragment images.
% 
% Inputs:
%   * frags_infos:    information about fragments (cell array)
%   * erosion_radii:  erosion radius per fragment (vector of non-negative integers)
%   * noise_stds:     standard deviation of Gaussian noise per fragment (vector of positive reals)
%   * palette_sizes:  reduced number of colors for all channels per fragment (vector with entries in {1,...,256})
% 
% Outputs:
%   * im_result:  degraded fragment images (cell array)
function im_result = simulate_fragments_degradations( frags_infos, erosion_radii, noise_stds, palette_sizes )
    % We check if the number of elements in all structures if the same
    if numel(frags_infos)~=numel(erosion_radii) || numel(frags_infos)~=numel(noise_stds) || numel(frags_infos)~=numel(palette_sizes)
        error('The number of elements in all arrays must be the same');
    end

    % We loop over fragment images
    im_result = frags_infos;

    for k=1:numel(im_result)
        % Erosion
        if erosion_radii(k)>0
            im_result{k}.alpha = imerode(im_result{k}.alpha, strel('disk', erosion_radii(k), 0));
        end

        % We reduce the number of available image intensities on each channel of the fresco image to mimic image fading
        if palette_sizes(k)~=256
            [im_seg,lab_centroids] = imsegkmeans(im2single(rgb2lab(im_result{k}.color)), palette_sizes(k));
            rgb_centroids          = max(0,min(1,im2double(lab2rgb(lab_centroids))));
            im_result{k}.color     = label2rgb(im_seg, rgb_centroids);
        end

        % Gaussian noise
        if noise_stds(k)>0
            im_result{k}.color = uint8(255.0*imnoise(im2double(im_result{k}.color), 'gaussian', 0.0, noise_stds(k)));
        end

        % Masking color channels with alpha channel
        im_result{k}.color = uint8(double(im_result{k}.color).*double(repmat(im_result{k}.alpha, [1,1,size(im_result{k}.color,3)])>0));
    end
end