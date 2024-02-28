% This function takes as input a set of rectangular fragment images, rotate 
% them, then erode them and finally save them on the disk.
% 
% Inputs:
%   * im_frags3:               collection of fragment images (cell array)
%   * erosion_radius:          radius for eroding all extracted fragment images (integer, >=0)
%   * used_rotated_fragments:  flag indicating if fragments are rotated or not (boolean)
%   * angles_list:             list of possible angles of rotation (array)
%   * fragment_size:           size of fragments (2D vector of integers)
%   * frags_dir:               directory name where fragment images are saved (string)
% 
% Outputs:
%   * im_frags4:    list of resulting fragments (cell array)
%   * frag_angles:  list of rotation angles of resulting fragments (vector)
function [im_frags4,frag_angles] = save_rectangular_fragments_images( im_frags3, erosion_radius, use_rotated_fragments, angles_list, fragment_size, frags_dir )
    % We check if input arguments are valid
    if numel(im_frags3)==0
        error('the number of fragment images to save must be not empty');
    end

    im_frags4   = im_frags3;
    frag_angles = cell(1,numel(im_frags4));

    for n=1:numel(im_frags4)
        im_frag = im_frags4(n);
        im_frag = im_frag{1};

        if erosion_radius>0
            im_frag = im_frag((1+erosion_radius):end-erosion_radius, (1+erosion_radius):end-erosion_radius, :);
        end

        if use_rotated_fragments
            angle          = angles_list(randi(numel(angles_list)));
            frag_angles(n) = {angle};
            im_frag        = imrotate(im_frag, angle);
        else
            frag_angles(n) = {0.0};
        end

        ps           = round((sqrt(2)-1)*(ceil(fragment_size*0.5)-erosion_radius));
        im_alpha     = 255*ones(size(im_frag,1),size(im_frag,2));
        im_alpha     = padarray(im_alpha, ps, 0, 'both');
        im_frag      = padarray(im_frag, ps, 0, 'both');
        im_frags4(n) = {cat(3,im_frag,im_alpha)};
        frag_fn      = [frags_dir filesep sprintf('frag_eroded_%d.png', n-1)];

        imwrite(uint8(im_frag), frag_fn, 'Alpha', uint8(im_alpha));
    end
end