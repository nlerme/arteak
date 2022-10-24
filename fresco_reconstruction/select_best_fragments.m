% Function returning the best subset of fragments using multi-bales graph cuts.
% 
% Inputs:
%   * im_fresco:           fresco image (RGBA image)
%   * frags_infos:         collection of fragments (cell array with RGBA images)
%   * current_frags_sol:   current solution composed of fragments ([non empty] cell array)
%   * new_frags_sol:       new solution composed of fragments ([non empty] cell array)
%   * general_parameters:  value of general parameters (non empty cell array)
%   * mpp_parameters:      value of MPP parameters (non empty cell array)
% 
% Outputs:
%   * best_frags_sol:  best subset of fragments (cell array) 
%   * energy:          value of the functional of the selected fragments (real)
%   * nb_colors:       number of colors used for coloring the adjacency graph (integer, >=1)
function [best_frags_sol,energy,nb_colors] = select_best_fragments( current_frags_sol, new_frags_sol, general_parameters, mpp_parameters, frags_gt )
    % We initialize some useful variables
    %verbose  = get_parameter_value(general_parameters, 'verbose');
    verbose  = false;
    beta_d   = get_parameter_value(mpp_parameters, 'beta_d');   % Weighting parameter for the term E_d
    beta_a   = get_parameter_value(mpp_parameters, 'beta_a');   % Weighting parameter for the term E_a
    beta_inc = get_parameter_value(mpp_parameters, 'beta_inc'); % Weighting parameter for the term E_{inc}
    beta_c   = get_parameter_value(mpp_parameters, 'beta_c');   % Weighting parameter for the term E_c
    beta_no  = get_parameter_value(mpp_parameters, 'beta_no');  % Weighting parameter for the term E_{no}
    beta_sf  = get_parameter_value(mpp_parameters, 'beta_sf');  % Weighting parameter for the term E_{sf}

    % Message
    msg('  + optimization', verbose);

    % Indexing
    current_frags_nn = 1:numel(current_frags_sol);
    new_frags_nn     = numel(current_frags_sol) + (1:numel(new_frags_sol));
    all_frags_sol    = [current_frags_sol,new_frags_sol];
    nb_sites         = numel(all_frags_sol);

    % Neighboring cost computation
    msg('    + neighbors computation', verbose);
    nb_non_null_values = ((nb_sites)*(nb_sites-1))/2;
    offsets1           = zeros(1, nb_non_null_values);
    offsets2           = zeros(1, nb_non_null_values);
    costs              = zeros(1, nb_non_null_values);
    count              = 1;

    for i=1:numel(all_frags_sol)
        for j=(i+1):numel(all_frags_sol)
            ok   = false;
            cost = 0.0;

            if beta_c>0
                idx = find(all_frags_sol{i}.N_c==j);

                if ~isempty(idx)
                    ok   = true;
                    cost = cost + beta_c*all_frags_sol{i}.E_c(idx);
                    %disp('uniqueness................');
                end
            end

            if beta_no>0
                idx1 = find(all_frags_sol{i}.N_no==j);
                idx2 = find(all_frags_sol{j}.N_no==i);

                if ~isempty(idx1) && ~isempty(idx2)
                    ok   = true;
                    cost = cost + beta_no*0.5*(all_frags_sol{i}.E_no(idx1)+all_frags_sol{j}.E_no(idx2));
                    %disp('non overlapping................');
                end
            end

            if beta_sf>0
