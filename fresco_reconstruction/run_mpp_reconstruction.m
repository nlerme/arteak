% This function returns a reconstructed fresco using MPPs, whatever the 
% availability of the fresco model.
% 
% Inputs:
%   * im_fresco_color:        color image of fresco (non empty uint8 matrix)
%   * im_fresco_alpha:        alpha image of fresco (non empty uint8 matrix)
%   * init_frags_sol:         initialization composed of fragments ([non empty] cell array)
%   * frags_infos:            collection of fragments (cell array with RGBA images)
%   * general_parameters:     value of general parameters (non empty cell array)
%   * init_parameters:        value of init parameters (non empty cell array)
%   * mpp_parameters:         value of MPP parameters (non empty cell array)
%   * gen_parameters:         value of parameters used for generating the fragmented fresco (non empty struct)
%   * geometric_constraints:  geometric constraints (non empty struct)
%   * frags_gt:               ground truth ([non empty] cell array)
% 
% Outputs:
%   * best_frags_sol:  resulting solution composed of fragments (cell array)
function best_frags_sol = run_mpp_reconstruction( im_fresco_color, im_fresco_alpha, init_frags_sol, frags_infos, general_parameters, init_parameters, mpp_parameters, gen_parameters, geometric_constraints, frags_gt )
    % We convert the fresco image to normalized grayscale intensities to speed up
    %im_fresco_alpha2 = uint8(im_fresco_alpha>0);

    %for k=1:size(im_fresco_color,3)
    %    im_fresco_color(:,:,k) = im_fresco_color(:,:,k).*im_fresco_alpha2;
    %end

    im_fresco_gray = im2double(rgb2gray(im_fresco_color));

    % We normalize intensities of fragment images
    for k=1:numel(frags_infos)
        frags_infos{k}.gray = im2double(frags_infos{k}.gray);
    end

    % We compute gradients of fresco image
    [im_fresco_grad_x,im_fresco_grad_y] = imgradientxy(im_fresco_gray, 'sobel');
    im_fresco_grads                     = cat(3, im_fresco_grad_x, im_fresco_grad_y);

    % We initialize variables
    verbose        = get_parameter_value(general_parameters, 'verbose');
    nb_iterations  = get_parameter_value(mpp_parameters, 'nb_iterations');
    best_frags_sol = {};

    % We alternate sampling and selection steps for a number of iterations
    all_energies      = zeros(1,nb_iterations);
    nb_detections     = zeros(1,nb_iterations);
    current_frags_sol = init_frags_sol;
    %aaa = zeros(1, numel(frags_infos));

    for it=1:nb_iterations
        % We get a new sample of fragments randomly selected
        %new_frags_sol = run_init_blind_reconstruction(im_fresco_color, im_fresco_alpha, frags_infos, general_parameters, init_parameters, gen_parameters, geometric_constraints, frags_gt);
        %translation_tolerance = get_parameter_value(general_parameters, 'translation_tolerance');
        %angle_tolerance = get_parameter_value(general_parameters, 'angle_tolerance');
        %[tp,~,~,~,~,~,~,~,~] = compare_solution_to_gt(new_frags_sol, frags_gt, numel(frags_infos), translation_tolerance, angle_tolerance);
        %disp(sprintf('it=%d', it));
        %aaa(tp) = aaa(tp)+1;
        %if numel(find(aaa)>0)==numel(frags_infos)
        %    aaa
        %    break;
        %end
        %continue;
        %new_frags_sol = frags_gt;
        %new_frags_sol = init_frags_sol;
        new_frags_sol = frags_gt{randi(numel(frags_gt))};
        %new_frags_sol = {};

        % Gradient-based fragments placement
        [all_frags_sol,E] = adjust_fragments_position(im_fresco_gray, im_fresco_alpha, im_fresco_grads, frags_infos, [current_frags_sol,new_frags_sol], general_parameters, mpp_parameters, gen_parameters, geometric_constraints);
        current_frags_sol = all_frags_sol(1:numel(current_frags_sol));
        new_frags_sol     = all_frags_sol(numel(current_frags_sol) + (1:numel(new_frags_sol)));

        %best_frags_sol    = all_frags_sol;
        %all_frags_sol{7}.idx
        %cellfun(@(x) x.idx, all_frags_sol(all_frags_sol{7}.N_c))
        %cellfun(@(x) x.idx, all_frags_sol(all_frags_sol{7}.N_sf))
        %cellfun(@(x) x.idx, all_frags_sol(all_frags_sol{7}.N_no))
        %for i=1:numel(all_frags_sol)
        %    %disp(sprintf('i=%d (idx=%d) | N_sf', i, all_frags_sol{i}.idx, all_frags_sol{i}.E_a));
        %    all_frags_sol{i}.idx
        %    cellfun(@(x) x.idx, all_frags_sol(all_frags_sol{i}.N_sf))
        %    disp('-------------');
        %end
        %disp('-------------');
        %min(cellfun(@(x) sum(x.E_sf), all_frags_sol))
        %max(cellfun(@(x) sum(x.E_sf), all_frags_sol))
        %return;

        % Graph cuts-based fragments selection
        %[tmp,energy,~] = select_best_fragments(current_frags_sol, new_frags_sol, general_parameters, mpp_parameters, frags_gt);
        [tmp,energy] = select_best_fragments_qpbo(current_frags_sol, new_frags_sol, general_parameters, mpp_parameters, frags_gt);

        % Message
        if it==1
            best_frags_sol = tmp;
        else
            if energy<=all_energies(it-1)
                best_frags_sol = tmp;
            else
                best_frags_sol = current_frags_sol;
                energy = all_energies(it-1);
            end
        end

        msg(sprintf('  + iteration %d | #current_frags=%d, #new_frags=%d, #best_frags=%d, energy=%f', it, numel(current_frags_sol), numel(new_frags_sol), numel(best_frags_sol), energy), verbose);

        % Assignments
        current_frags_sol = best_frags_sol;
        all_energies(it)  = energy;
        nb_detections(it) = numel(current_frags_sol);
    end

%     % We plot energy with respect to iteration number
%     figure;
%     hold on;
%     grid on;
%     xlabel('Iteration number');
%     ylabel('Energy');
%     xlim([1,nb_iterations]);
%     plot(1:nb_iterations, all_energies);
end