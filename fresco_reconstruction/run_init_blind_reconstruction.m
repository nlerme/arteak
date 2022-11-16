% This function returns a first guess of fresco reconstruction, when 
% the fresco image is unavailable.
% 
% Inputs:
%   * im_fresco_color:        color image of fresco (non empty uint8 matrix)
%   * im_fresco_alpha:        alpha image of fresco (non empty uint8 matrix)
%   * frags_infos:            collection of fragments (cell array with RGBA images)
%   * general_parameters:     value of general parameters (non empty cell array)
%   * init_parameters:        value of init parameters (non empty cell array)
%   * gen_parameters:         value of parameters used for generating the fragmented fresco (non empty struct)
%   * geometric_constraints:  geometric constraints (non empty struct)
%   * frags_gt:               ground truth ([non empty] cell array)
% 
% Outputs:
%   * frags_sol:  solution composed of fragments (cell array)
function frags_sol = run_init_blind_reconstruction( im_fresco_color, im_fresco_alpha, frags_infos, general_parameters, init_parameters, gen_parameters, geometric_constraints, frags_gt )
    % We erase the content of the color image according to the alpha channel
    im_fresco_color = zeros(size(im_fresco_alpha));

    % We initialize variables
    interpolation_type          = get_parameter_value(general_parameters, 'interpolation_type');
    verbose                     = get_parameter_value(general_parameters, 'verbose');
    outside_fragment_tolerance  = get_parameter_value(init_parameters, 'outside_fragment_tolerance');
    fragments_overlap_tolerance = get_parameter_value(init_parameters, 'fragments_overlap_tolerance');
    max_cover_rate              = get_parameter_value(init_parameters, 'max_cover_rate');
    frags_sol                   = {};
    frags_counter               = zeros(1,numel(frags_infos));
    max_nb_frag_duplicates      = 1; % maximum number of occurrences of the same fragment image
    fresco_size                 = size(im_fresco_alpha);
    fresco_nb_pixels            = numel(im_fresco_alpha);

    % We check if locations are constrained to lie in a finite subset of Z^2
    if ~isempty(geometric_constraints.locations)
        % If so, we fill as much as possible the fresco with fragments whose location is constrained
        max_nb_attempts = 10;
        cover_rate      = 0.0;
        order           = randperm(size(geometric_constraints.locations,1));

        for k=order
            % We get the translation
            translation = flip(geometric_constraints.locations(k,:));

            % We look for available fragment images and choose one uniformly at random
            available_frags = find(frags_counter<max_nb_frag_duplicates);

            if isempty(available_frags)
                break;
            end

            idx = available_frags(randi([1,numel(available_frags)]));

            % We try to place the chosen fragment image
            is_placed   = false;
            nb_attempts = 0;

            while ~is_placed && nb_attempts<max_nb_attempts
                % We choose an angle of rotation uniformly at random
                if isempty(geometric_constraints.orientations)
                    angle = 360.0*rand(1);
                else
                    angle = -geometric_constraints.orientations(randi([1,numel(geometric_constraints.orientations)]));
                end

                % We try to place the fragment
                frag = place_fragment(frags_infos, idx, translation, angle, frags_sol, im_fresco_color, im_fresco_alpha, interpolation_type, outside_fragment_tolerance, fragments_overlap_tolerance);

                if ~isempty(frag)
                    % We add it to the list
                    cover_rate         = cover_rate + (frag.area / fresco_nb_pixels);
                    frags_sol          = [frags_sol,{frag}];
                    is_placed          = true;
                    frags_counter(idx) = frags_counter(idx)+1;
                else
                    nb_attempts = nb_attempts+1;
                end
            end

            if cover_rate>=max_cover_rate
                break;
            end
        end
    else
        % If not, we fill as much as possible the fresco with fragments whose location is uniformly taken at random
        im_frags_union = zeros(fresco_size, 'logical');
        cover_rate     = 0.0;

        while cover_rate<max_cover_rate
            % We look for available fragment images and choose one uniformly at random
            available_frags = find(frags_counter<max_nb_frag_duplicates);

            if isempty(available_frags)
                break;
            end

            idx = available_frags(randi([1,numel(available_frags)]));

            % We choose a translation
            [rows,cols] = find(1-im_frags_union);

            if isempty(rows) || isempty(cols)
                break;
            end

            translation = [rows(randi([1,numel(rows)])),cols(randi([1,numel(cols)]))];

            % We choose an angle of rotation taken uniformly at random
            if isempty(geometric_constraints.orientations)
                angle = 360.0*rand(1);
            else
                angle = -geometric_constraints.orientations(randi([1,numel(geometric_constraints.orientations)]));
            end

            % We try to place the fragment
            frag = place_fragment(frags_infos, idx, translation, angle, frags_sol, im_fresco_color, im_fresco_alpha, interpolation_type, outside_fragment_tolerance, fragments_overlap_tolerance);

            if ~isempty(frag)
                % We add id to the image with the union of placed fragments
                im_frag          = zeros(fresco_size, 'logical');
                offsets          = sub2ind(fresco_size, frag.fresco_coords(:,1), frag.fresco_coords(:,2));
                im_frag(offsets) = 1;
                im_frags_union   = im_frags_union | im_frag;

                % We add it to the list
                cover_rate         = cover_rate + (frag.area / fresco_nb_pixels);
                frags_sol          = [frags_sol,{frag}];
                frags_counter(idx) = frags_counter(idx)+1;
            end
        end
    end

    % We erase fields containing pixel coordinates to ensure that they will only be devoted to the fresco reconstruction
    for k=1:numel(frags_sol)
        frags_sol{k}.fresco_coords = [];
        frags_sol{k}.frag_coords   = [];
    end
end