%                 idx1 = find(all_frags_sol{i}.N_sf==j);
%                 idx2 = find(all_frags_sol{j}.N_sf==i);
% 
%                 if ~isempty(idx1) && ~isempty(idx2)
%                     ok   = true;
%                     cost = cost + beta_sf*0.5*(all_frags_sol{i}.E_sf(idx1)+all_frags_sol{j}.E_sf(idx2));
%                 end

                idx1 = find(all_frags_sol{i}.N_sf==j);
                idx2 = find(all_frags_sol{j}.N_sf==i);

                if ~isempty(idx1) && ~isempty(idx2)
                    ii = find(cellfun(@(x) x.idx==all_frags_sol{i}.idx, frags_gt));
    
                    if ~isempty(ii)
                        neighbors = frags_gt(frags_gt{ii}.neighbors);
                        jj        = find(cellfun(@(x) x.idx==all_frags_sol{j}.idx, neighbors));
        
                        if ~isempty(jj)
                            i_angle        = all_frags_sol{i}.angle;
                            i_translation  = all_frags_sol{i}.translation;
                            j_angle        = all_frags_sol{j}.angle;
                            j_translation  = all_frags_sol{j}.translation;
                            ii_angle       = frags_gt{ii}.angle;
                            ii_translation = frags_gt{ii}.translation;
                            jj_angle       = neighbors{jj}.angle;
                            jj_translation = neighbors{jj}.translation;
        
                            if i_angle~=ii_angle || ...
                               j_angle~=jj_angle || ...
                               (j_translation(1)-i_translation(1))~=(jj_translation(1)-ii_translation(1)) || ...
                               (j_translation(2)-i_translation(2))~=(jj_translation(2)-ii_translation(2))
                                ok   = true;
                                cost = cost + beta_sf*1.0;
                                %disp(sprintf('cost between %d (%d) and %d (%d) | ', i, ii, j, jj));
                            end
                        else
                            ok   = true;
                            cost = cost + beta_sf*1.0;
                        end
                    end
                end
            end

            if ok
                offsets1(count) = i;
                offsets2(count) = j;
                costs(count)    = cost;
                count           = count + 1;
                disp(sprintf('cost between i=%d (idx=%d) and j=%d (idx=%d) -> %f', i, all_frags_sol{i}.idx, j, all_frags_sol{j}.idx, cost));
            end
        end
    end

    indexes  = find(offsets1>0, 1, 'last');
    offsets1 = offsets1(1:indexes);
    offsets2 = offsets2(1:indexes);
    costs    = costs(1:indexes);
    nc       = sparse(offsets1, offsets2, costs, nb_sites, nb_sites);

    % Graph coloring
    [all_frags_sol,nb_colors] = compute_graph_coloring_dsatur(all_frags_sol);
    is_valid = is_valid_graph_coloring(all_frags_sol);
    if is_valid
        msg(sprintf('    + graph coloring (%d) | VALID', nb_colors), verbose);
    else
        msg(sprintf('    + graph coloring (%d) | INVALID', nb_colors), verbose);
    end
    global nodes_idx;
    nodes_idx = cellfun(@(x) x.color_idx, all_frags_sol);
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

    for k=1:numel(current_frags_sol)
        nn                   = current_frags_nn(k);
        cost                 = current_frags_sol{k}.E_d;
        dc(:,nn)             = beta_d*0.5*(1-cost);
        dc(nodes_idx(nn),nn) = beta_d*0.5*(1+cost) + beta_a*current_frags_sol{k}.E_a + beta_inc*current_frags_sol{k}.E_inc;
        energy_const         = energy_const + beta_d*0.5*(1-cost);
        init_labeling(nn)    = nodes_idx(nn);
        %------- For debugging -------
        %dc(:,nn) = 1;
        %dc(nodes_idx(nn),nn) = 0 - alpha*(current_frags{k}.area/fresco_nb_pixels*100);
        %disp(sprintf('[ current %d / %d ] cost=%f, E(1)=%f, E(2)=%f', nn, nodes_idx(nn), cost, dc(1,nn), dc(2,nn)));
        %-----------------------------
    end

    for k=1:numel(new_frags_sol)
        nn                   = new_frags_nn(k);
        cost                 = new_frags_sol{k}.E_d;
        dc(:,nn)             = beta_d*0.5*(1-cost);
        dc(nodes_idx(nn),nn) = beta_d*0.5*(1+cost) + beta_a*new_frags_sol{k}.E_a + beta_inc*new_frags_sol{k}.E_inc;
        energy_const         = energy_const + beta_d*0.5*(1-cost);
        init_labeling(nn)    = mod(nodes_idx(nn),max(nodes_idx)) + 1;
        %------- For debugging -------
        %dc(:,nn) = 1;
        %dc(nodes_idx(nn),nn) = 0 - alpha*(new_frags{k}.area/fresco_nb_pixels*100);
        %disp(sprintf('[ new %d / %d ] cost=%f, E(1)=%f, E(2)=%f', nn, nodes_idx(nn), cost, dc(1,nn), dc(2,nn)));
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
    msg(sprintf('      + total energy = %f (%f)', E, E-energy_const), verbose);
    energy = E - energy_const;

    % Construction of the solution
    msg('    + construction of the solution', verbose);
    labeling   = GCO_GetLabeling(h);
    best_frags_sol = {};

    for i=1:numel(all_frags_sol)
        disp(sprintf('i=%d (idx=%d) | color_idx=%d', i, all_frags_sol{i}.idx, all_frags_sol{i}.color_idx));
    end

    %nodes_idx
    %labeling

    for k=1:numel(current_frags_sol)
        nn = current_frags_nn(k);

        if labeling(nn)==nodes_idx(nn)
            best_frags_sol = [best_frags_sol,{current_frags_sol{k}}];
        end
    end

    for k=1:numel(new_frags_sol)
        nn = new_frags_nn(k);

        if labeling(nn)==nodes_idx(nn)
            best_frags_sol = [best_frags_sol,{new_frags_sol{k}}];
        end
    end

    for k=1:numel(best_frags_sol)
        best_frags_sol{k}.color_idx = [];
        best_frags_sol{k}.neighbors = [];
    end

    % Memory deallocation
    msg('    + memory deallocation', verbose);
    GCO_Delete(h);
end