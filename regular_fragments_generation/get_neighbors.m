% This function returns neighboring relationships as a symetric matrix
function neighbors = get_neighbors( frag_coords, true_idx )
    % We create an empty symmetric matrix
    neighbors = zeros(numel(frag_coords));

    % We loop over elements of the matrix
    for idx1=true_idx
        coords1 = frag_coords(idx1);
        coords1 = coords1{1};

        for idx2=true_idx
            coords2 = frag_coords(idx2);
            coords2 = coords2{1};

            % If the L1 norm of the difference of block coordinates of two fragments is equal to one, we mark them as neighbors
            if norm(coords1-coords2)==1
                neighbors(idx1,idx2) = 1;
                neighbors(idx2,idx1) = 1;
            end
        end
    end
end