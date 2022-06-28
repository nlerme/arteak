% This function builds a dataset with fragments of regular size
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
        seed                     = 1;                                                          % Seed used for pseudo random number generator (0=random, >0=fixed seed for reproductibility)
        verbose                  = false;                                                       % Enables/disables display of messages on command window
        fragments_sizes          = {[0.1,0.1]};                                      % Fragment sizes {[sy,sx]}_{i=1}^n in percentage of the smallest size of the fresco image (in ]0,1[)
        grayscale_conversion     = false;                                                      % Enables/disables grayscale conversion of both fresco and fragment images (true or false)
        use_rotated_fragments    = true;                                                       % Enables/disables use of rotated fragments (true or false)
        erosion_fragments_rates  = [0.0,0.003];                                           % Amount of erosion in percentage of the smallest size of the fresco image (in [0,1[)
        missing_fragments_rates  = [0.0,0.2];                                                 % Percentages of missing fragments (in ]0,1])
        spurious_fragments_rates = [0.0,0.2];                                                 % Percentages of spurious fragments (in [0,1[)
        fresco_degradation_rates = [0.0,0.3];                                                 % Percentage of degradation of the fresco image (in [0,1])
        input_dir                = ['..' filesep '..' filesep 'data' filesep 'irregular_db1']; % Input directory name (string)
        input_fns                = get_files_list(input_dir);                                  % Input image filenames (string)
        output_dir               = ['..' filesep '..' filesep 'data' filesep 'regular_db1'];   % Output directory name (string)
        background_color         = [0,0,0];                                                    % RGB color of reconstructed fresco (in [0,1]^3)
        purge_dataset            = true;                                                       % Enables/disables destruction of anterior dataset

        % We set the seed for pseudo random number generation. simdTwister algorithm is used for 
        % reproductibility (same sequence of random numbers will be obtained on different machines)
        rng(seed, 'simdTwister');

        % We create output directory if needed
        if purge_dataset && isfolder(output_dir)
            rmdir(output_dir, 's');
        end

        if ~isfolder(output_dir)
            mkdir(output_dir);
        end

        % We loop over input fresco filenames
        for i=1:numel(input_fns)
            % We create output directory or delete it
            [~,img_name,~] = fileparts(input_fns{i});
            all_other_fns  = setdiff(input_fns, input_fns{i});
            dir_name       = [output_dir filesep img_name];

            if ~isfolder(dir_name)
                mkdir(dir_name);
            end

            % Message
            disp(sprintf('+ %s (%d/%d)', img_name, i, numel(input_fns)));

            % We load fresco image
            im_src_color = load_image(input_fns{i}, grayscale_conversion);

            if size(im_src_color,3)>1
                im_src_gray = rgb2gray(im_src_color);
            else
                im_src_gray = im_src_color;
            end

            img_size = [size(im_src_color,1),size(im_src_color,2)];

            % We save the uncorrupted fresco image
            imwrite(im_src_color, [dir_name filesep sprintf('%s.png', img_name)]);

            % We loop over degradation rates
            for j=1:numel(fresco_degradation_rates)
                degradation_rate = fresco_degradation_rates(j);
                msg(sprintf('  + degradation rate=%.2f%%', degradation_rate*100.0), verbose);

                % We simulate degraded parts onto the fresco image
                im_src_alpha = get_degraded_fresco_parts(im_src_color, degradation_rate);

                % We loop over fragment sizes
                for k=1:numel(fragments_sizes)
                    % Message
                    fragment_size = 2*floor(min(img_size)*fragments_sizes{k}*0.5)+1; % make fragment size as odd integers to cope with the problem of their accurate placement
                    msg(sprintf('    + fragment size=[%d,%d]', fragment_size(1), fragment_size(2)), verbose);

                    % We pad fresco image with zeros if needed
                    nb_frags       = floor(img_size./fragment_size);
                    nb_total_frags = prod(nb_frags);
                    padding_size   = img_size - (fragment_size.*nb_frags);
                    ul_translation = floor(padding_size*0.5);
                    im_frags       = cell(1,nb_total_frags);

                    % We loop over fragments
                    frag_coords       = cell(1,nb_total_frags);
                    frag_translations = cell(1,nb_total_frags);

                    for ii=0:(nb_frags(1)-1)
                        for jj=0:(nb_frags(2)-1)
                            p                       = ([ii,jj].*fragment_size+1)+ul_translation;
                            q                       = p+fragment_size-1;
                            im_frag                 = im_src_color(p(1):q(1), p(2):q(2), :);
                            idx1                    = ii*nb_frags(2)+jj+1;
                            frag_translations(idx1) = {round((q-p)*0.5 + p)};
                            im_frags(idx1)          = {im_frag};
                            frag_coords(idx1)       = {[ii,jj]};
                        end
                    end

                    % We fill arrays constraining the placement and rotation of fragments
                    available_translations = frag_translations;
                    angles_list            = [0.0,90.0,180.0,270.0]; % CAUTION: rotation is counterclockwise
                    available_angles       = cell(1,nb_total_frags);

                    for idx=1:numel(available_angles)
                        if use_rotated_fragments
                            available_angles(idx) = {angles_list};
                        else
                            available_angles(idx) = {[0.0]};
                        end
                    end

                    % We loop over missing fragments rates
                    for l=1:numel(missing_fragments_rates)
                        % Message
                        missing_rate = missing_fragments_rates(l);
                        msg(sprintf('      + missing fragment rate=%.2f%%', 100.0*missing_rate), verbose);

                        % We discard some proportion of fragments, shuffle the remaining ones
                        nb_frags_kept      = round((1-missing_rate)*nb_total_frags);
                        rp                 = randperm(nb_total_frags, nb_frags_kept);
                        im_frags2          = im_frags(rp);
                        frag_translations2 = frag_translations(rp);
                        frag_coords2       = frag_coords(rp);

                        % We loop over spurious fragments rates
                        for m=1:numel(spurious_fragments_rates)
                            % Message
                            spurious_rate = spurious_fragments_rates(m);
                            msg(sprintf('        + spurious fragment rate=%.2f%%', 100*spurious_rate), verbose);

                            % We add some proportion of spurious fragments
                            if spurious_rate>0
                                nb_frags_to_add    = round(spurious_rate*nb_total_frags);
                                extra_idx          = (1:nb_frags_to_add)+numel(im_frags2);
                                im_frags3          = im_frags2;
                                frag_translations3 = frag_translations2;
                                frag_coords3       = frag_coords2;

                                for idx=extra_idx
                                    im_frag                 = randomly_extract_region_from_frescoes(all_other_fns, grayscale_conversion, fragment_size);
                                    im_frags3(idx)          = {im_frag};
                                    frag_translations3(idx) = {[]};
                                    frag_coords3(idx)       = {[]};
                                end

                                % We shuffle fragments again
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
                                true_idx           = 1:numel(im_frags2);
                            end

                            % We look for neighoring relationships
                            frag_neighbors = get_neighbors(frag_coords3, true_idx);

                            % We loop over erosion rates
                            for n=1:numel(erosion_fragments_rates)
                                % Message
                                erosion_rate   = erosion_fragments_rates(n);
                                erosion_radius = round(min(img_size)*erosion_rate);
                                msg(sprintf('          + erosion radius=%d', erosion_radius), verbose);

                                % We set names of files and directories
                                config_dir        = [dir_name filesep sprintf('%s_%d_%.2f_%.2f_%.2f_%d', img_name, fragment_size(1), 100*degradation_rate, missing_rate*100, spurious_rate*100, erosion_radius)];
                                frags_dir         = [config_dir filesep 'frag_eroded'];
                                true_frags_fn     = [config_dir filesep 'fragments.txt'];
                                spurious_frags_fn = [config_dir filesep 'fragments_s.txt'];
                                constraints_fn    = [config_dir filesep 'constraints.txt'];
                                parameters_fn     = [config_dir filesep 'parameters.txt'];
                                neighbors_fn      = [config_dir filesep 'neighbors.txt'];
                                rebuilt_img_fn    = [config_dir filesep 'rebuilt_image.png'];
                                rebuilt_img_n_fn  = [config_dir filesep 'rebuilt_image_n.png'];
                                fresco_img_fn     = [config_dir filesep 'deg_fresco.png'];

                                % We create necessary directories
                                mkdir(config_dir);
                                mkdir(frags_dir);

                                % We save the degraded fresco image
                                imwrite(im_src_color, fresco_img_fn, 'Alpha', im_src_alpha);

                                % We save the parameters used for generating fragment images
                                save_fragments_generation_parameters({'fragment_size', 'degradation_rate', 'missing_rate', 'spurious_rate', 'erosion_radius'}, ...
                                                                     {uint32(fragment_size(1)), double(100*degradation_rate), double(missing_rate*100), double(spurious_rate*100), uint32(erosion_radius)}, ...
                                                                     parameters_fn);

                                % We save the set of rotated and eroded fragment images
                                [im_frags4,frag_angles] = save_fragments_images(im_frags3, erosion_radius, use_rotated_fragments, angles_list, fragment_size, frags_dir);

                                % We save the list of true fragment coordinates
                                save_true_fragments_parameters(frag_translations3, frag_angles, true_idx, true_frags_fn);

                                % We save the list of spurious fragments
                                save_spurious_fragments_idx(spurious_idx, spurious_frags_fn);

                                % We save the file constraining the placement and/or rotation of fragment images
                                save_constraints(available_translations, available_angles, constraints_fn);

                                % We build the ideal fresco reconstruction
                                im_rec_color = reconstruct_fresco(im_src_color, im_frags4(true_idx), frag_translations3(true_idx), frag_angles(true_idx), background_color, []);

                                % We save the ideal fresco reconstructions
                                save_reconstructed_fresco(im_rec_color, im_src_alpha, rebuilt_img_fn, [], []); % reconstructed fresco without neighboring relationships
                                save_reconstructed_fresco(im_rec_color, im_src_alpha, rebuilt_img_n_fn, frag_neighbors, frag_translations3); % reconstructed fresco with neighboring relationships (debugging)

                                % We save the neighboring relationships between fragments
                                save_fragment_neighbors(frag_neighbors, neighbors_fn);
                            end
                        end
                    end
                end
            end
        end
    end
end