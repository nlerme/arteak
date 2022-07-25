% This function modifies an existing dataset with fragments of irregular shape
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
        seed                     = 1;                                                      % Seed used for pseudo random number generator (0=random, >0=fixed seed for reproductibility)
        verbose                  = false;                                                  % Enables/disables display of messages on command window
        fresco_degradation_rates = 0.0:0.1:1.0;                                            % Percentages of degradation of the fresco image (in [0,1])
        root_frescoes_dir        = ['..' filesep '..' filesep 'data' filesep 'irregular']; % Input/output frescoes directory (string)
        background_color         = [0,0,0];                                                % RGB color of reconstructed fresco (in [0,1]^3)
        interpolation_type       = 'bilinear';                                             % Interpolation type for reconstructing frescoes from fragments
        idx_color                = 'white';                                                % Color of fragment index in reconstructed fresco (string or [0,1]^3)
        neighbors_color          = 'cyan';                                                 % Color of neighboring relationships between fragments in reconstructed fresco (string or [0,1]^3)

        % We set the seed for pseudo random number generation. simdTwister algorithm is used for 
        % reproductibility (same sequence of random numbers will be obtained on different machines)
        rng(seed, 'simdTwister');

        % We loop over fresco directories
        frescoes_dirs = get_matching_dirs(root_frescoes_dir, '.*');

        if isempty(frescoes_dirs)
            error(sprintf('Directory %s is empty', root_frescoes_dir));
        end

        parfor i=1:numel(frescoes_dirs)
        %for i=2
            % We extract name of current fresco directory
            fresco_dir = split(frescoes_dirs{i}, filesep);
            fresco_dir = fresco_dir{end};

            % Message
            disp(sprintf('+ %s (%d/%d)', fresco_dir, i, numel(frescoes_dirs)));

            % We look for non degraded fresco image
            fresco_fn = get_matching_files(frescoes_dirs{i}, [fresco_dir '.png']);

            if numel(fresco_fn)==0
                error(sprintf('Unable to find fresco image in directory %s', frescoes_dirs{i}));
                continue;
            end

            fresco_fn = fresco_fn{1};

            % We load fresco image
            [im_fresco_color,~] = load_image(fresco_fn, false);
            fresco_size         = [size(im_fresco_color,1),size(im_fresco_color,2)];

            % We loop over degradation rates
            for j=1:numel(fresco_degradation_rates)
                degradation_rate = fresco_degradation_rates(j);

                % We simulate degraded parts onto the fresco image
                im_fresco_alpha = get_degraded_fresco_parts(im_fresco_color, degradation_rate);

                % We save the degraded fresco image
                imwrite(im_fresco_color, [frescoes_dirs{i} filesep sprintf('%s_degraded_%d.png', fresco_dir, round(100*degradation_rate))], 'Alpha', im_fresco_alpha);
            end

            % We loop over config directories for current fresco
            config_dirs = get_matching_dirs(frescoes_dirs{i}, '.*');

            if numel(config_dirs)==0
                warning(sprintf('No config directories found in the fresco directory %s', frescoes_dirs{i}));
                continue;
            end

            for j=1:numel(config_dirs)
                % We extract name of current config directory
                config_dir = split(config_dirs{j}, filesep);
                config_dir = config_dir{end};

                % Message
                msg(sprintf('  + %s (%d/%d)', config_dir, j, numel(config_dirs)), verbose);

                % We set necessary filenames
                frags_dir         = [config_dirs{j} filesep 'frag_eroded'];
                true_frags_fn     = [config_dirs{j} filesep 'fragments.txt'];
                constraints_fn    = [frags_dir filesep 'geometric_constraints.txt'];
                parameters_fn     = [frags_dir filesep 'gen_parameters.txt'];
                neighbors_fn      = [config_dirs{j} filesep 'neighbors.txt'];
                rebuilt_img_n_fn  = [config_dirs{j} filesep 'rebuilt_image_n.png'];

                % We loop over all fragment image filenames
                frags_fns = get_matching_files(frags_dir, ['.*\.png']);

                if numel(frags_fns)==0
                    warning(sprintf('No fragment images found in config directory %s', config_dirs{j}));
                    continue;
                end

                frags_infos = cell(1, numel(frags_fns));

                for k=1:numel(frags_fns)
                    % We load fragment image
                    [im_frag_color,im_frag_alpha] = load_image(frags_fns{k}, false);

                    % We add it to the list
                    frags_infos{k} = struct('color', im_frag_color, 'alpha', im_frag_alpha);
                end

                % We load the ideal reconstructed fresco
                [ids,tx,ty,angles] = textread(true_frags_fn, '%d %f %f %f');

                if numel(ids)~=numel(tx) || numel(tx)~=numel(ty) || numel(ty)~=numel(angles)
                    warning(sprintf('Ground truth text file %s is badly formatted', true_frags_fn));
                    continue;
                end

                % We construct the structure describing a fresco to reconstruct
                frags_sol = {};

                for k=1:numel(ids)
                    idx = ids(k)+1;

                    if idx>numel(frags_infos)
                        continue;
                    end

                    frags_sol = {frags_sol{:},struct('idx', idx, 'translation', [ty(k),tx(k)], 'angle', -angles(k), 'neighbors', [], ...
                                                     'fresco_coords', [], 'frag_coords', [], 'color_idx', [])};
                end

                % Given fragment images and their transformation parameters, we reconstruct the fresco
                [im_rec_gray,~,im_rec_color] = get_reconstructed_fresco(im_fresco_color, frags_infos, frags_sol, interpolation_type, background_color);

                % Given reconstructed fresco, we both estimate neighboring relationships between nearby fragments as well as their distance
                [ifd,frags_sol] = get_nearby_fragments_estimates(im_rec_gray, frags_sol);

                % We save the parameters used for generating fragment images
                save_gen_parameters({'nearby_frags_gap'}, {double(ifd)}, parameters_fn);

                % We save the file constraining the placement of fragment images
                save_geometric_constraints(struct('locations', [], 'orientations', []), constraints_fn);

                % We save the neighboring relationships between fragments
                save_fragment_neighbors(frags_sol, neighbors_fn);

                % We save the ideal fresco reconstructions
                save_reconstructed_fresco(im_rec_color, frags_sol, idx_color, neighbors_color, rebuilt_img_n_fn); % reconstructed fresco with neighboring relationships
            end
        end
    end
end
