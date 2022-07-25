% Function returning the true fragment index of ground truth given fragment
% index, empty set otherwise.
% 
% Inputs:
%   * frags_gt:  true fragments belonging to ground truth (cell array)
%   * frag_idx:  fragment index (in [1,#total-nb-fragments])
% 
% Outputs:
%   * frag_idx2:  index (if found) or [] (if not found)
function frag_idx2 = is_fragment_in_gt( frags_gt, frag_idx )
    frag_idx2 = find(cellfun(@(x) x.idx, frags_gt)==frag_idx);
end