% Function generating a random population of fragments.
% 
% Inputs:
%   * im_fresco_color:        colored fresco image
%   * frags_infos:            infos about fragments
%   * nb_desired_frags:       desired number of fragments
%   * outside_tolerance:      tolerance for outside fragments
%   * overlap_tolerance:      tolerance for overlapping fragments
%   * nb_attempts:            number of attempts
%   * inter_frags_distance:   average geometrical distance between the common borders of two aligned fragments
%   * interpolation_type:     type of interpolation (nearest, bilinear, bicubic, etc.)
%   * max_nb_frag_repeats:    maximum number of times a fragment can appear in the generated solution
%   * forbidden_frags:        array whose entries indicates if a fragment is forbidden to be selected or not (length=#frags_infos)
%   * confidence_maps_dir:    directory where confidence maps are stored
% 
% Outputs:
%   * frags_sol:  solution composed of randomly selected fragments
function frags_sol = generate_random_fragments( im_fresco_color, frags_infos, nb_desired_frags, outside_tolerance, overlap_tolerance, nb_attempts, ...
                                                inter_frags_distance, interpolation_type, max_nb_frag_repeats, forbidden_frags, confidence_maps_dir )
    % We get fresco size
    fresco_size = size(im_fresco_color);

    % We initialize counters for all fragments
    frags_counter = zeros(size(frags_infos));

    % We construct an empty binary image that will consist of the union of placed fragments
    im_frags_union = zeros(fresco_size(1:2), 'logical');

    % We make empty the set of placed fragments
    frags_sol = {};

    % We loop over the number of desired fragments
    for i=1:nb_desired_frags
        % We check if enough space for placing subsequent fragments is still available
        [rows,cols] = find(1-im_frags_union);

        if isempty(rows) || isempty(cols)
            break;
        end

        % If so, we look for available fragments that are allowed and that do not exceed the desired number of repetitions
        available_frags = find((forbidden_frags==0) & (frags_counter<max_nb_frag_repeats));

        if isempty(available_frags)
            break;
        end

        idx = available_frags(randi([1,length(available_frags)]));

        % We set some variables for convenience
        ic_center     = frags_infos{idx}.inner_circle_center;
        ic_radius     = frags_infos{idx}.inner_circle_radius;
        oc_center     = frags_infos{idx}.outer_circle_center;
        oc_radius     = frags_infos{idx}.outer_circle_radius;
        im_frag_color = frags_infos{idx}.color;
        im_frag_alpha = frags_infos{idx}.alpha;
        frag_area     = frags_infos{idx}.area;
        frag_size     = frags_infos{idx}.size;

        % We load the confidence map of the fragment, intersect it with the union of already placed ones and set the threshold
        im_map    = im2double(imread([confidence_maps_dir filesep sprintf('confidence_map_%04d.jpg', idx)]));
        im_map2   = (1-im_frags_union).*im_map;
        threshold = 0.8*max(im_map2(:));

        % We try a number of attempts to place the selected fragment
        is_placed = false;
        counter   = 0;

        while ~is_placed && counter<nb_attempts
            % We choose an angle of rotation uniformly at random
            angle = 360.0*rand(1);

            % We choose a location where the fragment could be placed uniformly at random
            %n           = randi([1,length(rows)]);
            %translation = [rows(n),cols(n)];

            % We choose a location where the fragment could be placed according to confidence map
            translation = get_random_pixel(im_map2, threshold, 1);

            % We apply geometrical transform to the fragment
            [fresco_coords_t,frag_coords_t] = get_transformed_fragment(im_frag_alpha, translation, angle, fresco_size(1:2));
            frag_area_t                     = size(fresco_coords_t,1);
            ic_center_t                     = round(apply_forward_transform([0,0], translation, angle, [0,0]));
            oc_center_t                     = round(apply_forward_transform(oc_center, translation, angle, ic_center));
            ic_radius_t                     = ic_radius;
            oc_radius_t                     = oc_radius;

            % We check if the fragment lies inside the fresco
            if ~is_fragment_inside_fresco(oc_center_t, frag_area_t, fresco_size, frag_area, outside_tolerance)
                counter = counter+1;
                continue;
            end

            % We check if the generated fragment does not intersect too moch with already placed ones
            no_intersections = 1;

            for k=1:length(frags_sol)
                fresco_coords_t2 = frags_sol{k}.fresco_coords;
                oc_center_t2     = frags_sol{k}.outer_circle_center;
                oc_radius_t2     = frags_sol{k}.outer_circle_radius;

                if are_fragments_intersected(fresco_coords_t, oc_center_t, oc_radius_t, fresco_coords_t2, oc_center_t2, oc_radius_t2, overlap_tolerance)
                    no_intersections = 0;
                    break;
                end
            end

            if ~no_intersections
                counter = counter+1;
                continue;
            end

            % We construct the binary image containing the fragment
            im_frag_t               = zeros(fresco_size(1:2), 'logical');
            fresco_idx_t            = sub2ind(fresco_size(1:2), fresco_coords_t(:,1), fresco_coords_t(:,2));
            im_frag_t(fresco_idx_t) = 1;

            % We add the generated fragment
            frag_intensities_t   = get_intensities(im_frag_color, frag_coords_t, interpolation_type)/255.0;
            fresco_intensities_t = get_intensities(im_fresco_color, fresco_coords_t, interpolation_type)/255.0;
            frag                 = struct('idx', idx, 'translation', translation, 'angle', angle, 'area', frag_area_t, 'inner_circle_center', ic_center_t, ...
                                          'inner_circle_radius', ic_radius_t, 'outer_circle_center', oc_center_t, 'outer_circle_radius', oc_radius_t, ...
                                          'fresco_coords', fresco_coords_t, 'frag_coords', frag_coords_t, 'frag_intensities', frag_intensities_t, ...
                                          'fresco_intensities', fresco_intensities_t, 'neighbors', [], 'color_idx', []);
            frags_sol          = [frags_sol,{frag}];
            is_placed          = true;
            frags_counter(idx) = frags_counter(idx)+1;
            im_frags_union     = im_frags_union | im_frag_t;
        end
        %disp(sprintf('+ desired frag %d | %d attempts', i, counter));
    end

    % We compute dilated fragments
    parfor i=1:numel(frags_sol)
        fresco_coords                = frags_sol{i}.fresco_coords;
        fresco_idx_t                 = sub2ind(fresco_size(1:2), fresco_coords(:,1), fresco_coords(:,2));
        im_frag_t                    = zeros(fresco_size(1:2), 'logical');
        im_frag_t(fresco_idx_t)      = 1;
        [rows_d,cols_d]              = find(imdilate(im_frag_t, strel('square', round(2*inter_frags_distance+1))));
        frags_sol{i}.fresco_coords_d = [rows_d,cols_d];
    end
end