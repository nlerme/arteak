% This function locally adjust the position of a given set of fragments, 
% whatever the availability of the fresco model.
% 
% Inputs:
%   * im_fresco_color:        grayscale image of fresco (non empty uint8 matrix)
%   * im_fresco_alpha:        alpha image of fresco (non empty uint8 matrix)
%   * im_fresco_grads:        gradients of fresco model (x then y)
%   * frags_infos:            collection of fragments (cell array with RGBA images)
%   * frags_sol:              input set of fragments (cell array)
%   * general_parameters:     value of general parameters (non empty cell array)
%   * mpp_parameters:         value of MPP parameters (non empty cell array)
%   * gen_parameters:         value of parameters used for generating the fragmented fresco (non empty struct)
%   * geometric_constraints:  geometric constraints (non empty struct)
%   * frags_gt:               ground truth ([non empty] cell array)
% 
% Outputs:
%   * frags_sol:   output set of fragments (cell array)
%   * energy:      value of the functional (real number)
function [frags_sol,energy] = adjust_fragments_position( im_fresco_gray, im_fresco_alpha, im_fresco_grads, frags_infos, frags_sol, general_parameters, mpp_parameters, gen_parameters, geometric_constraints )
    % We set parameters
    interpolation_type      = get_parameter_value(general_parameters, 'interpolation_type');
    verbose                 = get_parameter_value(general_parameters, 'verbose');
    outside_frag_tolerance  = get_parameter_value(mpp_parameters, 'outside_fragment_tolerance');
    frags_overlap_tolerance = get_parameter_value(mpp_parameters, 'fragments_overlap_tolerance');
    beta_d                  = get_parameter_value(mpp_parameters, 'beta_d');   % Weighting parameter for the term E_d
    beta_a                  = get_parameter_value(mpp_parameters, 'beta_a');   % Weighting parameter for the term E_a
    beta_inc                = get_parameter_value(mpp_parameters, 'beta_inc'); % Weighting parameter for the term E_{inc}
    beta_c                  = get_parameter_value(mpp_parameters, 'beta_c');   % Weighting parameter for the term E_c
    beta_no                 = get_parameter_value(mpp_parameters, 'beta_no');  % Weighting parameter for the term E_{no}
    beta_sf                 = get_parameter_value(mpp_parameters, 'beta_sf');  % Weighting parameter for the term E_{sf}
    lambda                  = get_parameter_value(mpp_parameters, 'lambda');   % Slope parameter of psi function
    mu                      = get_parameter_value(mpp_parameters, 'mu');       % Shift parameter of psi function
    nb_iterations           = 200;
    epsilon                 = 0.01;

    % We apply gradient descent on transformation parameters (3)
    x0 = zeros(numel(frags_sol), 3);

    for i=1:length(frags_sol)
        frag        = frags_sol{i};
        translation = frag.translation; % translation [ty,tx] in pixels
        angle       = frag.angle;       % angle of rotation in degrees
        x0(i,:)     = [translation,angle];
    end

    iteration = 1;
    xk_old    = x0;
    iterates  = [];
    [Exk_old,frags_sol] = eval_E(im_fresco_gray, im_fresco_alpha, frags_infos, frags_sol, xk_old, interpolation_type, ...
                                 outside_frag_tolerance, frags_overlap_tolerance, ...
                                 beta_d, beta_a, beta_inc, beta_c, beta_no, beta_sf, lambda, mu);
    xk_new   = xk_old;
    Exk_new  = Exk_old;
    iterates = [iterates;Exk_new];
    %msg(sprintf('  + E(x%d)=%f', iteration, Exk_new), verbose);
    %for i=1:size(xk_new,1)
    %    msg(sprintf('    + E%d=(%f,%f,%f)', i, xk_new(i,1), xk_new(i,2), xk_new(i,3)), verbose);
    %end

    energy = Exk_new;

    % If both locations and orientations are constrained, we do not apply local adjustment of fragments
    if ~isempty(geometric_constraints.locations) && ~isempty(geometric_constraints.orientations)
        return;
    end
end

