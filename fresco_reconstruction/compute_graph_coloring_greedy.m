% Function computing a graph coloring using greedy algorithm.
% 
% Inputs:
%   * input_frags:  input collection of fragments (cell array)
% 
% Outputs:
%   * output_frags:  output collection of fragments (cell array)
%   * nb_colors:     number of colors used for coloring the graph (N_{>=1})
function [output_frags,nb_colors] = compute_graph_coloring_greedy( input_frags )
    % If the number of fragments is null, we assign a null color index to each fragment
    if numel(input_frags)==0
        output_frags = {};
        nb_colors    = 0;
        return;
    end

    % We compute the graph coloring
    output_frags = input_frags;
    nb_colors    = 1;

    for i=1:numel(output_frags)
        output_frags{i}.n_colors_idx = zeros(1,numel(output_frags));
    end

    for i=randperm(numel(output_frags))
        [~,color_idx] = min(output_frags{i}.n_colors_idx);
        output_frags{i}.color_idx = color_idx;
        nb_colors = max(nb_colors, color_idx);

        for j=output_frags{i}.neighbors
            output_frags{j}.n_colors_idx(color_idx) = output_frags{j}.n_colors_idx(color_idx)+1;
        end
    end

    % We assign the final color index to each fragment
    for i=1:numel(output_frags)
        output_frags{i}.n_colors_idx = [];
    end
end