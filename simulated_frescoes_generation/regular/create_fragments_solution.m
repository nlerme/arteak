% This function returns a structure containing fragments and their relationships with nearby ones.
% 
% Inputs:
%   * frags_coords:        row/column index of fragments (cell array)
%   * frags_translations:  translation vectors of fragments (cell array)
%   * frags_angles:        rotation angles of fragments (cell array)
%   * true_idx:           index of fragments belonging to the ground truth (array)
% 
% Outputs:
%   * frags_sol:  solution composed of fragments (cell array)
function frags_sol = create_fragments_solution( frags_coords, frags_translations, frags_angles, true_idx )
    % We check input arguments
    if numel(frags_coords)~=numel(frags_translations) || numel(frags_translations)~=numel(frags_angles)
        error('The number of row/column indexes, translation vectors and rotation angles must be the same');
    end

    % We allocate memory for storing the solution
    frags_sol = cell(1,numel(true_idx));

    % We loop over true fragments
    for i=1:numel(true_idx)
        idx          = true_idx(i);
        translation  = frags_translations{idx};
        angle        = frags_angles{idx};
        frags_sol{i} = struct('idx', idx, 'translation', translation, 'angle', angle, 'neighbors', [], 'fresco_coords', [], 'frag_coords', [], 'color_idx', []);
    end

    % We compute neighboring relationship between adjacent fragments
    for i=1:numel(true_idx)
        idx1    = true_idx(i);
        coords1 = frags_coords{idx1};

        for j=1:numel(true_idx)
            idx2    = true_idx(j);
            coords2 = frags_coords{idx2};

            if norm(coords1-coords2)==1
                frags_sol{i}.neighbors = [frags_sol{i}.neighbors,j];
            end
        end
    end
end