% This function returns the set of filenames within given directory.
% 
% Inputs:
%   * root_dir_name:  name of directory where image files are searched
% 
% Outputs:
%   * res_fns:  resulting list of found image filenames
function res_fns = get_files_list( root_dir_name )
    % We get the set of maching directories and loop over them
    dir_names = get_matching_dirs(root_dir_name, '.*');
    res_fns   = {};

    for i=1:numel(dir_names)
        % We extract name of current directory
        dir_name  = split(dir_names{i}, filesep);
        dir_name  = dir_name{end};

        % We look for image files
        file_names = get_matching_files(dir_names{i}, [dir_name '.png']);

        % If the list is not empty, we append it to the list
        if isempty(file_names)
            continue;
        end

        res_fns = {res_fns{:},file_names{1}};
    end
end