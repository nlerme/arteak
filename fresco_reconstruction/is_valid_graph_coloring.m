% Function checking the validity of a graph coloring of fragments.
% 
% Inputs:
%   * frags:  collection of fragments (cell array)
% 
% Outputs:
%   * decision:  true if the graph coloring is valid, false otherwise
function decision = is_valid_graph_coloring( frags )
    if isempty(frags)
        decision = false;
        return;
    end

    decision = true;

    for i=1:numel(frags)
        for j=frags{i}.neighbors
            if i~=j && frags{i}.color_idx==frags{j}.color_idx
                %disp(sprintf('i=%d, j=%d | color_i=%d, color_j=%d', i, j, frags{i}.color_idx, frags{j}.color_idx));
                decision = false;
                return;
            end
        end
    end
end