% This function returns the value of the functional E
function [Exk,frags_sol] = eval_E( im_fresco_gray, im_fresco_alpha, frags_infos, frags_sol, xk_old, interpolation_type, ...
                                   outside_frag_tolerance, frags_overlap_tolerance, ...
                                   beta_d, beta_a, beta_inc, beta_c, beta_no, beta_sf, lambda, mu )
    % We initialize energy terms and neighboring relationships
    for i=1:numel(frags_sol)
        frags_sol{i}.E_d       = 0.0; % energy term E_d
        frags_sol{i}.E_a       = 0.0; % energy term E_a
        frags_sol{i}.E_inc     = 0.0; % energy term E_inc
        frags_sol{i}.E_c       = []; % energy term E_c
        frags_sol{i}.E_no      = []; % energy term E_no
        frags_sol{i}.E_sf      = []; % energy term E_sf
        frags_sol{i}.N_c       = []; % list of neighbors for E_c
        frags_sol{i}.N_no      = []; % list of neighbors for E_no
        frags_sol{i}.N_sf      = []; % list of neighbors for E_sf
        frags_sol{i}.neighbors = []; % list of neighbors
    end

    % We loop over fragments and compute E
    fresco_size = size(im_fresco_alpha);
    nb_channels = size(im_fresco_gray,3);
    Exk         = 0.0;

    all_E_sf = [];
    all_E_d  = [];

    for i=1:numel(frags_sol)
        % We get information about the ith fragment
        frag_i                 = frags_sol{i};
        frag_i_size            = frags_infos{frag_i.idx}.size;
        frag_i_center          = round(0.5*frag_i_size);
        frag_i_area            = frags_infos{frag_i.idx}.area;
        frag_i_occ             = frags_infos{frag_i.idx}.outer_circle_center;
        frag_i_ocr             = frags_infos{frag_i.idx}.outer_circle_radius;
        im_frag_i_gray         = frags_infos{frag_i.idx}.gray;
        im_frag_i_gray_ext     = frags_infos{frag_i.idx}.gray_ext;
        frag_i_coords          = frags_infos{frag_i.idx}.coords;
        frag_i_coords_d        = frags_infos{frag_i.idx}.coords_d;
        frag_i_coords_e        = frags_infos{frag_i.idx}.coords_e;
        extrapolation_distance = frags_infos{frag_i.idx}.extrapolation_distance;

        % We project the coordinates of the ith fragment (P_wi) into the frame of the fresco image (P)
        frag_i_coords_P = apply_forward_transform(frag_i_coords, xk_old(i,1:2), xk_old(i,3), frag_i_center);

        % We add the contribution of the term E_inc
        % -----------------------------------------
        if beta_inc>0
            frags_sol{i}.E_inc = eval_E_inc(frag_i_coords_P, fresco_size, outside_frag_tolerance);
            Exk                = Exk + beta_inc*frags_sol{i}.E_inc;
        end

        % We add the contribution of the term E_a
        % ---------------------------------------
        if beta_a>0
            frags_sol{i}.E_a = eval_E_a(frag_i_area, fresco_size);
            Exk              = Exk + beta_a*frags_sol{i}.E_a;
        end

        % We add the contribution of the term E_d
        % ---------------------------------------
        if beta_d>0
            % For doing so, we first keep only projected pixel coordinates 
            % that lie into the fresco domain (P). If this set is not
            % empty, we compute L2 norm between the fragment and the fresco
            keep = find(frag_i_coords_P(:,1)>=1 & frag_i_coords_P(:,1)<=fresco_size(1) & frag_i_coords_P(:,2)>=1 & frag_i_coords_P(:,2)<=fresco_size(2));

            if ~isempty(keep)
                frag_i_coords_P        = frag_i_coords_P(keep,:);
                frag_i_coords_Pwi      = frag_i_coords(keep,:);
                frag_i_intensities2_P  = get_intensities(im_fresco_alpha, frag_i_coords_P, interpolation_type);

                if sum(frag_i_intensities2_P)>0
                    frag_i_intensities_P   = get_intensities(im_fresco_gray, frag_i_coords_P, interpolation_type);
                    frag_i_intensities_Pwi = get_intensities(im_frag_i_gray, frag_i_coords_Pwi, interpolation_type);
                    frag_i_intensities_P   = frag_i_intensities_P(frag_i_intensities2_P>0);
                    frag_i_intensities_Pwi = frag_i_intensities_Pwi(frag_i_intensities2_P>0);
                    frags_sol{i}.E_d       = eval_E_d(frag_i_intensities_P, frag_i_intensities_Pwi, frag_i_area, nb_channels, lambda, mu);
                else
                    frags_sol{i}.E_d = eps;
                end

                Exk     = Exk + beta_d*frags_sol{i}.E_d;
                all_E_d = [all_E_d,frags_sol{i}.E_d];
            end
        end

        % If all weighting parameters of pairwise energy terms are null, 
        % we can safely skip all couples of fragments involving the ith
        if beta_c==0 && beta_no==0 && beta_sf==0
            continue;
        end

        % We loop over all other fragments of the solution
        for j=1:numel(frags_sol)
            if i==j
                continue;
            end

            % We get information about the jth fragment
            frag_j             = frags_sol{j};
            frag_j_size        = frags_infos{frag_j.idx}.size;
            frag_j_center      = round(0.5*frag_j_size);
            frag_j_occ         = frags_infos{frag_j.idx}.outer_circle_center;
            frag_j_ocr         = frags_infos{frag_j.idx}.outer_circle_radius;
            im_frag_j_gray_ext = frags_infos{frag_j.idx}.gray_ext;
            im_frag_j_alpha_d  = frags_infos{frag_j.idx}.alpha_d;

            % We add the contribution of the term E_c
            % ---------------------------------------
            if beta_c>0
                E_c = eval_E_c(frag_i, frag_j);

                if E_c>0
                    frags_sol{i}.E_c = [frags_sol{i}.E_c,E_c];
                    frags_sol{i}.N_c = [frags_sol{i}.N_c,j];
                    Exk              = Exk + beta_c*E_c;
                end
            end

            % We project the coordinates of the outer circle center of the
            % ith fragment into the jth fragment domain. If the distance
            % separating the two circle centers is larger than the distance
            % enabling the term E_sf (worst case among all pairse terms, 
            % we can safely skip this couple of fragments to speed up
            frag_i_occ_proj = apply_forward_backward_transforms(frag_i_occ, xk_old(i,1:2), xk_old(i,3), frag_i_center, xk_old(j,1:2), xk_old(j,3), frag_j_center);
            max_gap         = (frag_i_ocr+frag_j_ocr+max(extrapolation_distance, frags_overlap_tolerance));

            if norm(frag_i_occ_proj-frag_j_occ)>max_gap
                continue;
            end

            % We add the contribution of the terms E_no and E_sf
            % --------------------------------------------------
            if beta_no>0 || beta_sf>0
                % We project the pixel coordinates of the ith eroded fragment domain (e(P_wi)) into the frame of the jth fragment domain (P_wj)
                frag_i_coords_e_Pwj = apply_forward_backward_transforms(frag_i_coords_e, xk_old(i,1:2), xk_old(i,3), frag_i_center, ...
                                                                                         xk_old(j,1:2), xk_old(j,3), frag_j_center);
    
                % We only keep projected pixel coordinates that lie into the jth fragment image
                keep = find(frag_i_coords_e_Pwj(:,1)>=1 & frag_i_coords_e_Pwj(:,1)<=frag_j_size(1) & frag_i_coords_e_Pwj(:,2)>=1 & frag_i_coords_e_Pwj(:,2)<=frag_j_size(2));

                if ~isempty(keep)
                    frag_i_coords_e_Pwj = frag_i_coords_e_Pwj(keep,:);

                    if ~isempty(frag_i_coords_e_Pwj)
                        % We add the contribution of the term E_no
                        [E_no,min_dist] = eval_E_no(frags_infos, frag_j, frag_i_coords_e_Pwj, frags_overlap_tolerance, interpolation_type);
        
                        if min_dist<=frags_overlap_tolerance && E_no>0
                            frags_sol{i}.E_no = [frags_sol{i}.E_no,E_no];
                            frags_sol{i}.N_no = [frags_sol{i}.N_no,j];
                            Exk               = Exk + beta_no*E_no;
                        end

                        if beta_sf>0 && (min_dist-frags_overlap_tolerance)>0 && (min_dist-frags_overlap_tolerance)<=extrapolation_distance
                            % We project the pixel coordinates of the ith dilated fragment domain (d(P_wi)) into the frame of the jth fragment domain (P_wj)
                            frag_i_coords_d_Pwj = apply_forward_backward_transforms(frag_i_coords_d, xk_old(i,1:2), xk_old(i,3), frag_i_center, ...
                                                                                                     xk_old(j,1:2), xk_old(j,3), frag_j_center);

                            % We only keep projected pixel coordinates that lie into the frame of the jth fragment image
                            keep = find(frag_i_coords_d_Pwj(:,1)>=1 & frag_i_coords_d_Pwj(:,1)<=frag_j_size(1) & frag_i_coords_d_Pwj(:,2)>=1 & frag_i_coords_d_Pwj(:,2)<=frag_j_size(2));

                            % If the projected fragment does not lie outside the frame of the jth fragment image, we add the contribution of the term E_sf
                            if ~isempty(keep)
                                frag_i_coords_d_Pwi = frag_i_coords_d(keep,:);
                                frag_i_coords_d_Pwj = frag_i_coords_d_Pwj(keep,:);

                                %-----------------
                                %coords  = round(frag_i_coords_d_Pwj);
                                %idx     = sub2ind(frag_j_size, coords(:,1), coords(:,2));
                                %im_tmp  = zeros(frag_j_size);
                                %im_tmp(idx) = get_intensities(im_frag_i_gray_ext, frag_i_coords_d_Pwi, interpolation_type);
                                %return;

                                coords  = round(frag_i_coords_d_Pwj);
                                idx     = sub2ind(frag_j_size, coords(:,1), coords(:,2));
                                keep    = im_frag_j_alpha_d(idx)>0;
                                %-----------------

                                % We compute the term E_sf
                                if ~isempty(keep)
                                    %-------------------------
                                    frag_i_coords_d_Pwi = frag_i_coords_d_Pwi(keep,:);
                                    frag_i_coords_d_Pwj = frag_i_coords_d_Pwj(keep,:);

                                    %coords      = round(frag_i_coords_d_Pwj);
                                    %idx         = sub2ind(frag_j_size, coords(:,1), coords(:,2));
                                    %im_tmp      = zeros(frag_j_size);
                                    %im_tmp(idx) = 1;
                                    %figure, imshow(im_tmp,[]);
                                    %return;
                                    %-------------------------

                                    lambda2 = 20.0;
                                    mu2     = -0.92;
                                    frag_i_intensities  = get_intensities(frags_infos{frag_i.idx}.color_ext, frag_i_coords_d_Pwi, interpolation_type);
                                    frag_j_intensities  = get_intensities(frags_infos{frag_j.idx}.color_ext, frag_i_coords_d_Pwj, interpolation_type);
                                    E_sf                = eval_E_sf(frag_i_intensities, frag_j_intensities, size(frag_i_intensities,1), 3, lambda2, mu2);

                                    %disp(sprintf('card=%d', size(frag_i_intensities,1)));
                                    if size(frag_i_intensities,1)>500 % TODO: CHANGE BY E_sf>0
                                        if i<j
                                            %figure, imshow(im_tmp,[]);
                                            %figure, imshow(im_frag_j_gray_ext,[]);
                                            %toto = abs(double(im_tmp)-double(im_frag_j_gray_ext));
                                            %imwrite(toto, sprintf('im_res_%04d_%04d.png', i, j));
                                            %figure, imshow(toto,[]);
                                            %disp(sprintf('i=%d vs j=%d | E_sf=%f', i, j, E_sf));
                                            all_E_sf = [all_E_sf,E_sf];
                                        end
                                        frags_sol{i}.E_sf = [frags_sol{i}.E_sf,E_sf];
                                        frags_sol{i}.N_sf = [frags_sol{i}.N_sf,j];
                                       Exk                = Exk + beta_sf*E_sf;
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

%     disp(sprintf('#E_d>0      = %d', sum(all_E_d>0)));
%     disp(sprintf('#E_d<0      = %d', sum(all_E_d<0)));
%     disp(sprintf('mean(E_d>0) = %f', mean(all_E_d(all_E_d>0))));
%     disp(sprintf('mean(E_d<0) = %f', mean(all_E_d(all_E_d<0))));

%     disp(sprintf('#E_sf>0      = %d', sum(all_E_sf>0)));
%     disp(sprintf('#E_sf<0      = %d', sum(all_E_sf<0)));
%     disp(sprintf('mean(E_sf>0) = %f', mean(all_E_sf(all_E_sf>0))));
%     disp(sprintf('mean(E_sf<0) = %f', mean(all_E_sf(all_E_sf<0))));

    % We gather all neighboring indexes in the same array for convenience
    for i=1:numel(frags_sol)
        tmp = unique([frags_sol{i}.N_c,frags_sol{i}.N_no,frags_sol{i}.N_sf]);

        if numel(tmp)>0
            frags_sol{i}.neighbors = tmp;
        end
    end
end

% Psi activation function (sigmoid here).
% 
% Inputs:
%   * x:       input data (in [-1,1])
%   * lambda:  sharpness parameter (>0)
%   * mu:      shift parameter (in [-1,1])
% 
% Outputs:
%   * result:  output data (in [-1,1])
function result = psi_x( x, lambda, mu )
    result = 2/(1+exp(-lambda*(x-mu)))-1;
end

% This function returns the value of the unary term E_d
function E_d = eval_E_d( frag_i_intensities_P, frag_i_intensities_Pwi, frag_area, nb_channels, lambda, mu )
    E_d = sum((frag_i_intensities_P(:)-frag_i_intensities_Pwi(:)).^2) / (frag_area*nb_channels);
    E_d = psi_x(2*E_d-1, lambda, mu);
end

% This function returns the value of the unary term E_a
function E_a = eval_E_a( frag_area, fresco_size )
    E_a = -frag_area / prod(fresco_size);
end

% This function returns the value of the unary term E_inc
function E_inc = eval_E_inc( frag_i_coords_P, fresco_size, outside_frag_tolerance )
    % We get nearest neighbors distance from the projection of P_wi in the frame of the fresco domain (P) to it
    [q_dists,~] = get_nearest_points_to_P(fresco_size, frag_i_coords_P);
    q_dists     = sqrt(q_dists);

    % We compute the contribution of all projected pixel coordinates
    E_inc = sum((1/2)*(1+cos((pi*q_dists)/outside_frag_tolerance^2)).*(q_dists>=outside_frag_tolerance^2));
end

% This function returns the value of the pairwise term E_c
function E_c = eval_E_c( frag_i, frag_j )
    E_c = (frag_i.idx==frag_j.idx);
end

% This function returns the value of the pairwise term E_no
function [E_no,min_dist] = eval_E_no( frags_infos, frag_j, frag_i_coords_e_Pwj, frags_overlap_tolerance, interpolation_type )
    % We get nearest neighbors images for the jth fragment
    im_frag_j_nny = frags_infos{frag_j.idx}.nny;
    im_frag_j_nnx = frags_infos{frag_j.idx}.nnx;

    % We compute the contribution of any pixel of the projection P_wi to P_wj
    qstar_y  = get_intensities(im_frag_j_nny, frag_i_coords_e_Pwj, interpolation_type);
    qstar_x  = get_intensities(im_frag_j_nnx, frag_i_coords_e_Pwj, interpolation_type);
    q_diff   = (frag_i_coords_e_Pwj-[qstar_y,qstar_x]);
    snd      = sum(q_diff.^2,2);
    E_no     = sum((1/2)*(1+cos((pi*snd)/frags_overlap_tolerance^2)).*(snd<=frags_overlap_tolerance^2));
    min_dist = min(sqrt(snd));
end

% This function returns the value of the pairwise term E_sf
function E_sf = eval_E_sf( frag_i_intensities, frag_j_intensities, area, nb_channels, lambda, mu )
    E_sf = sum((frag_i_intensities(:)-frag_j_intensities(:)).^2) / (area * nb_channels);
    %E_sf = median((frag_i_intensities(:)-frag_j_intensities(:)).^2);
    E_sf = psi_x(2*E_sf-1, lambda, mu);
end