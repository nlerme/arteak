% Function returning the files matching a given pattern.
%
% Inputs:
%   * path:    location where the search is performed
%   * pattern: regular expression for matching the desired files
% 
% Outputs:
%   * files_list:  list of mtched files
function files_list = get_matching_files(path, pattern)
    tmp = dir(path);
    files_list = {};

    for i={tmp(~[tmp.isdir]).name}
        c = regexp(i, pattern, 'match', 'ignorecase');
        if length(c{:})>0
            f = [sprintf('%s%s%s', path, filesep, i{1})];
            files_list = {files_list{:},f};
        end
    end

    if ~isempty(files_list)
        files_list = natsortfiles(files_list);
    end
end