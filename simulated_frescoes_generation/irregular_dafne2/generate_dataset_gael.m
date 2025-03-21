% This function generates a new dataset from existing fresco images with fragments of irregular shape.
function generate_dataset_gael()
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

        % Parameters to tune
        seed               = 1;                                                                                                  % Seed used for pseudo random number generator (<0:random, >=0:fixed seed for reproductibility)
        verbose            = true;                                                                                               % Enables/disables display of messages on command window (true or false)
        image_size         = [512,512];                                                                                          % Size of resulting fragmentations (2D vector of positive integers)
        mis                = min(image_size);                                                                                    % Temporary variable declared for convenience
        nb_fragments       = 3:15;                                                                                               % Number of fragments (vector of non-negative integers)
        min_dists          = 0.05*mis*ones(size(nb_fragments));                                                                  % Minimum distances between sampled location of fragments (vector of positive reals; in pixels)
        nb_fragmentations  = 10000*ones(size(nb_fragments));                                                                     % Number of fragmentations to generate per number of fragments (vector of positive integers)
        erosion_levels     = struct('min', [0.0,0.005]*mis, 'max', [0.0,0.01]*mis);                                              % Lower and upper bounds on erosion levels (struct with lower and upper bounds arrays)
        parameters         = struct('sampling_min_dist', [], 'sampling_nb_points', [], 'sampling_type', 'non-uniform-lloyd', ...
                                    'noise_exponent', 1.7, 'uncertainty_band_size', 0.02*mis, 'beta', 0.5, ...
                                    'dist_name', 'euclidean', 'dist_weights', [0.5,1.0]);                                          % Parameters for simulating fragmentations (struct)
        %output_dir         = ['..' filesep '..' filesep '..' filesep 'data' filesep 'simulated' filesep 'gael'];                % Output fragmentations directory (string)
        output_dir         = ['results'];                                                                                        % Output fragmentations directory (string)
        purge_dataset      = true;                                                                                               % Enables/disables destruction of previous version of dataset (true or false)

        % We check array length consistency arrays are of the same size
        if numel(min_dists)~=numel(nb_fragments) || numel(min_dists)~=numel(nb_fragmentations)
            error('The size of array min_dists, nb_fragments and nb_fragmentations parameters arrays must be the same');
        end

        % We check if erosion levels are consistent
        if numel(erosion_levels.min)~=numel(erosion_levels.max)
            error('The number of lower and upper bounds of erosion levels must be the same');
        end

        for i=1:numel(erosion_levels.min)
            if any(min_dists<=erosion_levels.min(i)) || any(min_dists<=erosion_levels.max(i))
                error('Minimum and maximum erosion levels must be both smaller than minimum distances');
            end

            if erosion_levels.min(i)>erosion_levels.max(i)
                error('Minimum erosion levels must be smaller than maximum ones');
            end
        end

        % We check if the desired minimum distance between sampling points is smaller than the maximum allowed one
        for i=1:numel(nb_fragments)
            max_nb_fragments = floor(prod(image_size./min_dists(i)));

            if nb_fragments(i)>=max_nb_fragments
                error('The desired number of fragments (%d) exceeds the maximum allowed one (%d). Please decrease the former or the minimum distance', nb_fragments(i), max_nb_fragments);
            end
        end

        % We set the seed for pseudo random number generation. simdTwister algorithm is used for 
        % reproducibility (same sequence of random numbers will be obtained on different machines)
        if seed<0
            rng('shuffle', 'simdTwister');
        else
            rng(seed, 'simdTwister');
        end

        % We create output directory if needed
        if ~isfolder(output_dir)
            mkdir(output_dir);
        else
            if purge_dataset
                rmdir(output_dir, 's');
                mkdir(output_dir);
                msg('[ old dataset removed ]', verbose);
            end
        end

        % We loop over number of fragments
        for i=1:numel(nb_fragments)
            % Message
            msg(sprintf('+ number of fragments=%d / min dist=%f', nb_fragments(i), min_dists(i)), verbose);

            % We assign fragmentation parameters
            parameters.sampling_nb_points = nb_fragments(i);
            parameters.sampling_min_dist  = min_dists(i);

            % We loop over number of fragmentations
            for j=1:nb_fragmentations(i)
                % Message
                msg(sprintf('  + fragmentation %d', j), verbose);

                % We simulate fragmentation and compute distance from resulting boundaries
                [im_fragmentation,~] = simulate_fresco_fragmentation(image_size, parameters);
                [im_dmap,max_dists]  = get_distance_to_contours(im_fragmentation, 'euclidean', true);
                min_dist             = min(max_dists);

                % We loop over erosion levels
                for k=1:numel(erosion_levels.min)
                    % Message
                    msg(sprintf('    + erosion level (min=%f,max=%f)', erosion_levels.min(k), erosion_levels.max(k)), verbose);

                    % We eventually erode resulting fragments
                    if erosion_levels.min(k)>0 && erosion_levels.max(k)>0
                        % We erode all fragments
                        if erosion_levels.min(k)==erosion_levels.max(k)
                            threshold                           = min(erosion_levels.min(k),0.75*min_dist);
                            im_fragmentation(im_dmap<threshold) = 0;
                        else
                            [min_label,max_label] = bounds(im_fragmentation(:));
                
                            for l=min_label:max_label
                                threshold                = min(rand_bounds(erosion_levels.min(k),erosion_levels.max(k)), 0.75*min_dist);
                                im_tmp                   = (im_dmap<threshold) & (im_fragmentation==l);
                                im_fragmentation(im_tmp) = 0;
                            end
                        end
                    end
                
                    % Since erosion can cause an increase of the number of connected components, we keep the k largest ones
                    im_tmp                      = bwpropfilt(im_fragmentation>0, 'Area', nb_fragments(i), 'largest');
                    im_fragmentation(im_tmp==0) = 0;

                    %--- debug ---
                    figure, imshow(im_fragmentation,[]);
                    %-------------

                    % We create output directory if needed
                    fragmentations_dir = [output_dir filesep sprintf('nb_fragments=%d_erosion=%d_%d', nb_fragments(i), erosion_levels.min(k), erosion_levels.max(k))];

                    if ~isfolder(fragmentations_dir)
                        mkdir(fragmentations_dir);
                    end

                    % We save the fragmentation image in the output directory
                    fragmentation_fn = [fragmentations_dir filesep sprintf('fragmentation_%dx%d_%d_%d_%d.tif', image_size(1), image_size(2), nb_fragments(i), round(min_dists(i)), j)];
                    imwrite(uint16(im_fragmentation), fragmentation_fn, 'Compression', 'deflate');

                    %--- debug ---
                    if (max(im_fragmentation(:))-max(1,min(im_fragmentation(:))))~=(nb_fragments(i)-1)
                        error('!!! CONSISTENCY PROBLEM ON RESULTING LABELING !!!');
                    end
                    %-------------
                end
            end
        end
    end
end
