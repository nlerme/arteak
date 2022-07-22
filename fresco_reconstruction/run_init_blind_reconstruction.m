% This function returns a first guess of fresco reconstruction, when 
% the fresco image is unavailable.
% 
% Inputs:
%   * im_fresco:              fresco image (RGBA image)
%   * frags_infos:            collection of fragments (cell array with RGBA images)
%   * general_parameters:     value of general parameters (non empty cell array)
%   * init_parameters:        value of init parameters (non empty cell array)
%   * gen_parameters:         value of parameters used for generating the fragmented fresco (non empty struct)
%   * geometric_constraints:  geometric constraints (non empty struct)
%   * frags_gt:               ground truth ([non empty] cell array)
% 
% Outputs:
%   * frags_sol:  solution composed of fragments ([non empty] cell array)
function frags_sol = run_init_blind_reconstruction( im_fresco, frags_infos, general_parameters, init_parameters, gen_parameters, geometric_constraints, frags_gt )
    % We initialize variables
    frags_sol               = {};
    frags_counter           = zeros(1,numel(frags_infos));
    max_nb_frag_duplicates  = 1;
    nb_attempts             = 1;
    outside_frag_tolerance  = 0.0;
    frags_overlap_tolerance = 0.0;
    fresco_size             = size(im_fresco);

    % We check if locations are constrained to lie in a finite subset of Z^2
    if isempty(geometric_constraints.locations)
        % If so, we fill as much as possible the fresco with fragments whose location is constrained
        for k=1:size(geometric_constraints.locations,1)
            % We compute the translation
            translation = geometric_constraints.locations(k,:);

            % We look for available fragment images and choose one uniformly at random
            available_frags = find(frags_counter<max_nb_frag_duplicates);
            idx             = available_frags(randi([1,numel(available_frags)]));

            if isempty(idx)
                break;
            end

            % We set some variables for convenience
            ic_center     = frags_infos{idx}.inner_circle_center;
            ic_radius     = frags_infos{idx}.inner_circle_radius;
            oc_center     = frags_infos{idx}.outer_circle_center;
            oc_radius     = frags_infos{idx}.outer_circle_radius;
            im_frag_color = frags_infos{idx}.color;
            im_frag_alpha = frags_infos{idx}.alpha;
            frag_area     = frags_infos{idx}.area;

            % We try to place the chosen fragment image a given number of attempts
            is_placed = false;
            counter   = 0;

            while ~is_placed && counter<nb_attempts
                % We choose an angle of rotation uniformly at random
                if isempty(geometric_constraints.orientations)
                    angle = 360.0*rand(1);
                else
                    angle = geometric_constraints.orientations(randi([1,numel(geometric_constraints.orientations)]));
                end

                [fresco_coords_t,frag_coords_t] = get_transformed_fragment(im_frag_alpha, translation, angle, fresco_size(1:2));
                frag_area_t                     = size(fresco_coords_t,1);
                ic_center_t                     = round(apply_forward_transform(ic_center, translation, angle, ic_center));
                oc_center_t                     = round(apply_forward_transform(oc_center, translation, angle, ic_center));
                ic_radius_t                     = ic_radius;
                oc_radius_t                     = oc_radius;

                % We check if the fragment lies inside the fresco
                if ~is_fragment_inside_fresco(oc_center_t, frag_area_t, fresco_size(1:2), frag_area, outside_frag_tolerance)
                    counter = counter+1;
                    continue;
                end

                % We check if the generated fragment does not intersect with already placed ones
                intersections = 0;
    
                for k=1:length(frags_sol)
                    fresco_coords_t2 = frags_sol{k}.fresco_coords;
                    oc_center_t2     = frags_sol{k}.outer_circle_center;
                    oc_radius_t2     = frags_sol{k}.outer_circle_radius;
    
                    if are_fragments_intersected(fresco_coords_t, oc_center_t, oc_radius_t, fresco_coords_t2, oc_center_t2, oc_radius_t2, frags_overlap_tolerance)
                        intersections = 1;
                        break;
                    end
                end
    
                if intersections
                    counter = counter+1;
                    continue;
                end

                % We add the generated fragment to the list
                frag_intensities_t   = get_intensities(im_frag_color, frag_coords_t, interpolation_type)/255.0;
                fresco_intensities_t = get_intensities(im_fresco_color, fresco_coords_t, interpolation_type)/255.0;
                frag                 = struct('idx', idx, 'translation', translation, 'angle', angle, 'area', frag_area_t, 'inner_circle_center', ic_center_t, ...
                                              'inner_circle_radius', ic_radius_t, 'outer_circle_center', oc_center_t, 'outer_circle_radius', oc_radius_t, ...
                                              'fresco_coords', fresco_coords_t, 'frag_coords', frag_coords_t, 'frag_intensities', frag_intensities_t, ...
                                              'fresco_intensities', fresco_intensities_t, 'neighbors', [], 'color_idx', []);
                frags_sol            = [frags_sol,{frag}];
                is_placed            = true;
                frags_counter(idx)   = frags_counter(idx)+1;
            end
        end
    else
        % If not, we fill as much as possible the fresco with fragments whose location is uniformly taken at random
        disp('TODO ..................');
    end
end