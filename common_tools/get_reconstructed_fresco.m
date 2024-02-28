% Function returning the fresco reconstructed from fragments using ground
% truth (consistency check). This function should be only used for
% visualization purposes.
% 
% Inputs:
%   * fresco_size:         size of the fresco image (2D vector of positive integers)
%   * nb_channels:         number of the channels in the fresco image (positive integer)
%   * frags_infos:         infos about fragments (cell array)
%   * frags_sol:           solution composed of fragments (cell array)
%   * interpolation_type:  interpolation type (string; e.g. nearest, bilinear, bicubic, etc.)
%   * background_color:    background color of reconstructed fresco (in {0,...,255}^c)
% 
% Outputs:
%   * im_filled_frags:  reconstructed fresco with numbered filled fragments (uint64 image)
%   * im_bnd_frags:     reconstructed fresco with numbered boundaries of fragments (uint64 image)
%   * im_rec_frags:     reconstructed fresco with colored fragments (uint8 color image)
function [im_filled_frags,im_bnd_frags,im_rec_frags] = get_reconstructed_fresco( fresco_size, nb_channels, frags_infos, frags_sol, interpolation_type, background_color )
    % We allocate memory for storing results
    im_filled_frags = zeros(fresco_size, 'uint64');
    im_bnd_frags    = zeros(fresco_size, 'uint64');
    im_rec_frags    = ones([fresco_size,nb_channels], 'uint8');

    for k=1:nb_channels
        im_rec_frags(:,:,k) = im_rec_frags(:,:,k)*background_color(k);
    end

    % We loop over fragments in the solution
    for k=1:length(frags_sol)
        % We get the index and image content of fragment
        idx           = frags_sol{k}.idx;
        im_frag_color = frags_infos{idx}.color;
        im_frag_alpha = frags_infos{idx}.alpha;

        % We get corresponding pixel coordinates in fresco image and fragment image
        if isempty(frags_sol{k}.fresco_coords) || isempty(frags_sol{k}.frag_coords)
            [fresco_coords,frag_coords] = get_transformed_fragment(im_frag_alpha, frags_sol{k}.translation, frags_sol{k}.angle, fresco_size);
        else
            fresco_coords = frags_sol{k}.fresco_coords;
            frag_coords   = frags_sol{k}.frag_coords;
        end

        % If the fragment lies outside, we discard it from the reconstructed fresco
        if isempty(fresco_coords) || isempty(frag_coords)
            continue;
        end

        % We construct binary image of registered fragment
        fresco_idx                  = sub2ind(fresco_size, fresco_coords(:,1), fresco_coords(:,2));
        im_frag_t_alpha             = zeros(fresco_size, 'logical');
        im_frag_t_alpha(fresco_idx) = 1;

        % We add resulting fragment image to grayscale fresco reconstruction
        im_filled_frags(fresco_idx) = k;

        % We add resulting fragment image to binary fresco reconstructions
        im_bnd_frag               = (im_frag_t_alpha-imerode(im_frag_t_alpha,strel('square',3)))>0;
        fresco_idx2               = find(im_bnd_frag>0);
        im_bnd_frags(fresco_idx2) = uint64(k*im_bnd_frag(fresco_idx2));

        % We construct color image of registered fragment and add it to color fresco reconstruction
        for c=1:nb_channels
            im_tmp              = im_frag_color(:,:,c);
            im_tmp2             = im_rec_frags(:,:,c);
            im_tmp2(fresco_idx) = interp2(double(im_tmp), frag_coords(:,2), frag_coords(:,1), interpolation_type);
            im_rec_frags(:,:,c) = im_tmp2;
        end
    end
end
