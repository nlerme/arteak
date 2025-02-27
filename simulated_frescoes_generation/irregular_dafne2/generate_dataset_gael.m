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
        image_size         = [512,512];                                                                                             % Size of resulting fragmentations (2D vector of positive integers)
        nb_fragments       = 3:15;                                                                                                  % Number of fragments (vector of non-negative integers)
        min_dists          = 25*ones(size(nb_fragments));                                                                           % Minimum distances between sampled location of fragments (vector of positive reals; in pixels)
        nb_fragmentations  = 1*ones(size(nb_fragments));                                                                            % Number of fragmentations to generate per number of fragments (vector of positive integers)
        erosion_levels     = [0,3];                                                                                                 % Erosion levels (vector of non-negative integers; in pixels)
        parameters         = struct('sampling_min_dist', [], 'sampling_nb_points', [], 'sampling_type', 'non-uniform-lloyd', ...
                                    'noise_exponent', 1.5, 'uncertainty_band_size', 10, ...
                                    'beta', 0.5, 'metric', 'euclidean');                                                            % Parameters for simulating fragmentations (struct)
        output_dir         = ['..' filesep '..' filesep '..' filesep 'data' filesep 'simulated' filesep 'gael'];                    % Output fragmentations directory (string)
        %output_dir         = ['/media/nas_utils_nl2/nicolas66/donnees'];                                                           % Output fragmentations directory (string)
        purge_dataset      = true;                                                                                                  % Enables/disables destruction of previous version of dataset (true or false)

        % We check array length consistency arrays are of the same size
        if numel(min_dists)~=numel(nb_fragments) || numel(min_dists)~=numel(nb_fragmentations)
            error('The size of array min_dists, nb_fragments and nb_fragmentations parameters arrays must be the same');
        end

        % We check if erosion levels are all smaller than minimum distances
        for i=1:numel(erosion_levels)
            if any(min_dists<=erosion_levels(i))
                error('Erosion levels must be all smaller than minimum distances');
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
                disp('[ old dataset removed ]');
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

                % We simulate fragmentation and convert it to uint16
                [im_fragmentation,~,im_voronoi] = simulate_fresco_fragmentation(image_size, parameters, false);
                im_fragmentation                = uint16(im_fragmentation);
                im_voronoi                      = uint16(im_voronoi);

                % We loop over erosion levels
                parfor k=1:numel(erosion_levels)
                    % Message
                    msg(sprintf('    + erosion level=%d', erosion_levels(k)), verbose);

                    % We erode all pieces of the fragmentation (if needed)
                    if erosion_levels(k)==0
                        im_fragmentation_e = im_fragmentation;
                    else
                        [im_dmap,max_dists]      = get_distance_to_contours(im_fragmentation, parameters.metric);
                        min_dist                 = min(max_dists);
                        threshold                = min(erosion_levels(k),0.75*min_dist);
                        im_fragmentation_e       = im_fragmentation;
                        im_fragmentation_e(im_dmap<=threshold) = 0;
                    end

                    % We create output directory if needed
                    fragmentations_dir = [output_dir filesep sprintf('nb_fragments=%d_erosion=%d', nb_fragments(i), erosion_levels(k))];

                    if ~isfolder(fragmentations_dir)
                        mkdir(fragmentations_dir);
                    end

                    % We save the fragmentation and the Voronoi images in the output directory
                    fragmentation_fn = [fragmentations_dir filesep sprintf('fragmentation_%dx%d_%d_%d_%d.tif', image_size(1), image_size(2), nb_fragments(i), min_dists(i), j)];
                    voronoi_fn       = [fragmentations_dir filesep sprintf('voronoi_%dx%d_%d_%d_%d.tif', image_size(1), image_size(2), nb_fragments(i), min_dists(i), j)];
                    imwrite(im_fragmentation_e, fragmentation_fn, 'Compression', 'deflate');
                    imwrite(im_voronoi, voronoi_fn, 'Compression', 'deflate');

                    %--- debug ---
                    if (max(im_fragmentation_e(:))-max(1,min(im_fragmentation_e(:))))~=(nb_fragments(i)-1)
                        disp('PROBLEM !!!!!!!!!!!!!!!!!!!!!');
                    end
                    %figure, imshow(imread(fragmentation_fn),[]);
                    %figure, imshow(im_noise,[]);
                    %-------------
                end
            end
        end
    end
end
