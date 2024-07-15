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
        seed               = 1;                                                                                                     % Seed used for pseudo random number generator (<0:random, >=0:fixed seed for reproductibility)
        verbose            = true;                                                                                                  % Enables/disables display of messages on command window (true or false)
        fragmentation_size = [512,512];                                                                                             % Size of resulting fragmentations (2D vector of positive integers)
        min_dists          = [5,5];                                                                                                 % Minimum distances between sampled location of fragments (vector of positive reals)
        nb_fragments       = [4,15,25];                                                                                             % Number of fragments (vector of non-negative integers; can be null)
        nb_fragmentations  = [200000,200000,200000];                                                                                % Number of fragmentations to generate per number of fragments (vector of positive integers)
        parameters         = struct('sampling_min_dist', [], 'sampling_nb_points', [], 'sampling_type', 'non-uniform-lloyd', ...
                                    'noise_exponent', 1.5, 'uncertainty_band_size', 0.2, ...
                                    'beta', 0.7, 'metric', 'euclidean');                                                            % Parameters for simulating fragmentations (struct)
        output_dir         = ['..' filesep '..' filesep '..' filesep 'data' filesep 'simulated' filesep 'gael'];                    % Output frescoes directory (string)
        purge_dataset      = true;                                                                                                  % Enables/disables destruction of previous version of dataset (true or false)

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
                disp('[ old dataset removed ]');
            else
                error(sprintf('The output directory %s is not empty. Please remove it or set flag purge_dataset to true.', output_dir));
            end
        end

        % We loop over number of fragments
        for i=1:numel(nb_fragments)
            % Message
            msg(sprintf('+ number of fragments=%d / min dist=%f', nb_fragments(i), min_dists(i)), verbose);

            % We assign fragmentation parameters
            parameters.sampling_nb_points = nb_fragments(i);
            parameters.sampling_min_dist  = min_dists(i);

            % We create output directory or delete it
            fragmentations_dir = [output_dir filesep sprintf('%d_fragments', nb_fragments(i))];

            if ~isfolder(fragmentations_dir)
                mkdir(fragmentations_dir);
            end

            % We loop over trials
            parfor j=1:nb_fragmentations(i)
                % Message
                %msg(sprintf('  + fragmentation %d', j), verbose);

                % We simulate fragmentation
                [im_fragmentation,~] = simulate_fresco_fragmentation(fragmentation_size, parameters);

                % We save the fragmentation in the output directory
                fragmentation_fn = [fragmentations_dir filesep sprintf('%d_%d_%d_%d.tif', fragmentation_size(1), nb_fragments(i), min_dists(i), j)];
                imwrite(uint8(im_fragmentation), fragmentation_fn);

                %--- debug ---
                %figure, imshow(im_fragmentation,[]);
                %figure, imshow(im_noise,[]);
                %-------------
            end
        end
    end
end