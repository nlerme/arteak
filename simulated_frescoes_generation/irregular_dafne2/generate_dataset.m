% This function generates a new dataset from existing fresco images with fragments of irregular shape.
function generate_dataset()
    % We run the main function
    main();

    %----------------------------------------------------------------------
    %----------------------------------------------------------------------
    %----------------------------------------------------------------------

    % Main function
    function main()
        % We delete variables and close windows
        clear all;
        close all;
        clc;

        % We turn off some undesirable warnings
        warning('off', 'images:label2rgb:zerocolorSameAsRegionColor');

        % We add required paths recursively
        addpath_recurse(['..' filesep '..' filesep 'common_tools']);

        % We create a parallel pool if needed
        if isempty(gcp('nocreate'))
            parpool('IdleTimeout', 60*24*7);
        end

        % Parameters
        seed                            = 1;                                                                                              % Seed used for pseudo random number generator (<0=random, >0=fixed seed for reproductibility)
        verbose                         = false;                                                                                          % Enables/disables display of messages on command window (true or false)
        grayscale_conversion            = false;                                                                                          % Enables/disables grayscale conversion of both fresco and fragment images (true or false)
        interpolation_type              = 'nearest';                                                                                      % Interpolation type for reconstructing frescoes from fragments (nearest, bilinear, bicubic, etc.)
        nb_attempts                     = 100;                                                                                            % Number of attempts when extracting random patches from fresco images (>0)
        padding_factor                  = 1.2;                                                                                            % Factor by which fragment images are enlarged before saving; e.g. 1.2 means 20% of enlargement (>=0)
        fragments_palette_sizes         = [256];                                                                                          % Reduced number of color for fading on fragment images (vector with entries in {0,...,256})
        fragments_erosion_rates         = [0.0,0.003,0.006];                                                                              % Percentages of fragments erosion, relatively to the fresco image size (vector with entries in [0,1])
        fragments_noise_stds            = [0.0];                                                                                          % Standard deviations of Gaussian noise applied on each fragment (vector of positive reals)
        fragments_missing_rates         = [0.0,0.2];                                                                                      % Percentages of missing fragments (vector with entries in [0,1])
        fragments_spurious_rates        = [0.2,0.2];                                                                                      % Percentages of spurious fragments (vector with entries in [0,1])
        fragments_erosion_factors_range = [1.0,1.0];                                                                                      % Range of erosion factors for varying erosion radii in the same fresco (pair of positive reals)
        fragments_scale_factors_range   = [1.0,1.0];                                                                                      % Range of scale factors of spuriously generated fragments (pair of positive reals)
        fresco_palette_sizes            = [256];                                                                                          % Reduced number of color for fading on fresco image (vector with entries in {0,...,256})
        fresco_missing_parts_rates      = 0.0:0.1:1.0;                                                                                    % Percentages of missing parts of the fresco image (vector with entries in [0,1])
        fresco_missing_parts_params     = struct('type', 'power_law', 'exponent', 1.8);                                                   % Parameters for simulating degradations of the fresco image (struct)
        fresco_noise_stds               = [0.0];                                                                                          % Standard deviations of Gaussian noise of the fresco image (vector of positive reals)
        fresco_fragmentation_min_dists  = [0.05,0.10,0.15];                                                                               % Minimum distances between sampled location of fragments, relatively to the fresco image size (vector of positive reals)
        fresco_fragmentation_nb_frags   = [100,200,300];                                                                                  % Number of sampled fragments; 0 means that value is not used (optional; vector of non-negative integers)
        fresco_fragmentation_params     = struct('sampling_min_dist', [], 'sampling_nb_points', [], 'sampling_type', 'non-uniform--loyd', ...
                                                 'noise_exponent', 1.0, 'uncertainty_band_size', 0.5, ...
                                                 'beta', 0.5, 'metric', 'euclidean');                                                     % Parameters for simulating fragmentation of frescoes (struct)
        input_frescoes_dir              = ['..' filesep '..' filesep '..' filesep 'data' filesep 'simulated' filesep 'irregular_dafne1']; % Input frescoes directory (string)
        input_frescoes_fns              = get_files_list(input_frescoes_dir);                                                             % Input frescoes filenames (cell array of strings)
        output_frescoes_dir             = ['..' filesep '..' filesep '..' filesep 'data' filesep 'simulated' filesep 'irregular_dafne2']; % Output frescoes directory (string)
        background_color                = [0,0,0];                                                                                        % RGB color of reconstructed fresco (in [0,1]^3)
        frags_idx_color                 = 'white';                                                                                        % Color of fragment index in reconstructed fresco (string or [0,1]^3)
        neighbors_color                 = 'cyan';                                                                                         % Color of neighboring relationships between fragments in reconstructed fresco (string or [0,1]^3)
        purge_dataset                   = true;                                                                                           % Enables/disables destruction of previous version of dataset (true or false)

        % We set the seed for pseudo random number generation. simdTwister algorithm is used for 
        % reproducibility (same sequence of random numbers will be obtained on different machines)
        if seed<0
            rng('shuffle', 'simdTwister');
        else
            rng(seed, 'simdTwister');
        end

        % We check if the input directory exists
        if ~isfolder(input_frescoes_dir)
            error(sprintf('Unable to find input directory %s', input_frescoes_dir));
        end

        % We create output directory if needed
        if ~isfolder(output_frescoes_dir)
            mkdir(output_frescoes_dir);
        else
            if purge_dataset
                rmdir(output_frescoes_dir, 's');
                mkdir(output_dir);
                disp('[ old dataset removed ]');
            else
                error(sprintf('The output directory %s is not empty. Please remove it or set flag purge_dataset to true.', output_frescoes_dir));
            end
        end

        % We loop over input fresco filenames
        for i=1:numel(input_frescoes_fns)
            % We create output directory or delete it
            [~,fresco_name,~] = fileparts(input_frescoes_fns{i});
            all_other_fns     = setdiff(input_frescoes_fns, input_frescoes_fns{i});
            fresco_dir        = [output_frescoes_dir filesep fresco_name];

            if ~isfolder(fresco_dir)
                mkdir(fresco_dir);
            end

            % Message
            disp(sprintf('+ %s (%d/%d)', fresco_name, i, numel(input_frescoes_fns)));

            % We load fresco image and get its size
            [im_fresco_color,~] = load_image(input_frescoes_fns{i}, grayscale_conversion);
            fresco_size         = size(im_fresco_color,[1,2]);
            nb_channels         = size(im_fresco_color,3);

            if isempty(im_fresco_color)
                error(sprintf('Unable to load fresco image %s', input_frescoes_fns{i}));
            end

            % We save a copy of the fresco image
            imwrite(im_fresco_color, [fresco_dir filesep fresco_name '.png'], 'Alpha', uint8(255*ones(fresco_size)));

            %--------------------------------------------------------------

            % We loop over Gaussian noise levels
            for j=1:numel(fresco_noise_stds)
                noise_std = fresco_noise_stds(j);

                % We look over palette sizes
                for k=1:numel(fresco_palette_sizes)
                    palette_size = fresco_palette_sizes(k);

                    % We simulate degradations on the fresco image
                    [im_fresco_color_g,~,im_fresco_alphas] = simulate_fresco_degradations(im_fresco_color, noise_std, palette_size, fresco_missing_parts_rates, fresco_missing_parts_params);

                    % We loop over missing parts rates
                    for l=1:numel(fresco_missing_parts_rates)
                        missing_parts_rate = fresco_missing_parts_rates(l);

                        % We save the degraded fresco image
                        imwrite(im_fresco_color_g, [fresco_dir filesep sprintf('%s_n=%.2f_ps_%d_mp_%d.png', fresco_name, noise_std, palette_size, round(100*missing_parts_rate))], 'Alpha', im_fresco_alphas(:,:,l));
                    end
                end
            end

            %--------------------------------------------------------------

            % We loop over minimum distances between fragments (related with number/size of fragments)
            for j=1:numel(fresco_fragmentation_min_dists)
                fresco_fragmentation_min_dist  = fresco_fragmentation_min_dists(j);
                fresco_fragmentation_min_dist2 = min(fresco_fragmentation_min_dist*fresco_size);
                fresco_fragmentation_nb_frags = fresco_fragmentation_nb_frags(j);

                % We add them to the parameters structure
                fresco_fragmentation_params.sampling_min_dist  = fresco_fragmentation_min_dist2;
                fresco_fragmentation_params.sampling_nb_points = fresco_fragmentation_nb_frags;

                % Message
                msg(sprintf('  + minimum distance=%f (nb frags=%d)', fresco_fragmentation_min_dist, fresco_fragmentation_nb_frags), verbose);

                % We generate the fragmentation
                [im_seg,~] = simulate_fresco_fragmentation(fresco_size, fresco_fragmentation_params);

                % We generate another fragmentation in case of spurious fragments are needed
                [im_seg_s,~] = simulate_fresco_fragmentation(fresco_size, fresco_fragmentation_params);
                nb_available_spurious_frags = max(im_seg_s(:));

                % We build the list of fragments
                nb_total_frags     = max(im_seg(:));
                frags_infos        = cell(1,nb_total_frags);
                frags_angles       = cell(1,nb_total_frags);
                frags_translations = cell(1,nb_total_frags);
                frags_seg_idx      = cell(1,nb_total_frags);

                for k=1:nb_total_frags
                    scale_factor                    = 1.0;
                    frags_angles{k}                 = rand_bounds(0.0, 360.0); % CAUTION: rotation is counterclockwise
                    [im_frag_color,im_frag_alpha,t] = create_fragment_image(im_fresco_color, im_seg, k, frags_angles{k}, scale_factor, padding_factor, interpolation_type);
                    frags_translations{k}           = t;
                    frags_infos{k}                  = struct('alpha', im_frag_alpha, 'color', im_frag_color);
                    frags_seg_idx{k}                = k;
                end

                % We loop over missing fragments rates
                for k=1:numel(fragments_missing_rates)
                    % Message
                    missing_rate = fragments_missing_rates(k);
                    msg(sprintf('    + missing fragment rate=%.2f%%', 100.0*missing_rate), verbose);

                    % We discard some proportion of fragments, shuffle the remaining ones
                    nb_frags_kept       = round((1-missing_rate)*nb_total_frags);
                    rp                  = randperm(nb_total_frags, nb_frags_kept);
                    frags_infos2        = frags_infos(rp);
                    frags_translations2 = frags_translations(rp);
                    frags_angles2       = frags_angles(rp);
                    frags_seg_idx2      = frags_seg_idx(rp);

                    % We loop over spurious fragments rates
                    for l=1:numel(fragments_spurious_rates)
                        % Message
                        spurious_rate = fragments_spurious_rates(l);
                        msg(sprintf('      + spurious fragment rate=%.2f%%', 100*spurious_rate), verbose);

                        % We add some proportion of spurious fragments
                        if spurious_rate>0
                            nb_frags_to_add     = round(spurious_rate*nb_total_frags);
                            extra_idx           = (1:nb_frags_to_add)+numel(frags_infos2);
                            frags_infos3        = frags_infos2;
                            frags_translations3 = frags_translations2;
                            frags_angles3       = frags_angles2;
                            frags_seg_idx3      = frags_seg_idx2;

                            for m=1:numel(extra_idx)
                                my_idx                        = extra_idx(mod(m-1,nb_available_spurious_frags-1)+1); % to avoid out of bounds for index
                                [im_frag_color,im_frag_alpha] = extract_random_patch_from_frescoes(im_seg_s, m, all_other_fns, nb_attempts, grayscale_conversion, ...
                                                                                                   fragments_scale_factors_range, padding_factor, interpolation_type);
                                frags_infos3{my_idx}          = struct('alpha', im_frag_alpha, 'color', im_frag_color);
                                frags_translations3{my_idx}   = [];
                                frags_angles3{my_idx}         = 0.0;
                                frags_seg_idx3{my_idx}        = 0;
                            end

                            % We shuffle fragments again to gain randomness
                            nb_frags3           = numel(frags_infos3);
                            rp                  = randperm(nb_frags3);
                            frags_infos3        = frags_infos3(rp);
                            frags_translations3 = frags_translations3(rp);
                            frags_angles3       = frags_angles3(rp);
                            frags_seg_idx3      = frags_seg_idx3(rp);
                            spurious_idx        = [];
                            true_idx            = [];

                            for idx=1:numel(frags_infos2)
                                true_idx = [true_idx,find(rp==idx)];
                            end

                            for idx=extra_idx
                                spurious_idx = [spurious_idx,find(rp==idx)];
                            end

                            true_idx     = sort(true_idx);
                            spurious_idx = sort(spurious_idx);
                        else
                            frags_infos3        = frags_infos2;
                            frags_translations3 = frags_translations2;
                            frags_angles3       = frags_angles2;
                            frags_seg_idx3      = frags_seg_idx2;
                            spurious_idx        = [];
                            true_idx            = 1:numel(frags_infos3);
                        end

                        % We loop over Gaussian noise levels
                        for m=1:numel(fragments_noise_stds)
                            % Message
                            noise_std = fragments_noise_stds(m);
                            msg(sprintf('        + noise std=%f', noise_std), verbose);

                            % We loop over palette sizes
                            for n=1:numel(fragments_palette_sizes)
                                % Message
                                palette_size = fragments_palette_sizes(n);
                                msg(sprintf('          + palette size=%d', palette_size), verbose);

                                % We loop over erosion rates
                                for o=1:numel(fragments_erosion_rates)
                                    % Message
                                    erosion_rate   = fragments_erosion_rates(o);
                                    erosion_radius = round(min(fresco_size)*erosion_rate);
                                    min_dist       = round(fresco_fragmentation_min_dist2);
                                    msg(sprintf('            + erosion rate=%d', erosion_rate), verbose);

                                    % We set names of files and directories
                                    config_dir        = [fresco_dir filesep sprintf('%s_%d_%d_%d_%.2f_%d_%d', fresco_name, min_dist, round(missing_rate*100), round(spurious_rate*100), noise_std, palette_size, erosion_radius)];
                                    frags_dir         = [config_dir filesep 'frag_eroded'];
                                    true_frags_fn     = [config_dir filesep 'fragments.txt'];
                                    spurious_frags_fn = [config_dir filesep 'fragments_s.txt'];
                                    constraints_fn    = [frags_dir filesep 'geometric_constraints.txt'];
                                    parameters_fn     = [frags_dir filesep 'gen_parameters.txt'];
                                    neighbors_fn      = [config_dir filesep 'neighbors.txt'];
                                    rebuilt_img_fn    = [config_dir filesep 'rebuilt_image.png'];
                                    rebuilt_img_n_fn  = [config_dir filesep 'rebuilt_image_n.png'];

                                    % We create necessary directories
                                    if ~isfolder(config_dir)
                                        mkdir(config_dir);
                                    end

                                    if ~isfolder(frags_dir)
                                        mkdir(frags_dir);
                                    end

                                    % We simulate degradations on the fragment images (ok)
                                    min_erosion_factor = fragments_erosion_factors_range(1)*ones(1,numel(frags_infos3));
                                    max_erosion_factor = fragments_erosion_factors_range(2)*ones(1,numel(frags_infos3));
                                    erosion_radii      = max(0,round(erosion_radius*rand_bounds(min_erosion_factor,max_erosion_factor)));
                                    noise_stds         = noise_std*ones(1,numel(frags_infos3));
                                    palette_sizes      = palette_size*ones(1,numel(frags_infos3));
                                    frags_infos3       = simulate_fragments_degradations(frags_infos3, erosion_radii, noise_stds, palette_sizes);

                                    % We save the parameters used for generating fragment images (ok)
                                    save_gen_parameters({'palette_size', 'min_dist', 'missing_rate', 'spurious_rate', 'mean_frags_gap', 'noise_std', 'fragmentation_params', ...
                                                         'min_scale_factor', 'max_scale_factor', 'min_erosion_factor', 'max_erosion_factor', ...
                                                         'padding_factor', 'interpolation_type', 'nb_attempts'}, ...
                                                        {uint64(palette_size), double(fresco_fragmentation_min_dist2), double(missing_rate*100), double(spurious_rate*100), ...
                                                         double(2*mean(erosion_radii)), double(noise_std), fresco_fragmentation_params, ...
                                                         double(fragments_scale_factors_range(1)), double(fragments_scale_factors_range(2)), ...
                                                         double(fragments_erosion_factors_range(1)), double(fragments_erosion_factors_range(2)), ...
                                                         double(padding_factor), interpolation_type, uint64(nb_attempts)}, ...
                                                         parameters_fn);

                                    % We save the fragment images
                                    save_fragment_images(frags_infos3, frags_dir);

                                    % We save the list of true fragments
                                    save_true_fragments(frags_translations3, frags_angles3, true_idx, true_frags_fn);

                                    % We save the list of spurious fragments
                                    save_spurious_fragments(spurious_idx, spurious_frags_fn);

                                    % We save the file constraining the placement of fragment images (no constraints here)
                                    geometric_constraints = struct('locations', [], 'orientations', []);
                                    save_geometric_constraints(geometric_constraints, constraints_fn);

                                    % We construct the solution composed of fragments
                                    frags_sol = create_fragments_solution(im_seg, frags_translations3, frags_angles3, frags_seg_idx3, true_idx);

                                    % We save the neighboring relationships between fragments
                                    save_fragment_neighbors(frags_sol, neighbors_fn);

                                    % We build the ideal fresco reconstruction
                                    [~,~,im_rec_color] = get_reconstructed_fresco(fresco_size, nb_channels, frags_infos3, frags_sol, interpolation_type, background_color);

                                    %--- debug ---
                                    %figure, imshow(im_rec_color,[]);
                                    %-------------

                                    % We save the ideal fresco reconstructions
                                    save_reconstructed_fresco(im_rec_color, {}, frags_idx_color, neighbors_color, rebuilt_img_fn);          % reconstructed fresco without neighboring relationships
                                    save_reconstructed_fresco(im_rec_color, frags_sol, frags_idx_color, neighbors_color, rebuilt_img_n_fn); % reconstructed fresco with neighboring relationships
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
