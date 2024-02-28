% This function returns a structure containing fragments and their 
% relationships with adjacent ones.
% 
% Inputs:
%   * frag_coords:        2D indexes of fragments (cell array)
%   * frag_translations:  2D translation vectors (cell array)
%   * frag_angles:        angles of rotation (cell array)
%   * true_idx:           indexes of fragments belonging to the ground truth (array)
% 
% Outputs:
%   * frags_sol:  solution composed of fragments (cell array)
function frags_sol = get_fragments( frag_coords, frag_translations, frag_angles, true_idx )
    % We check input arguments
    if numel(frag_coords)~=numel(frag_translations) || numel(frag_translations)~=numel(frag_angles)
        frags_sol = {};
        return;
    end

    % We loop over true fragments
    frags_sol = cell(1,numel(true_idx));

    for i=1:numel(true_idx)
        idx          = true_idx(i);
        translation  = frag_translations(idx);
        translation  = translation{1};
        angle        = frag_angles(idx);
        angle        = -angle{1};
        frags_sol{i} = struct('idx', idx, 'translation', translation, 'angle', angle, 'neighbors', [], 'fresco_coords', [], 'frag_coords', [], 'color_idx', []);
    end

    for i=1:numel(true_idx)
        idx1    = true_idx(i);
        coords1 = frag_coords(idx1);
        coords1 = coords1{1};

        for j=1:numel(true_idx)
            idx2    = true_idx(j);
            coords2 = frag_coords(idx2);
            coords2 = coords2{1};

            % If the L1 norm of the difference of block coordinates of two fragments is equal to one, we mark them as neighbors
            if norm(coords1-coords2)==1
                frags_sol{i}.neighbors = [frags_sol{i}.neighbors,j];
            end
        end
    end
end