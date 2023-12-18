% Function returning the best subset of fragments using multi-bales graph cuts.
% 
% Inputs:
%   * current_frags_sol:   current solution composed of fragments ([non empty] cell array)
%   * new_frags_sol:       new solution composed of fragments ([non empty] cell array)
%   * general_parameters:  value of general parameters (non empty cell array)
%   * mpp_parameters:      value of MPP parameters (non empty cell array)
%   * frags_gt:               ground truth ([non empty] cell array)
% 
% Outputs:
%   * best_frags_sol:  best subset of fragments (cell array)
%   * energy:          value of the functional of the selected fragments (real)
function [best_frags_sol,energy] = select_best_fragments_qpbo( current_frags_sol, new_frags_sol, general_parameters, mpp_parameters, frags_gt )
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

    % Data costs assignment
    msg('    + data costs assignment', verbose);
    dc = zeros(nb_sites, 2);
    energy_const = 0.0;

    for k=1:numel(current_frags_sol)
        % [Dp(0), Dp(1)] - unary terms
        nn           = current_frags_nn(k);
        cost         = current_frags_sol{k}.E_d;
        %dc(nn,1)     = beta_d*0.5*(1-cost);
        %dc(nn,2)     = beta_d*0.5*(1+cost) + beta_a*current_frags_sol{k}.E_a + beta_inc*current_frags_sol{k}.E_inc;
        dc(nn,1) = beta_a*current_frags_sol{k}.E_a;
        dc(nn,2) = beta_d*current_frags_sol{k}.E_d;
        %disp(sprintf('cost1=%f, cost2=%f', dc(nn,1), dc(nn,2)));
        %energy_const = energy_const + beta_d*0.5*(1-cost);
    end

    for k=1:numel(new_frags_sol)
        % [Dp(0), Dp(1)] - unary terms
        nn           = new_frags_nn(k);
        cost         = new_frags_sol{k}.E_d;
        %dc(nn,1)     = beta_d*0.5*(1+cost) + beta_a*new_frags_sol{k}.E_a + beta_inc*new_frags_sol{k}.E_inc;
        %dc(nn,2)     = beta_d*0.5*(1-cost);
        dc(nn,1)     = beta_d*new_frags_sol{k}.E_d;
        dc(nn,2)     = beta_a*new_frags_sol{k}.E_a;
        %energy_const = energy_const + beta_d*0.5*(1-cost);
    end

    % Neighboring cost computation
    msg('    + smoothness costs assignment', verbose);
    sc = [];

    for i=1:numel(all_frags_sol)
        for j=(i+1):numel(all_frags_sol)
            ok   = false;
            cost = 0.0;

            if beta_c>0
                idx1 = find(all_frags_sol{i}.N_c==j);
                idx2 = find(all_frags_sol{j}.N_c==i);

                if ~isempty(idx1) && ~isempty(idx2)
                    ok   = true;
                    cost = cost + beta_c*0.5*(all_frags_sol{i}.E_c(idx1)+all_frags_sol{i}.E_c(idx2));
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
                idx1 = find(all_frags_sol{i}.N_sf==j);
                idx2 = find(all_frags_sol{j}.N_sf==i);

                if ~isempty(idx1) && ~isempty(idx2)
                    ok   = true;
                    cost = cost + beta_sf*0.5*(all_frags_sol{i}.E_sf(idx1)+all_frags_sol{j}.E_sf(idx2));
                end

%                 if ~isempty(idx1) && ~isempty(idx2)
%                     ii = find(cellfun(@(x) x.idx==all_frags_sol{i}.idx, frags_gt));
%     
%                     if ~isempty(ii)
%                         neighbors = frags_gt(frags_gt{ii}.neighbors);
%                         jj        = find(cellfun(@(x) x.idx==all_frags_sol{j}.idx, neighbors));
% 
%                         if ~isempty(jj)
%                             i_angle        = all_frags_sol{i}.angle;
%                             i_translation  = all_frags_sol{i}.translation;
%                             j_angle        = all_frags_sol{j}.angle;
%                             j_translation  = all_frags_sol{j}.translation;
%                             ii_angle       = frags_gt{ii}.angle;
%                             ii_translation = frags_gt{ii}.translation;
%                             jj_angle       = neighbors{jj}.angle;
%                             jj_translation = neighbors{jj}.translation;
%         
%                             if i_angle~=ii_angle || ...
%                                j_angle~=jj_angle || ...
%                                (j_translation(1)-i_translation(1))~=(jj_translation(1)-ii_translation(1)) || ...
%                                (j_translation(2)-i_translation(2))~=(jj_translation(2)-ii_translation(2))
%                                 % Penality
%                                 ok   = true;
%                                 cost = cost + beta_sf*1.0;
%                             else
%                                 % Reward
%                                 ok   = true;
%                                 cost = cost - beta_sf*1.0;
%                             end
%                         else
%                             % Penality
%                             ok   = true;
%                             cost = cost + beta_sf*1.0;
%                         end
%                     end
%                 end
            end

            if ok
                % [p, q, Vpq(0, 0), Vpq(0, 1), Vpq(1,0), Vpq(1, 1)] - pairwise terms
                if ~isempty(current_frags_sol) && i>=current_frags_nn(1) && i<=current_frags_nn(end) && j>=current_frags_nn(1) && j<=current_frags_nn(end)
                    sc = [sc;i,j,0,0,0,cost];
                elseif ~isempty(new_frags_sol) && i>=new_frags_nn(1) && i<=new_frags_nn(end) && j>=new_frags_nn(1) && j<=new_frags_nn(end)
                    sc = [sc;i,j,cost,0,0,0];
                elseif ~isempty(current_frags_sol) && ~isempty(new_frags_sol) && i>=current_frags_nn(1) && i<=current_frags_nn(end) && j>=new_frags_nn(1) && j<=new_frags_nn(end)
                    sc = [sc;i,j,0,0,cost,0];
                end
            end
        end
    end

    if isempty(sc)
        sc = [1,2,0,0,0,0];
    end

    % Energy minimization
    [E,labeling] = qpboMex(dc, sc);
    msg(sprintf('    + energy minimization | energy=%f (%f)', E, E-energy_const), verbose);
    energy = E - energy_const;

    % Construction of the solution
    msg('    + construction of the solution', verbose);
    best_frags_sol = {};

    for k=1:numel(current_frags_sol)
        nn = current_frags_nn(k);

        if labeling(nn)==1
            best_frags_sol = [best_frags_sol,{current_frags_sol{k}}];
        end
    end

    for k=1:numel(new_frags_sol)
        nn = new_frags_nn(k);

        if labeling(nn)==0
            best_frags_sol = [best_frags_sol,{new_frags_sol{k}}];
        end
    end

    for k=1:numel(best_frags_sol)
        best_frags_sol{k}.color_idx = [];
        best_frags_sol{k}.neighbors = [];
    end
end