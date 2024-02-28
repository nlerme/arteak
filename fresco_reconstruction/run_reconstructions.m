% Function performing automatic reconstruction of digitized frescoes.
function run_reconstructions()
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

        % -----------------------------------------------------------------
        seed             = 1; % Seed used for pseudo random number generator (<0=random, >0=fixed seed for reproductibility)
        results_root_dir = ['..' filesep '..' filesep 'results' filesep 'tests'];
        data_root_dir    = ['..' filesep '..' filesep 'data' filesep 'simulated' filesep 'regular'];
        degradation_rate = 0; % degradation level of the fresco image (in {0,...,100})
        %------------------------------------------------------------------

        % We add required paths recursively
        addpath_recurse(['..' filesep 'common_tools']);
        addpath_recurse('multi-labels_gc');
        addpath_recurse(['tests' filesep 'QPBO']);

        % We create a parallel pool if needed
        if isempty(gcp('nocreate'))
            parpool('IdleTimeout', 60*24*7);
        end

        % We set the seed for pseudo random number generation. simdTwister 
        % algorithm is used for reproductibility (same sequence of random 
        % numbers will be obtained on different machines)
        if seed<0
            rng('shuffle', 'simdTwister');
        else
            rng(seed, 'simdTwister');
        end

        %------------------------------------------------------------------

        %fresco_name = 'Lanzani_SantAntonioproteggePavia_2440x2524';
        %config_name = [fresco_name '_2019-2-20_17.26.13'];

        %fresco_name = 'Leonardo-da-Vinci_Ultima-Cena_5193x2926';
        %config_name = [fresco_name '_2019-2-28_13.56.32'];

        %fresco_name = 'Michelangelo_ThecreationofAdam_1707x775';
        %config_name = [fresco_name '_77_0_0_0'];
        %config_name = [fresco_name '_2019-2-15_18.45.27'];
        %config_name = [fresco_name '_2019-2-15_18.46.1'];
        %config_name = [fresco_name '_2019-2-20_17.29.23'];

        %fresco_name = 'Giotto_EntryIntoJerusalem_1000x941';
        %config_name = [fresco_name '_95_0_0_3'];
        %config_name = [fresco_name '_189_0_0_3'];
        %config_name = [fresco_name '_2019-2-19_15.31.27'];
        %config_name = [fresco_name '_2019-2-19_15.31.30'];
        %config_name = [fresco_name '_2019-2-19_15.31.33'];

        %fresco_name = 'Vasari_PaulIIIFarnese_1006x759';
        %config_name = [fresco_name '_75_0_0_2'];
        %config_name = [fresco_name '_189_0_0_2'];

        %fresco_name = 'Signorelli_Dannati_1010x700';
        %config_name = [fresco_name '_71_0_0_2'];
        %config_name = [fresco_name '_175_0_0_2'];

        fresco_name = 'PierodellaFrancesca_Resurrezione_730x826';
        %config_name = [fresco_name '_73_0_0_0'];
        config_name = [fresco_name '_183_0_0_0'];
        %config_name = [fresco_name '_2019-2-28_13.55.54'];
        %config_name = [fresco_name '_2019-2-28_13.56.15'];
        %config_name = [fresco_name '_2019-2-28_13.56.3'];

        %fresco_name = 'Perugino_Consegnadellechiavi_2347x1438';
        %config_name = [fresco_name '_2019-2-20_17.52.19'];

        %fresco_name = 'Piero-della-Francesca_ExaltationoftheCross_1239x900';
        %config_name = [fresco_name '_2019-2-15_18.48.27'];

        %fresco_name = 'Tiepolo_TheInstitutionoftheRosary_850x1231';
        %config_name = [fresco_name '_85_0_0_0'];
        %config_name = [fresco_name '_2019-2-15_17.29.20'];

        run_reconstruction(data_root_dir, fresco_name, config_name, results_root_dir, degradation_rate);

        %--------------

