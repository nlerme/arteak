% Function computing a graph coloring using DSATUR algorithm.
% 
% Inputs:
%   * input_frags:  input collection of fragments (cell array)
% 
% Outputs:
%   * output_frags:  output collection of fragments (cell array)
%   * nb_colors:     number of colors used for coloring the graph (in N_{>=1})
function [output_frags,nb_colors] = compute_graph_coloring_dsatur( input_frags )
    % If the number of fragments is null, we assign a null color index to each fragment
    if numel(input_frags)==0
        output_frags = {};
        nb_colors    = 0;
        return;
    end

    % We compute the graph coloring
    output_frags = input_frags;
    nb_colors    = 1;

    n_colors_idx = zeros(numel(output_frags));
    colors_idx   = zeros(1,numel(output_frags));
    dsat         = zeros(1,numel(output_frags));
    deg          = cellfun(@(x) numel(x.neighbors), output_frags);

    for i=1:numel(output_frags)
        nodes_idx1 = find(colors_idx==0);
        dsat_idx1  = dsat(nodes_idx1);
        nodes_idx2 = find(dsat_idx1==max(dsat_idx1));
        deg_idx2   = deg(nodes_idx1(nodes_idx2));
        nodes_idx3 = find(deg_idx2==max(deg_idx2));
        node_idx   = nodes_idx1(nodes_idx2(nodes_idx3(1)));

        [~,color_idx] = min(n_colors_idx(node_idx,:));
        colors_idx(node_idx) = color_idx;
        nb_colors = max(nb_colors, color_idx);

        for n_node_idx=output_frags{node_idx}.neighbors
            n_colors_idx(n_node_idx, color_idx) = n_colors_idx(n_node_idx, color_idx)+1;
        end

        dsat(node_idx) = numel(find(n_colors_idx(node_idx,:)>0));
    end

    % We assign the final color index to each fragment
    for i=1:numel(output_frags)
        output_frags{i}.color_idx    = colors_idx(i);
        output_frags{i}.n_colors_idx = [];
    end
end