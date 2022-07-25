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

        % We add required paths recursively
        addpath_recurse(['..' filesep 'common_tools']);
        addpath_recurse('multi-labels_gc');

        % We create a parallel pool if needed
        if isempty(gcp('nocreate'))
            parpool();
        end

        %------------------------------------------------------------------
        results_root_dir = ['..' filesep '..' filesep 'results' filesep 'tests'];
        data_root_dir    = ['..' filesep '..' filesep 'data' filesep 'regular'];
        degradation_rate = 100; % degradation level of the fresco image (in {0,...,100})
        %--------------

        %fresco_name = 'Lanzani_SantAntonioproteggePavia_2440x2524';
        %config_name = [fresco_name '_2019-2-20_17.26.13'];

        %fresco_name = 'Leonardo-da-Vinci_Ultima-Cena_5193x2926';
        %config_name = [fresco_name '_2019-2-28_13.56.32'];

        %fresco_name = 'Michelangelo_ThecreationofAdam_1707x775';
        %config_name = [fresco_name '_2019-2-15_18.45.27'];
        %config_name = [fresco_name '_2019-2-15_18.46.1'];
        %config_name = [fresco_name '_2019-2-20_17.29.23'];

        %fresco_name = 'Giotto_EntryIntoJerusalem_1000x941';
        %config_name = [fresco_name '_2019-2-19_15.31.27'];
        %config_name = [fresco_name '_2019-2-19_15.31.30'];
        %config_name = [fresco_name '_2019-2-19_15.31.33'];

        fresco_name = 'PierodellaFrancesca_Resurrezione_730x826';
        config_name = [fresco_name '_73_0_0_2'];
        %config_name = [fresco_name '_2019-2-28_13.55.54'];

        %config_name = [fresco_name '_2019-2-28_13.56.15'];
        %config_name = [fresco_name '_2019-2-28_13.56.3'];

        %fresco_name = 'Perugino_Consegnadellechiavi_2347x1438';
        %config_name = [fresco_name '_2019-2-20_17.52.19'];

        %fresco_name = 'Piero-della-Francesca_ExaltationoftheCross_1239x900';
        %config_name = [fresco_name '_2019-2-15_18.48.27'];

        %fresco_name = 'Tiepolo_TheInstitutionoftheRosary_850x1231';
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
%                 run_reconstruction(data_root_dir, fresco_name, config_name, results_root_dir);
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
        results_dir   = [results_root_dir filesep fresco_name filesep config_name];

        %------------------------------------------------------------------

        % General parameters
        verbose                   = true;       % Enables/disables verbose mode
        show_figures              = false;      % Enables/disables display of figures
        recompute_preprocessing   = false;       % Boolean indicating if preprocessing step is recomputed or loaded (true or false)
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
        outside_fragment_tolerance         = 0.1;     % Allowed normalized area of a fragment being outside fresco (in [0,1])
        fragments_overlap_tolerance        = 0.1;     % Allowed normalized area between two overlapping fragments (in [0,1])
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
                           struct('name', 'color_matching_threshold', 'value', color_matching_threshold)};

        % MPP parameters
        recompute_mpp = true; % Boolean indicating if MPP step is recomputed or loaded (true or false)
        beta_d        = 0.0;  % Weighting parameter for the term E_d
        beta_inc      = 0.0;  % Weighting parameter for the term E_{inc}
        beta_c        = 0.0;  % Weighting parameter for the term E_c
        beta_no       = 0.0;  % Weighting parameter for the term E_{no}
        beta_sf       = 0.0;  % Weighting parameter for the term E_{sf}
        lambda        = 0.0;  % Slope parameter of psi function
        mu            = 0.0;  % Shift parameter of psi function
        nb_iterations = 1;    % Number of iterations of MPP algorithm
        nb_fragments  = 100;  % Number of fragments during sampling step

        mpp_parameters = {struct('name', 'recompute_mpp', 'value', recompute_mpp), ...
                          struct('name', 'beta_d', 'value', beta_d), ...
                          struct('name', 'beta_inc', 'value', beta_inc), ...
                          struct('name', 'beta_c', 'value', beta_c), ...
                          struct('name', 'beta_no', 'value', beta_no), ...
                          struct('name', 'beta_sf', 'value', beta_sf), ...
                          struct('name', 'lambda', 'value', lambda), ...
                          struct('name', 'mu', 'value', mu), ...
                          struct('name', 'nb_iterations', 'value', nb_iterations), ...
                          struct('name', 'nb_fragments', 'value', nb_fragments)};

        %------------------------------------------------------------------

        % We create the results directory if necessary
        if ~isfolder(results_dir)
            mkdir(results_dir);
        end

        % We load the fresco image
        msg('+ loading of fresco image (degradation rate=%d', verbose);
        fresco_fn = [fresco_dir filesep fresco_name '_degraded_' num2str(round(degradation_rate)) '.png'];

        [im_fresco_color,im_fresco_alpha] = load_image(fresco_fn, false);

        if isempty(im_fresco_color) || isempty(im_fresco_alpha)
            error('Unable to load fresco image. Wrong path, missing alpha channel or unavailable degradation rate?');
        end

        im_fresco        = cat(3, im_fresco_color, im_fresco_alpha);
        fresco_nb_pixels = numel(im_fresco_alpha);

        % We load the geometric constraints file
        msg('+ loading of geometric constraints', verbose);

        geometric_constraints = load_geometric_constraints(geo_csts_fn);

        if isempty(geometric_constraints)
            error('Unable to load geometric constraints. Wrong path?');
        end

        % We load the gen parameters file
        msg('+ loading of gen parameters', verbose);

        gen_parameters = load_gen_parameters(gen_params_fn);

        if isempty(gen_parameters)
            error('Unable to load gen parameters. Wrong path?');
        end

        % We loop over fragment image filenames
        msg('+ loading of fragments', verbose);
        frag_fns = get_matching_files(frags_dir, '.*\.png');
        %frag_fns{numel(frag_fns)+1} = 'my_eroded_fragment.png'; % DEBUG, A RETIRER ABSOLUMENT A TERME !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        if isempty(frag_fns)
            error('Unable to find fragment images. Wrong path or unknown file format?');
        end

        frags_infos        = cell(1,numel(frag_fns));
        true_frags_est_idx = [];

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

            frag_area      = sum(sum(im_frag_alpha>0));
            frag_info      = struct('color', im_frag_color, 'alpha', im_frag_alpha, 'area', frag_area)
            frags_infos{k} = frag_info;

            % We estimate true fragments as the set of of square images
            if size(frag_info.alpha,1)==size(frag_info.alpha,2)
                true_frags_est_idx = [true_frags_est_idx,k];
            end
        end

        all_frags_idx                 = 1:numel(frag_fns);
        spurious_frags_est_idx        = setdiff(all_frags_idx, true_frags_est_idx);
        all_frags_areas               = cellfun(@(x) x.area, frags_infos);
        all_frags_cover_rate          = sum(all_frags_areas)/fresco_nb_pixels*100.0;
        true_frags_est_cover_rate     = sum(all_frags_areas(true_frags_est_idx))/fresco_nb_pixels*100.0;
        spurious_frags_est_cover_rate = sum(all_frags_areas(spurious_frags_est_idx))/fresco_nb_pixels*100.0;

        msg('  --------------------------------------------------------', verbose);
        msg(sprintf('  * true fragments (est.)     -> cardinality=%d, cover rate=%.2f%% (w.r.t. image)', numel(true_frags_est_idx), true_frags_est_cover_rate), verbose);
        msg(sprintf('  * spurious fragments (est.) -> cardinality=%d, cover rate=%.2f%% (w.r.t. image)', numel(spurious_frags_est_idx), spurious_frags_est_cover_rate), verbose);
        msg(sprintf('  * all fragments             -> cardinality=%d, cover rate=%.2f%% (w.r.t. image)', numel(all_frags_idx), all_frags_cover_rate), verbose);
        msg('  --------------------------------------------------------', verbose);

        % We build a reconstructed fresco composed of a set of fragments
        [final_frags_sol,final_frags_infos] = run_reconstruction_from_loaded_data(im_fresco, frags_infos, general_parameters, init_parameters, ...
                                                                                  mpp_parameters, gen_parameters, geometric_constraints);

        % We build the reconstructed fresco image from fragments
        %interpolation_type          = get_parameter_value(general_parameters, 'interpolation_type');
        %background_color            = get_parameter_value(general_parameters, 'background_color');
        %[im_rec_gray,~im_rec_color] = get_reconstructed_fresco(im_fresco(:,:,1:3), final_frags_infos, final_frags_sol, interpolation_type, background_color);
        %im_rec                      = cat(3, im_rec_color, im_fresco(:,:,4));
        %imwrite(im_rec, [results_dir filesep 'final_result.png']);

        % We save the reconstructed fresco image and fragments
        %save_registered_fragments_list(final_frags_sol, frags_infos, [results_dir filesep 'fragments.txt']);

        % We save the neighboring relationships between fragments
        %save_fragment_neighbors(final_frags_sol, [results_dir filesep 'neighbors.txt']);

        return;

        %---------------------------------------------------------------------------------------------------------------------------------------------
        %---------------------------------------------------------------------------------------------------------------------------------------------
        %---------------------------------------------------------------------------------------------------------------------------------------------

        if recompute_mpp_optimization
            ttt = tic;

            %idx = init_frags_sol{6}.idx;
            %im_frag_color = frags_infos{idx}.color;
            %im_map = im2double(imread([results_dir filesep sprintf('confidence_map_%04d.jpg', idx)]));
            %figure, imshow(im_frag_color,[]);
            %figure, imshow(im_map,[]);
            %figure, imshow(im_fresco_color,[]);

            msg('-----------------------------------------------', verbose);
            msg('+ MPP-based optimization', verbose);

            % Parameters
            alpha               = 1.0;
            beta                = 1.0;
            lambda              = 20.0;
            mu                  = -0.95;
            max_nb_iterations   = 1;
            nb_desired_frags    = 10;
            nb_attempts         = 50;
            max_nb_frag_repeats = 1;

            % Alternance between sampling and selection until convergence
            forbidden_frags     = zeros(1,numel(frags_infos));
            energies            = zeros(1,max_nb_iterations);
            nb_detections       = zeros(1,max_nb_iterations);

            %current_frags = generate_random_fragments(im_fresco_color, frags_infos, nb_desired_frags, outside_fragment_tolerance, fragments_overlap_tolerance, ...
            %                                          nb_attempts, mean_inter_fragments_distance, interpolation_type, max_nb_frag_repeats, forbidden_frags, results_dir);

            idx = 12;
            tmp1 = cellfun(@(x) x.idx, init_frags);
            tmp2 = [idx,17,19,34,48,57,126];
            [~,tmp3] = ismember(tmp2,tmp1);
            current_frags = init_frags(tmp3);
            fragments_overlap_tolerance = 0.1;
            rng(1,'twister');

            for it=1:max_nb_iterations
                % Sampling
                %new_frags = generate_random_fragments(im_fresco_color, frags_infos, nb_desired_frags, outside_fragment_tolerance, fragments_overlap_tolerance, ...
                %                                      nb_attempts, mean_inter_fragments_distance, interpolation_type, max_nb_frag_repeats, forbidden_frags, results_dir);
                %new_frags = {};

                [~,tmp3] = ismember([316],tmp1);
                new_frags = init_frags(tmp3);

                % Optimization
                [best_frags,energy] = get_best_fragments(im_fresco_color, frags_infos, current_frags, new_frags, fragments_overlap_tolerance, alpha, beta, lambda, mu, verbose);

                disp(sprintf('  + iteration %d | #current_frags=%d, #new_frags=%d, #best_frags=%d', it, numel(current_frags), numel(new_frags), numel(best_frags)));

                % Misc. assignments
                current_frags     = best_frags;
                energies(it)      = energy;
                nb_detections(it) = numel(current_frags);
            end

            final_frags = current_frags;
            [~,~,~,im_rec_frags] = get_reconstructed_fresco(im_fresco_color, frags_infos, final_frags, interpolation_type, background_color);
            show_reconstructed_fresco(im_rec_frags, best_frags, [], [], [], [], [], false, false, false, true, 'on');
            return;

            % Running time
            mpp_optimization_time = toc(ttt);

