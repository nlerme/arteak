% This function builds a dataset with fragments of regular shape.
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

        % We add required paths recursively
        addpath_recurse(['..' filesep 'common_tools']);

        % We create a parallel pool if needed
        if isempty(gcp('nocreate'))
            parpool('IdleTimeout', 60*24*7);
        end

        % Parameters
        seed                        = 1;                                                                                 % Seed used for pseudo random number generator (<0=random, >0=fixed seed for reproductibility)
        verbose                     = false;                                                                             % Enables/disables display of messages on command window (true or false)
        fragments_sizes             = {[0.1,0.1],[0.15,0.15],[0.2,0.2],[0.25,0.25]};                                     % Fragment sizes {[sy,sx]}_{i=1}^n in percentage of the smallest size of the fresco image (cell array with vectors in ]0,1[^2)
        grayscale_conversion        = false;                                                                             % Enables/disables grayscale conversion of both fresco and fragment images (true or false)
        use_rotated_fragments       = true;                                                                              % Enables/disables use of rotated fragments (true or false)
        fragments_erosion_rates     = [0.0,0.003];                                                                       % Amount of erosion in percentage of the smallest size of the fresco image (vector with entries in [0,1[)
        fragments_missing_rates     = [0.0,0.2];                                                                         % Percentages of missing fragments (vector with entries in ]0,1])
        fragments_spurious_rates    = [0.0,0.2];                                                                         % Percentages of spurious fragments (vector with entries in [0,1[)
        fresco_missing_parts_rates  = linspace(0.0,1.0,10);                                                              % Percentages of degradation of the fresco image (vector with entries in [0,1])
        fresco_missing_parts_params = struct('type', 'perlin', 'nb_octaves', 8, 'persistence', 0.3);                     % Parameters for simulating degradation over the fresco (struct)
        input_frescoes_dir          = ['..' filesep '..' filesep 'data' filesep 'simulated' filesep 'irregular_dafne1']; % Input frescoes directory (string)
        input_frescoes_fns          = get_files_list(input_frescoes_dir);                                                % Input fresco filenames (cell array of strings)
        output_frescoes_dir         = ['..' filesep '..' filesep 'data' filesep 'simulated' filesep 'regular'];          % Output frescoes directory (string)
        background_color            = [0,0,0];                                                                           % RGB color of reconstructed fresco (in [0,1]^3)
        purge_dataset               = true;                                                                              % Enables/disables destruction of previous version of dataset (true or false)
        idx_color                   = 'white';                                                                           % Color of fragment index in reconstructed fresco (string or [0,1]^3)
        neighbors_color             = 'cyan';                                                                            % Color of neighboring relationships between fragments in reconstructed fresco (string or [0,1]^3)

        % We set the seed for pseudo random number generation. simdTwister algorithm is used for 
        % reproducibility (same sequence of random numbers will be obtained on different machines)
        if seed<0
            rng('shuffle', 'simdTwister');
        else
            rng(seed, 'simdTwister');
        end

        % We create output directory if needed
        if purge_dataset && isfolder(output_frescoes_dir)
            rmdir(output_frescoes_dir, 's');
        end

        if ~isfolder(output_frescoes_dir)
            mkdir(output_frescoes_dir);
        end

        % We loop over input fresco filenames
        parfor i=1:numel(input_frescoes_fns)
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

            % We save a copy of the fresco image
            imwrite(im_fresco_color, [fresco_dir filesep fresco_name '.png'], 'Alpha', uint8(255*ones(fresco_size)));

            % We simulate degradations over the fresco image
            noise_std              = 0.0; % Standard deviation of Gaussian noise
            [~,~,im_fresco_alphas] = simulate_fresco_degradations(im_fresco_color, noise_std, fresco_missing_parts_rates, fresco_missing_parts_params);

            % We loop over degradation rates
            for j=1:numel(fresco_missing_parts_rates)
                missing_part_rate = fresco_missing_parts_rates(j);

                % We save the degraded fresco image
                imwrite(im_fresco_color, [fresco_dir filesep sprintf('%s_degraded_%d.png', fresco_name, round(100*missing_part_rate))], 'Alpha', im_fresco_alphas(:,:,j));
            end

            % We loop over fragment sizes
            for k=1:numel(fragments_sizes)
                % Message
                fragment_size = 2*floor(min(fresco_size)*fragments_sizes{k}*0.5)+1; % make fragment size as odd integers to cope with the problem of their accurate placement
                msg(sprintf('  + fragment size=[%d,%d]', fragment_size(1), fragment_size(2)), verbose);

                % We pad fresco image with zeros if needed
                nb_frags       = floor(fresco_size./fragment_size);
                nb_total_frags = prod(nb_frags);
                padding_size   = fresco_size - (fragment_size.*nb_frags);
                ul_translation = floor(padding_size*0.5);
                im_frags       = cell(1,nb_total_frags);

                % We loop over fragments
                frag_coords       = cell(1,nb_total_frags);
                frag_translations = cell(1,nb_total_frags);

                for ii=0:(nb_frags(1)-1)
                    for jj=0:(nb_frags(2)-1)
                        p                       = ([ii,jj].*fragment_size+1)+ul_translation;
                        q                       = p+fragment_size-1;
                        im_frag                 = im_fresco_color(p(1):q(1), p(2):q(2), :);
                        idx1                    = ii*nb_frags(2)+jj+1;
                        frag_translations(idx1) = {round((q-p)*0.5 + p)};
                        im_frags(idx1)          = {im_frag};
                        frag_coords(idx1)       = {[ii,jj]};
                    end
                end

                % We fill arrays constraining the placement and rotation of fragments
                available_translations = frag_translations;
                angles_list            = [0.0,90.0,180.0,270.0]; % CAUTION: rotation is counterclockwise

                if use_rotated_fragments
                    available_angles = {angles_list};
                else
                    available_angles = {[0.0]};
                end

                % We loop over missing fragments rates
                for l=1:numel(fragments_missing_rates)
                    % Message
                    missing_rate = fragments_missing_rates(l);
                    msg(sprintf('    + missing fragment rate=%.2f%%', 100.0*missing_rate), verbose);

                    % We discard some proportion of fragments, shuffle the remaining ones
                    nb_frags_kept      = round((1-missing_rate)*nb_total_frags);
                    rp                 = randperm(nb_total_frags, nb_frags_kept);
                    im_frags2          = im_frags(rp);
                    frag_translations2 = frag_translations(rp);
                    frag_coords2       = frag_coords(rp);

                    % We loop over spurious fragments rates
                    for m=1:numel(fragments_spurious_rates)
                        % Message
                        spurious_rate = fragments_spurious_rates(m);
                        msg(sprintf('      + spurious fragment rate=%.2f%%', 100*spurious_rate), verbose);

                        % We add some proportion of spurious fragments
                        if spurious_rate>0
                            nb_frags_to_add    = round(spurious_rate*nb_total_frags);
                            extra_idx          = (1:nb_frags_to_add)+numel(im_frags2);
                            im_frags3          = im_frags2;
                            frag_translations3 = frag_translations2;
                            frag_coords3       = frag_coords2;

                            for idx=extra_idx
                                im_frag                 = randomly_extract_rectangular_patch_from_frescoes(all_other_fns, grayscale_conversion, fragment_size);
                                im_frags3(idx)          = {im_frag};
                                frag_translations3(idx) = {[]};
                                frag_coords3(idx)       = {[]};
                            end

                            % We shuffle fragments again to gain randomness
                            nb_frags3          = numel(im_frags3);
                            rp                 = randperm(nb_frags3);
                            im_frags3          = im_frags3(rp);
                            frag_translations3 = frag_translations3(rp);
                            frag_coords3       = frag_coords3(rp);
                            spurious_idx       = [];
                            true_idx           = [];

                            for idx=1:numel(im_frags2)
                                true_idx = [true_idx,find(rp==idx)];
                            end

                            for idx=extra_idx
                                spurious_idx = [spurious_idx,find(rp==idx)];
                            end

                            true_idx     = sort(true_idx);
                            spurious_idx = sort(spurious_idx);
                        else
                            im_frags3          = im_frags2;
                            frag_translations3 = frag_translations2;
                            frag_coords3       = frag_coords2;
                            spurious_idx       = [];
                            true_idx           = 1:numel(im_frags3);
                        end

                        % We loop over erosion rates
                        for n=1:numel(fragments_erosion_rates)
                            % Message
                            erosion_rate   = fragments_erosion_rates(n);
                            erosion_radius = round(min(fresco_size)*erosion_rate);
                            msg(sprintf('        + erosion radius=%d', erosion_radius), verbose);

                            % We set names of files and directories
                            config_dir        = [fresco_dir filesep sprintf('%s_%d_%d_%d_%d', fresco_name, fragment_size(1), round(missing_rate*100), round(spurious_rate*100), erosion_radius)];
                            frags_dir         = [config_dir filesep 'frag_eroded'];
                            true_frags_fn     = [config_dir filesep 'fragments.txt'];
                            spurious_frags_fn = [config_dir filesep 'fragments_s.txt'];
                            constraints_fn    = [frags_dir filesep 'geometric_constraints.txt'];
                            parameters_fn     = [frags_dir filesep 'gen_parameters.txt'];
                            neighbors_fn      = [config_dir filesep 'neighbors.txt'];
                            rebuilt_img_fn    = [config_dir filesep 'rebuilt_image.png'];
                            rebuilt_img_n_fn  = [config_dir filesep 'rebuilt_image_n.png'];

                            % We create necessary directories
                            mkdir(config_dir);
                            mkdir(frags_dir);

                            % We save the parameters used for generating fragment images
                            save_gen_parameters({'fragment_size', 'missing_rate', 'spurious_rate', 'mean_frags_gap'}, ...
                                                {uint32(fragment_size(1)), double(missing_rate*100), double(spurious_rate*100), double(2*erosion_radius)}, ...
                                                parameters_fn);

                            % We save the set of rotated and eroded fragment images
                            [im_frags4,frag_angles] = save_rectangular_fragments_images(im_frags3, erosion_radius, use_rotated_fragments, angles_list, fragment_size, frags_dir);

                            % We save the list of true fragment coordinates
                            save_true_fragments_parameters(frag_translations3, frag_angles, true_idx, true_frags_fn);

                            % We save the list of spurious fragments
                            save_spurious_fragments_idx(spurious_idx, spurious_frags_fn);

                            % We save the file constraining the placement of fragment images
                            geometric_constraints = struct('locations', [], 'orientations', []);

                            for o=1:numel(available_translations)
                                translation = available_translations(o);
                                translation = translation{1};
                                geometric_constraints.locations = [geometric_constraints.locations;translation];
                            end

                            geometric_constraints.orientations = available_angles{1};

                            save_geometric_constraints(geometric_constraints, constraints_fn);

                            % We construct the solution composed of fragments
                            frags_sol = get_fragments(frag_coords3, frag_translations3, frag_angles, true_idx);

                            % We save the neighboring relationships between fragments
                            save_fragment_neighbors(frags_sol, neighbors_fn);

                            % We build the ideal fresco reconstruction
                            im_rec_color = reconstruct_fresco(im_fresco_color, im_frags4, frags_sol, background_color, []);

                            % We save the ideal fresco reconstructions
                            save_reconstructed_fresco(im_rec_color, {}, idx_color, neighbors_color, rebuilt_img_fn);          % reconstructed fresco without neighboring relationships
                            save_reconstructed_fresco(im_rec_color, frags_sol, idx_color, neighbors_color, rebuilt_img_n_fn); % reconstructed fresco with neighboring relationships
                        end
                    end
                end
            end
        end
    end
end
