% Function returning the best subset of two solutions composed of fragments.
% 
% Inputs:
%   * im_fresco:          multi-channels fresco image
%   * frags_infos:        informations about fragments
%   * current_frags:      current solution of fragments
%   * new_frags:          new solution of fragments
%   * overlap_tolerance:  threshold for accepting/rejecting overlapping fragments
%   * alpha:              weighting parameter (>=0)
%   * beta:               weighting parameter (>=0)
%   * lambda:             sharpness parameter of activation function psi (>0)
%   * mu:                 shift parameter of activation function psi (in [-1,1])
%   * verbose:            enables/disables debugging messages (true or false)
% 
% Outputs:
%   * best_frags:  best subset of fragments
%   * energy:      value of the functional of the selected fragments
function [best_frags,energy] = get_best_fragments( im_fresco, frags_infos, current_frags, new_frags, overlap_tolerance, alpha, beta, lambda, mu, verbose )
    msg('  + optimization', verbose);

    % We get size of fresco image
    fresco_size      = size(im_fresco);
    fresco_nb_pixels = prod(fresco_size(1:2));

    % Indexing
    current_frags_nn = 1:numel(current_frags);
    new_frags_nn     = numel(current_frags) + (1:numel(new_frags));
    all_frags        = [current_frags,new_frags];
    nb_sites         = numel(all_frags);

    % Neighboring cost computation
    msg('    + neighbors computation', verbose);
    nb_non_null_values = ((nb_sites)*(nb_sites-1))/2;
    offsets1           = zeros(1, nb_non_null_values);
    offsets2           = zeros(1, nb_non_null_values);
    costs              = zeros(1, nb_non_null_values);
    count              = 1;
    large_cost         = 10000.0;

    im_res = zeros(fresco_size(1:2));

    for i=1:numel(current_frags)
        nn1   = current_frags_nn(i);
        idx1  = current_frags{i}.idx;
        gi1   = current_frags{i}.frag_intensities;
        fc1   = current_frags{i}.fresco_coords;
        fc1_d = current_frags{i}.fresco_coords_d;
        c1    = current_frags{i}.outer_circle_center;
        r1    = current_frags{i}.outer_circle_radius;

        for j=(i+1):numel(current_frags)
            nn2   = current_frags_nn(j);
            idx2  = current_frags{j}.idx;
            gi2   = current_frags{j}.frag_intensities;
            fc2   = current_frags{j}.fresco_coords;
            fc2_d = current_frags{j}.fresco_coords_d;
            c2    = current_frags{j}.outer_circle_center;
            r2    = current_frags{j}.outer_circle_radius;
            ok    = false;

            if idx1==idx2
                % if fragments are identical, we assign prohibitive cost
                ok   = true;
                cost = large_cost;
                %disp(sprintf('[current_frags(%d),current_frags(%d)] large_cost', idx1, idx2));
            else
                % if fragments do not overlap significantly but their dilated version do, we assign a cost depending on radiometric differences along their common borders
                if beta>0
                    [decision1,~,~,subidx2] = are_fragments_intersected(fc1_d, c1, r1, fc2, c2, r2, 0.0);
                    [decision2,~,~,subidx1] = are_fragments_intersected(fc2_d, c2, r2, fc1, c1, r1, 0.0);

                    if decision1 && decision2
                        ok   = true;
                        cost = beta*get_dissimilarity(gi1(subidx1,:), gi2(subidx2,:));
                    end
                end
            end

            if ok
                msg(sprintf('      + [current vs current | idx1=%d,idx2=%d] cost=%f', idx1, idx2, cost), verbose);
                offsets1(count)          = nn1;
                offsets2(count)          = nn2;
                costs(count)             = cost;
                count                    = count + 1;
                all_frags{nn1}.neighbors = [all_frags{nn1}.neighbors,nn2];
                all_frags{nn2}.neighbors = [all_frags{nn2}.neighbors,nn1];
            end
        end
    end

    for i=1:numel(new_frags)
        nn1   = new_frags_nn(i);
        idx1  = new_frags{i}.idx;
        gi1   = new_frags{i}.frag_intensities;
        fc1   = new_frags{i}.fresco_coords;
        fc1_d = new_frags{i}.fresco_coords_d;
        c1    = new_frags{i}.outer_circle_center;
        r1    = new_frags{i}.outer_circle_radius;

        for j=(i+1):numel(new_frags)
            nn2   = new_frags_nn(j);
            idx2  = new_frags{j}.idx;
            gi2   = new_frags{j}.frag_intensities;
            fc2   = new_frags{j}.fresco_coords;
            fc2_d = new_frags{j}.fresco_coords_d;
            c2    = new_frags{j}.outer_circle_center;
            r2    = new_frags{j}.outer_circle_radius;
            ok    = false;

            if idx1==idx2
                % if fragments are identical, we assign a prohibitive cost
                ok   = true;
                cost = large_cost;
                %disp(sprintf('[new_frags(%d),new_frags(%d)] large_cost', idx1, idx2));
            else
                % if fragments do not overlap significantly but their dilated version do, we assign a cost depending on radiometric differences along their common borders
                if beta>0
                    [decision1,~,~,subidx2] = are_fragments_intersected(fc1_d, c1, r1, fc2, c2, r2, 0.0);
                    [decision2,~,~,subidx1] = are_fragments_intersected(fc2_d, c2, r2, fc1, c1, r1, 0.0);

                    if decision1 && decision2
                        ok   = true;
                        cost = beta*get_dissimilarity(gi1(subidx1,:), gi2(subidx2,:));
                    end
                end
            end

            if ok
                msg(sprintf('      + [new vs new | idx1=%d,idx2=%d] cost=%f', idx1, idx2, cost), verbose);
                offsets1(count)          = nn1;
                offsets2(count)          = nn2;
                costs(count)             = cost;
                count                    = count + 1;
                all_frags{nn1}.neighbors = [all_frags{nn1}.neighbors,nn2];
                all_frags{nn2}.neighbors = [all_frags{nn2}.neighbors,nn1];
            end
        end
    end

    for i=1:numel(current_frags)
        nn1   = current_frags_nn(i);
        idx1  = current_frags{i}.idx;
        gi1   = current_frags{i}.frag_intensities;
        fc1   = current_frags{i}.fresco_coords;
        fc1_d = current_frags{i}.fresco_coords_d;
        c1    = current_frags{i}.outer_circle_center;
        r1    = current_frags{i}.outer_circle_radius;

        for j=1:numel(new_frags)
            nn2   = new_frags_nn(j);
            idx2  = new_frags{j}.idx;
            gi2   = new_frags{j}.frag_intensities;
            fc2   = new_frags{j}.fresco_coords;
            fc2_d = new_frags{j}.fresco_coords_d;
            c2    = new_frags{j}.outer_circle_center;
            r2    = new_frags{j}.outer_circle_radius;
            ok    = false;

            if idx1==idx2 || are_fragments_intersected(fc1, c1, r1, fc2, c2, r2, overlap_tolerance)
                % if fragments are either identical or overlap too much, we assign a prohibitive cost
                ok   = true;
                cost = large_cost;
                %disp(sprintf('[current_frags(%d),new_frags(%d)] large_cost', idx1, idx2));
            else
                % if fragments do not overlap significantly but their dilated version do, we assign a cost depending on radiometric differences along their common borders
                if beta>0
                    [decision1,~,~,subidx2] = are_fragments_intersected(fc1_d, c1, r1, fc2, c2, r2, 0.0);
                    [decision2,~,~,subidx1] = are_fragments_intersected(fc2_d, c2, r2, fc1, c1, r1, 0.0);

                    if decision1 && decision2
                        ok   = true;
                        cost = beta*get_dissimilarity(gi1(subidx1,:), gi2(subidx2,:));
                    end
                end
            end

            if ok
                msg(sprintf('      + [current vs new | idx1=%d,idx2=%d] cost=%f', idx1, idx2, cost), verbose);
                offsets1(count)          = nn1;
                offsets2(count)          = nn2;
                costs(count)             = cost;
                count                    = count + 1;
                all_frags{nn1}.neighbors = [all_frags{nn1}.neighbors,nn2];
                all_frags{nn2}.neighbors = [all_frags{nn2}.neighbors,nn1];
            end
        end
    end

    indexes  = find(offsets1>0, 1, 'last');
    offsets1 = offsets1(1:indexes);
    offsets2 = offsets2(1:indexes);
    costs    = costs(1:indexes);
    nc       = sparse(offsets1, offsets2, costs, nb_sites, nb_sites);

    % Graph coloring
    [all_frags,nb_colors] = compute_graph_coloring_dsatur(all_frags);
    is_valid = is_valid_graph_coloring(all_frags);
    if is_valid
        msg('    + graph coloring | VALID', verbose);
    else
        msg('    + graph coloring | INVALID', verbose);
    end
    global nodes_idx;
    nodes_idx = cellfun(@(x) x.color_idx, all_frags);
    %-------- For debugging --------
    %disp(sprintf('number of colors found -> %d', nb_colors));
    %[~,im_bnd_frags,~] = get_reconstructed_fresco(im_fresco, frags_infos, all_frags, 'nearest', [0,0,0]);
    %show_reconstructed_fresco(im_bnd_frags, all_frags, [], [], [], [], [], false, false, true, true, 'on');
    %-------------------------------

    % Memory allocation
    msg('    + memory allocation', verbose);
    nb_labels = max(2,nb_colors);
    h = GCO_Create(nb_sites, nb_labels);

    % Data costs assignment
    msg('    + data costs assignment', verbose);
    dc = zeros(nb_labels, nb_sites);
    energy_const = 0.0;
    init_labeling = zeros(1, nb_sites);

    for k=1:numel(current_frags)
        nn                   = current_frags_nn(k);
        values               = 2*mean((current_frags{k}.fresco_intensities(:)-current_frags{k}.frag_intensities(:)).^2)-1;
        cost                 = psi_x(values, lambda, mu);
        dc(:,nn)             = 0.5*(1-cost);
        dc(nodes_idx(nn),nn) = 0.5*(1+cost) - alpha*(current_frags{k}.area/fresco_nb_pixels*100);
        energy_const         = energy_const + 0.5*(1-cost);
        init_labeling(nn)    = nodes_idx(nn);
        %------- For debugging -------
        %dc(:,nn) = 1;
        %dc(nodes_idx(nn),nn) = 0 - alpha*(current_frags{k}.area/fresco_nb_pixels*100);
        %disp(sprintf('[ current %d | E(0)=%f, E(1)=%f', nn, dc(1,nn), dc(2,nn)));
        %-----------------------------
    end

    for k=1:numel(new_frags)
        nn                   = new_frags_nn(k);
        values               = 2*mean((new_frags{k}.fresco_intensities(:)-new_frags{k}.frag_intensities(:)).^2)-1;
        cost                 = psi_x(values, lambda, mu);
        dc(:,nn)             = 0.5*(1-cost);
        dc(nodes_idx(nn),nn) = 0.5*(1+cost) - alpha*(new_frags{k}.area/fresco_nb_pixels*100);
        energy_const         = energy_const + 0.5*(1-cost);
        init_labeling(nn)    = mod(nodes_idx(nn),max(nodes_idx)) + 1;
        %------- For debugging -------
        %dc(:,nn) = 1;
        %dc(nodes_idx(nn),nn) = 0 - alpha*(new_frags{k}.area/fresco_nb_pixels*100);
        %disp(sprintf('[ new %d | E(0)=%f, E(1)=%f', nn, dc(1,nn), dc(2,idx)));
        %-----------------------------
    end

    GCO_SetDataCost(h, dc);

    % Neighbors assignment
    msg('    + neighboring costs assignment', verbose);
    GCO_SetNeighbors(h, nc);

    % Smoothness costs assignment
    msg('    + smoothness costs assignment', verbose);
    GCO_SetSmoothCost(h, 'smoothness_cost_fn');

    % Energy minimization
    msg('    + energy minimization', verbose);
    verbosity_level = 2;
    GCO_SetVerbosity(h, verbosity_level);
    GCO_SetLabeling(h, init_labeling);
    GCO_Swap(h);
    [E,D,S,~] = GCO_ComputeEnergy(h);
    msg(sprintf('      + data energy = %f', D), verbose);
    msg(sprintf('      + smoothness energy = %f', S), verbose);
    msg(sprintf('      + total energy = %f', E), verbose);
    energy = E - energy_const;

    % Construction of the solution
    msg('    + construction of the solution', verbose);
    labeling   = GCO_GetLabeling(h);
    best_frags = {};
    %nodes_idx
    %labeling

    for k=1:numel(current_frags)
        nn = current_frags_nn(k);

        if labeling(nn)==nodes_idx(nn)
            best_frags = [best_frags,{current_frags{k}}];
        end
    end

    for k=1:numel(new_frags)
        nn = new_frags_nn(k);

        if labeling(nn)==nodes_idx(nn)
            best_frags = [best_frags,{new_frags{k}}];
        end
    end

    % Memory deallocation
    msg('    + memory deallocation', verbose);
    GCO_Delete(h);
end