%             % Evaluation w.r.t. ground truth
%             if isempty(frags_gt)
%                 tp        = [];
%                 fp        = [];
%                 tn        = [];
%                 fn        = [];
%                 accuracy  = [];
%                 f_measure = [];
%                 ina       = [];
%             else
%                 [tp,fp,tn,fn,accuracy,f_measure,~,~,ina] = compare_solution_to_gt(best_frags, frags_gt, numel(frags_infos), translation_tolerance, angle_tolerance);
%             end
% 
%             msg('-----------------------------------------------', verbose);
%             msg('+ saving of final result', verbose);
% 
%             [~,im_filled_frags2,im_bnd_frags,im_rec_frags] = get_reconstructed_fresco(im_fresco_color, frags_infos, best_frags, interpolation_type, background_color);
% 
%             imwrite(im_filled_frags2, [results_dir filesep 'final_filled_frags2.png']);
%             imwrite(im_bnd_frags, [results_dir filesep 'final_bnd_frags.png']);
%             imwrite(im_rec_frags, [results_dir filesep 'final_rec_frags.png']);
% 
%             show_reconstructed_fresco(im_filled_frags2, best_frags, tp, fp, tn, fn, ina, false, false, false, true, show_figures);
%             results_fn = [results_dir filesep 'final_filled_frags2_n.png'];
%             saveas(gcf, results_fn);
%             system(sprintf('mogrify -trim %s', results_fn));
%             close(gcf);
% 
%             show_reconstructed_fresco(im_bnd_frags, best_frags, tp, fp, tn, fn, ina, false, false, false, true, show_figures);
%             results_fn = [results_dir filesep 'final_bnd_frags_n.png'];
%             saveas(gcf, results_fn);
%             system(sprintf('mogrify -trim %s', results_fn));
%             close(gcf);
% 
%             show_reconstructed_fresco(im_rec_frags, best_frags, tp, fp, tn, fn, ina, false, false, false, true, show_figures);
%             results_fn = [results_dir filesep 'final_rec_frags_n.png'];
%             saveas(gcf, results_fn);
%             system(sprintf('mogrify -trim %s', results_fn));
%             close(gcf);
% 
%             save_registered_fragments_list(best_frags, frags_infos, [results_dir filesep 'final_rec_frags.txt']);
% 
%             % We save the solution
%             if save_intermediate_results
%                 save(mpp_optimization_fn, 'mpp_optimization_time', 'final_frags', 'tp', 'fp', 'tn', 'fn', 'accuracy', 'f_measure', 'ina', '-v7.3');
%             end
        else
            if ~isfile(mpp_optimization_fn)
                error(sprintf('Unable to load ''%s''', mpp_optimization_fn));
            end

            msg('+ loading of MPP-based optimization results', verbose);

            load(mpp_optimization_fn, 'mpp_optimization_time', 'final_frags', 'tp', 'fp', 'tn', 'fn', 'accuracy', 'f_measure', 'ina');
        end

        % Running times
        overall_time = preprocessing_time+color_matching_time+features_matching_time+mpp_optimization_time;
        msg('--------------------------------------', verbose);
        msg(sprintf('+ preprocessing time     -> %.2f secs', preprocessing_time), verbose);
        msg(sprintf('+ confidence maps time   -> %.2f secs', color_matching_time), verbose);
        msg(sprintf('+ features matching time -> %.2f secs', features_matching_time), verbose);
        msg(sprintf('+ mpp optimization time  -> %.2f secs', mpp_optimization_time), verbose);
        msg(sprintf('+ overall time           -> %.2f secs', overall_time), verbose);
    end
end