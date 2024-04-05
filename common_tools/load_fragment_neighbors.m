% This function load the text file describing the relationships between
% adjacent fragments.
% 
% Inputs:
%   * filename:      name of the saved file (string)
%   * in_frags_sol:  input solution composed of fragments (cell array)
% 
% Outputs:
%   * out_frags_sol:  resulting solution composed of fragments (cell array)
function out_frags_sol = load_fragment_neighbors( filename, in_frags_sol )
    % We check if input arguments are valid
    if isempty(in_frags_sol) || isempty(filename)
        error('Fragments solution and filename must be non empty');
    end

    % We open the file in reading mode
    fp = fopen(filename, 'r');

    if fp<0
        error('Unable to read the text file %s', filename);
    end

    % We load neighboring relationships
    [fn_idx1,fn_idx2] = textread(filename, '%d %d'); % format
    fn_idx1           = fn_idx1 + 1; % we add one since indexes are assumed to start at zero
    fn_idx2           = fn_idx2 + 1;

    if numel(fn_idx1)~=numel(fn_idx2)
        error('Neighboring fragments file wrongly formatted');
    end

    out_frags_sol = in_frags_sol;

    if max(fn_idx1)<1 || max(fn_idx2)<1
        return;
    end

    % We make symmetrical fragments relationships
    fn_idx                  = zeros(max(max(fn_idx1),max(fn_idx2)), 'logical');
    fn_idx(fn_idx1,fn_idx2) = 1;
    fn_idx                  = (fn_idx+fn_idx')>0;

    % We make empty array storing neighboring relationships
    for k=1:numel(out_frags_sol)
        if ~isfield(out_frags_sol{k}, 'neighbors')
            return;
        end

        out_frags_sol{k}.neighbors = [];
    end

    % We loop over neighboring relationships
    [fn_idx1,fn_idx2] = find(triu(fn_idx,1)>0); % upper triangular part of adjacency matrix without diagonal self-relationships are discarded)
    f_idx             = cellfun(@(x) x.idx, out_frags_sol);

    for k=1:numel(fn_idx1)
        i = find(f_idx==fn_idx1(k));
        j = find(f_idx==fn_idx2(k));

        if numel(i)==1 && numel(j)==1
            out_frags_sol{i}.neighbors = [out_frags_sol{i}.neighbors,j];
            out_frags_sol{j}.neighbors = [out_frags_sol{j}.neighbors,i];
        end
    end
end