%         dirs1 = get_matching_dirs(data_root_dir, '.*');
%         for i=1:numel(dirs1)
%             a = split(dirs1{i}, filesep);
%             fresco_name = a{end};
%             disp(sprintf('+ %s (%d/%d)', fresco_name, i, numel(dirs1)));
%             dirs2 = get_matching_dirs(dirs1{i}, '.*');
%             for j=1:numel(dirs2)
%                 a = split(dirs2{j}, filesep);
%                 config_name = a{end};
%                 disp(sprintf('  + %s (%d/%d)', config_name, j, numel(dirs2)));
%                 run_reconstruction(data_root_dir, fresco_name, config_name, results_root_dir, degradation_rate);
%             end
%         end
        %------------------------------------------------------------------
    end

    function run_reconstruction( data_root_dir, fresco_name, config_name, results_root_dir, degradation_rate )
        % We set directory and file names
        fresco_dir    = [data_root_dir filesep fresco_name];
        config_dir    = [fresco_dir filesep config_name];
        frags_dir     = [config_dir filesep 'frag_eroded'];
        geo_csts_fn   = [frags_dir filesep 'geometric_constraints.txt'];
        gen_params_fn = [frags_dir filesep 'gen_parameters.txt'];
        results_dir   = [results_root_dir filesep fresco_name filesep config_name '_' num2str(degradation_rate)];

        %------------------------------------------------------------------

        % General parameters
        verbose                   = true;       % Enables/disables verbose mode (true or false)
        show_figures              = false;      % Enables/disables display of figures (true or false)
        recompute_preprocessing   = true;      % Boolean indicating if preprocessing step is recomputed or loaded (true or false)
        save_intermediate_results = true;       % Enables/disables saving of intermediate results (true or false)
        save_ground_truth_results = true;       % Enables/disables saving of ground truth results (true or false)
        interpolation_type        = 'bilinear'; % Type of interpolation used for geometrical transform of fragments (non empty string)
        translation_tolerance     = 10.0;       % Tolerance in translation in pixels (>=0)
        angle_tolerance           = 5.0;        % Tolerance in rotation in degrees (in [0,360])
        background_color          = [0,0,0];    % Background color of reconstructed fresco (in {0,...,255}^3)

        general_parameters = {struct('name', 'verbose', 'value', verbose), ...
                              struct('name', 'show_figures', 'value', show_figures), ...
                              struct('name', 'recompute_preprocessing', 'value', recompute_preprocessing), ...
                              struct('name', 'results_dir', 'value', results_dir), ...
                              struct('name', 'gt_dir', 'value', config_dir), ...
                              struct('name', 'save_ground_truth_results', 'value', save_ground_truth_results), ...
                              struct('name', 'interpolation_type', 'value', interpolation_type), ...
                              struct('name', 'save_intermediate_results', 'value', save_intermediate_results), ...
                              struct('name', 'translation_tolerance', 'value', translation_tolerance), ...
                              struct('name', 'angle_tolerance', 'value', angle_tolerance), ...
                              struct('name', 'background_color', 'value', background_color)};

        % Initialization parameters
        recompute_init                     = true;    % Boolean indicating if initialization step is recomputed or loaded (true or false)
        outside_fragment_tolerance         = 0.1;     % Tolerance threshold deciding if a fragment is outside fresco model or not (in [0,1])
        fragments_overlap_tolerance        = 0.1;     % Tolerance threshold deciding if two fragments overlap or not (in [0,1])
        features_detection_threshold1      = 0.01;    % First threshold for detecting features both in fresco and fragments (>=0)
        features_detection_threshold2      = 0.03;    % Second threshold for detecting features both in fresco and fragments (>=0)
        features_extraction_method         = 'BRISK'; % Method for extracting features (can be either SURF, KAZE, FRISK, or ORB)
        features_matching_threshold        = 50.0;    % Thrreshold for features matching (in ]0,100])
        features_matching_max_ratio        = 0.6;     % Maximum ratio for features matching (in ]0,1])
        features_matching_fresco_padding   = 18;      % Padding of fresco before computing features (>=0)
        features_matching_dilation_rate    = 0.5;     % Coefficient for dilating confidence maps (in [0,1])
        color_matching_nb_bins_per_channel = 16;      % Number of bins per channel in color histograms (in [1,256])
        color_matching_nb_rectangles       = 3;       % Number of rectangles for approximating circle (>0)
        color_matching_dilation_radius     = 3;       % Dilation radius of matched regions (>=0)
        color_matching_threshold           = 0.8;     % Threshold for extracting matched regions (in [0,1])
        max_cover_rate                     = 1.0;     % Maximum cover rate of fragments during sampling step (in [0,1])

        init_parameters = {struct('name', 'recompute_init', 'value', recompute_init), ...
                           struct('name', 'outside_fragment_tolerance', 'value', outside_fragment_tolerance), ...
                           struct('name', 'fragments_overlap_tolerance', 'value', fragments_overlap_tolerance), ...
                           struct('name', 'features_detection_threshold1', 'value', features_detection_threshold1), ...
                           struct('name', 'features_detection_threshold2', 'value', features_detection_threshold2), ...
                           struct('name', 'features_extraction_method', 'value', features_extraction_method), ...
                           struct('name', 'features_matching_threshold', 'value', features_matching_threshold), ...
                           struct('name', 'features_matching_max_ratio', 'value', features_matching_max_ratio), ...
                           struct('name', 'features_matching_fresco_padding', 'value', features_matching_fresco_padding), ...
                           struct('name', 'features_matching_dilation_rate', 'value', features_matching_dilation_rate), ...
                           struct('name', 'color_matching_nb_bins_per_channel', 'value', color_matching_nb_bins_per_channel), ...
                           struct('name', 'color_matching_nb_rectangles', 'value', color_matching_nb_rectangles), ...
                           struct('name', 'color_matching_dilation_radius', 'value', color_matching_dilation_radius), ...
                           struct('name', 'color_matching_threshold', 'value', color_matching_threshold), ...
                           struct('name', 'max_cover_rate', 'value', max_cover_rate)};

        % MPP parameters
        recompute_mpp               = true;  % Boolean indicating if MPP step is recomputed or loaded (true or false)
        outside_fragment_tolerance  = 5;     % Tolerance parameter controlling if a fragment is outside fresco model or not (in pixels, >=0)
        fragments_overlap_tolerance = 5;     % Tolerance parameter controlling if two fragments overlap or not (in pixels, >=0)
        beta_d                      = 1.0;   % Weighting parameter for the term E_d (>=0.0)
        beta_a                      = 0.01;   % Weighting parameter for the term E_a (>=0.0)
        beta_inc                    = 1000000.0; % Weighting parameter for the term E_{inc} (>=0.0)
        beta_c                      = 1000000.0; % Weighting parameter for the term E_c (>=0.0)
        beta_no                     = 1000000.0; % Weighting parameter for the term E_{no} (>=0.0)
        beta_sf                     = 0.5;  % Weighting parameter for the term E_{sf} (>=0.0)
        lambda                      = 20.0;  % Slope parameter of psi function (>0)
        mu                          = -0.995; % Shift parameter of psi function (in [-1,1])
        nb_iterations               = 1;  % Number of iterations of MPP algorithm (>=1)

        mpp_parameters = {struct('name', 'recompute_mpp', 'value', recompute_mpp), ...
                          struct('name', 'outside_fragment_tolerance', 'value', outside_fragment_tolerance), ...
                          struct('name', 'fragments_overlap_tolerance', 'value', fragments_overlap_tolerance), ...
                          struct('name', 'beta_d', 'value', beta_d), ...
                          struct('name', 'beta_a', 'value', beta_a), ...
                          struct('name', 'beta_inc', 'value', beta_inc), ...
                          struct('name', 'beta_c', 'value', beta_c), ...
                          struct('name', 'beta_no', 'value', beta_no), ...
                          struct('name', 'beta_sf', 'value', beta_sf), ...
                          struct('name', 'lambda', 'value', lambda), ...
                          struct('name', 'mu', 'value', mu), ...
                          struct('name', 'nb_iterations', 'value', nb_iterations)};

        %------------------------------------------------------------------

        % We load the fresco image
        msg(sprintf('+ loading of fresco image (degradation rate=%d%%)', degradation_rate), verbose);
        fresco_fn = [fresco_dir filesep fresco_name '_degraded_' num2str(round(degradation_rate)) '.png'];

        [im_fresco_color,im_fresco_alpha] = load_image(fresco_fn, false);

        if isempty(im_fresco_color) || isempty(im_fresco_alpha)
            error('Unable to load fresco image. Wrong path, missing alpha channel or unavailable degradation rate?');
        end

        % We threshold the alpha channel of fresco to limit memory usage
        im_fresco_alpha = (im_fresco_alpha>0);

        % We load the geometric constraints file
        msg('+ loading of geometric constraints', verbose);
        geometric_constraints = load_geometric_constraints(geo_csts_fn);

        if isempty(geometric_constraints)
            error('Unable to load geometric constraints. Wrong path?');
        end

        msg(sprintf('  + %d locations', numel(geometric_constraints.locations)), verbose);
        msg(sprintf('  + %d orientations', numel(geometric_constraints.orientations)), verbose);

        % We load the gen parameters file
        msg('+ loading of gen parameters', verbose);

        gen_parameters = load_gen_parameters(gen_params_fn);

        if isempty(gen_parameters)
            error('Unable to load gen parameters. Wrong path?');
        end

        fn = fieldnames(gen_parameters);

        for k=1:numel(fn)
            msg(sprintf('  + %s -> %s', fn{k}, num2str(getfield(gen_parameters, fn{k}))), verbose);
        end

        % We loop over fragment image filenames
        msg('+ loading of fragments', verbose);
        frag_fns = get_matching_files(frags_dir, '.*\.png');
        %frag_fns{numel(frag_fns)+1} = 'my_eroded_fragment.png'; % DEBUG, A RETIRER ABSOLUMENT A TERME !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        if isempty(frag_fns)
            error('Unable to find fragment images. Wrong path or unknown file format?');
        end

        frags_infos = cell(1,numel(frag_fns));

        parfor k=1:numel(frag_fns)
            msg(sprintf('  + fragment %d/%d', k, numel(frag_fns)), verbose);

            % We load fragment image
            [im_frag_color,im_frag_alpha] = load_image(frag_fns{k}, false);

            if isempty(im_frag_color) || isempty(im_frag_alpha)
                error('Unable to load fragment image %s. Wrong path or missing alpha channel?', frag_fns{k});
            end

            % We check if the number of channels is the same in fresco and fragment images
            if size(im_fresco_color,3) ~= size(im_frag_color,3)
                error('The number of channels of any fragment image must be the same as the one for the fresco image');
            end

            % We correct image intensities near fragment boundary based on alpha channel
            im_frag_color = correct_fragment_image_intensities(im_frag_color, im_frag_alpha);

            % We threshold alpha channel to limit memory usage
            im_frag_alpha = (im_frag_alpha>0);

            % We add fragment images to the list
            frags_infos{k} = struct('color', im_frag_color, 'alpha', im_frag_alpha);
        end

        % We reconstruct the fresco
        run_reconstruction_from_loaded_data(im_fresco_color, im_fresco_alpha, frags_infos, general_parameters, init_parameters, mpp_parameters, gen_parameters, geometric_constraints);
    end
end
