% This function save a set of fragments images in a given directory.
% 
% Inputs:
%   * frags_infos:  collection of fragments (cell array)
%   * frags_dir:    directory where fragment images will be saved (string)
% 
% Outputs:
%   None
function save_fragment_images( frags_infos, frags_dir )
    % We check if arguments are ok
    if isempty(frags_infos) || isempty(frags_dir)
        error('The set of fragments and the fragments directory must be not empty');
    end

    % We save fragment images
    for k=1:numel(frags_infos)
        fn = [frags_dir filesep sprintf('frag_eroded_%d.png', k-1)];
        imwrite(frags_infos{k}.color, fn, 'Alpha', frags_infos{k}.alpha);
    end
end