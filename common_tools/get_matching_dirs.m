% Function returning the directories matching a given pattern.
% 
% Inputs:
%   * directory:  directory where the search is performed
%   * pattern:    regular expression for matching the desired directories
% 
% Outputs:
%   * dirs_list:  list of matched directories
function dirs_list = get_matching_dirs(path, pattern)
    tmp = dir(path);
    dirs_list = {};

    for i={tmp([tmp.isdir]).name}
        c = regexp(i, pattern, 'match', 'ignorecase');
        if length(c{:})>0 && ~strcmp(i, '.') && ~strcmp(i, '..')
            f = [sprintf('%s%s%s', path, filesep, i{1})];
            dirs_list = {dirs_list{:},f};
        end
    end

    if ~isempty(dirs_list)
        dirs_list = natsortfiles(dirs_list);
    end
end