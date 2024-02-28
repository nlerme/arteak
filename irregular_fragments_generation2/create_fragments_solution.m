% This function returns a structure containing fragments and their relationships with nearby ones.
% 
% Inputs:
%   * im_seg:              fragmentation image (matrix in uint32 format)
%   * frags_translations:  translation vectors of fragments (cell array)
%   * frags_angles:        rotation angles of fragments (cell array)
%   * frags_seg_idx:       
%   * true_idx:            indexes of fragments belonging to the ground truth (array)
% 
% Outputs:
%   * frags_sol:  solution composed of fragments (cell array)
function frags_sol = create_fragments_solution( im_seg, frags_translations, frags_angles, frags_seg_idx, true_idx )
    % We check input arguments
    if numel(frags_translations)~=numel(frags_angles) || numel(frags_translations)~=numel(frags_seg_idx)
        error('The number of translation vectors, rotation angles and fragmentation indexes must be the same');
    end

    % We allocate memory for storing the solution
    frags_sol = cell(1,numel(true_idx));

    for i=1:numel(true_idx)
        idx          = true_idx(i);
        translation  = frags_translations{idx};
        angle        = frags_angles{idx};
        frags_sol{i} = struct('idx', idx, 'translation', translation, 'angle', angle, 'neighbors', [], 'fresco_coords', [], 'frag_coords', [], 'color_idx', []);
    end

    % We compute neighboring fragments with respect to the initial fragmentation
    for i=1:numel(true_idx)
        im_frag    = (im_seg==frags_seg_idx{i});
        im_d_frag  = imdilate(im_frag, true(3));
        im_o_frags = ~im_frag & im_d_frag;
        n_seg_idx  = unique(im_seg(im_o_frags>0));

        for j=1:numel(true_idx)
            if numel(find(n_seg_idx==frags_seg_idx{j}))>0
                frags_sol{i}.neighbors = [frags_sol{i}.neighbors,j];
            end
        end
    end
end