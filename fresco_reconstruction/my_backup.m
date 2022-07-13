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

        % General parameters
        interpolation_type        = 'bilinear'; % Type of interpolation used for geometrical transform of fragments
        recompute_init_frags_sol  = 1;          % Flag indicating if first guess is recomputed or loaded
        recompute_mpp_frags_sol   = 1;          % Flag indicating if MPP-based solution is recomputed or loaded
        save_intermediate_results = 1;          % Enables/disables saving of intermediate results
        save_ground_truth_results = 1;          % Enables/disables saving of ground truth results
        translation_tolerance     = 10.0;       % Tolerance in translation in pixels (>=0)
        angle_tolerance           = 5.0;        % Tolerance in rotation in degrees (in [0,360])
        background_color          = [0,0,0];    % Background color of reconstructed fresco (in {0,...,255}^3)

        general_parameters = {struct('name', 'interpolation_type', 'value', interpolation_type), ...
                              struct('name', 'save_intermediate_results', 'value', save_intermediate_results), ...
                              struct('name', 'save_ground_truth_results', 'value', save_ground_truth_results), ...
                              struct('name', 'translation_tolerance', 'value', translation_tolerance), ...
                              struct('name', 'angle_tolerance', 'value', angle_tolerance), ...
                              struct('name', 'background_color', 'value', background_color), ...
                              struct('name', 'recompute_init_frags_sol', 'value', recompute_init_frags_sol), ...
                              struct('name', 'recompute_mpp_frags_sol', 'value', recompute_mpp_frags_sol)};

        % Initialization parameters
        outside_fragment_tolerance            = 0.1;     % Allowed normalized area of a fragment being outside fresco (in [0,1])
        fragments_overlap_tolerance           = 0.1;     % Allowed normalized area between two overlapping fragments (in [0,1])
        features_detection_threshold1         = 0.01;    % First threshold for detecting features both in fresco and fragments (>=0)
        features_detection_threshold2         = 0.03;    % Second threshold for detecting features both in fresco and fragments (>=0)
        features_extraction_method            = 'BRISK'; % Method for extracting features (can be either SURF, KAZE, FRISK, or ORB)
        features_matching_threshold           = 50.0;    % Thrreshold for features matching (in ]0,100])
        features_matching_max_ratio           = 0.6;     % Maximum ratio for features matching (in ]0,1])
        features_matching_fresco_padding      = 18;      % Padding of fresco before computing features (>=0)
        features_matching_dilation_rate       = 0.5;     % Coefficient for dilating confidence maps (in [0,1])
        color_matching_nb_bins_per_channel    = 16;      % Number of bins per channel in color histograms (in [1,256])
        color_matching_nb_rectangles          = 3;       % Number of rectangles for approximating circle (>0)
        color_matching_dilation_radius        = 3;       % Dilation radius of matched regions (>=0)
        color_matching_threshold              = 0.8;     % Threshold for extracting matched regions (in [0,1])

        init_parameters = {struct('name', 'outside_fragment_tolerance', 'value', outside_fragment_tolerance), ...
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
        beta_d        = 0.0;
        beta_inc      = 0.0;
        beta_c        = 0.0;
        beta_no       = 0.0;
        beta_sf       = 0.0;
        lambda        = 0.0;
        mu            = 0.0;
        nb_iterations = 1;
        nb_fragments  = 100;

        mpp_parameters = {struct('name', 'beta_d', 'value', beta_d, ...
                          struct('name', 'beta_inc', 'value', beta_inc, ...
                          struct('name', 'beta_c', 'value', beta_c, ...
                          struct('name', 'beta_no', 'value', beta_no, ...
                          struct('name', 'beta_sf', 'value', beta_sf, ...
                          struct('name', 'lambda', 'value', lambda, ...
                          struct('name', 'mu', 'value', mu, ...
                          struct('name', 'nb_iterations', 'value', nb_iterations, ...
                          struct('name', 'nb_fragments', 'value', nb_fragments};

        %------------------------------------------------------------------
        results_root_dir = ['..' filesep 'results' filesep 'tests'];
        data_root_dir    = ['..' filesep 'data' filesep 'irregular'];
        verbose          = 1;
        show_figures     = 1;

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
        config_name = [fresco_name '_2019-2-28_13.55.54'];
        %config_name = [fresco_name '_2019-2-28_13.56.15'];
        %config_name = [fresco_name '_2019-2-28_13.56.3'];

        %fresco_name = 'Perugino_Consegnadellechiavi_2347x1438';
        %config_name = [fresco_name '_2019-2-20_17.52.19'];

        %fresco_name = 'Piero-della-Francesca_ExaltationoftheCross_1239x900';
        %config_name = [fresco_name '_2019-2-15_18.48.27'];

        %fresco_name = 'Tiepolo_TheInstitutionoftheRosary_850x1231';
        %config_name = [fresco_name '_2019-2-15_17.29.20'];

        run_reconstruction(data_root_dir, fresco_name, config_name, results_root_dir, verbose, ...
                           show_figures, general_parameters, init_parameters, mpp_parameters);

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
%                 run_reconstruction(data_root_dir, fresco_name, config_name, results_root_dir, verbose, ...
%                                    show_figures, general_parameters, init_parameters, mpp_parameters);
%             end
%         end
        %------------------------------------------------------------------
    end

    function run_reconstruction( data_root_dir, fresco_name, config_name, results_root_dir, verbose, show_figures )
        % We check input arguments
        if isempty(data_root_dir) || isempty(fresco_name) || isempty(config_name) || isempty(results_root_dir) || isempty(verbose) || isempty(show_figures)
            error('All inputs arguments must be non empty');
            return;
        end

        % We look for the fresco image
        fresco_dir = [data_root_dir filesep fresco_name];
        config_dir    = [fresco_dir filesep config_name];
        frags_dir     = [config_dir filesep 'frag_eroded'];
        geo_csts_fn   = [frags_dir filesep 'geometric_constraints.txt'];
        gen_params_fn = [frags_dir filesep 'gen_parameters.txt'];
        gt_fn         = [config_dir filesep 'fragments.txt'];
        results_dir   = [results_root_dir filesep fresco_name filesep config_name];
        init_data_fn  = [results_dir filesep 'init_data.mat'];
        mpp_data_fn   = [results_dir filesep 'mpp_data.mat'];

        % We load the fresco image
        fresco_fns = get_matching_files(fresco_dir, [fresco_dir '.png']);

        if isempty(fresco_fns)
            error('Unable to find fresco image. Wrong path, empty directory or unknown file format?');
        end

        fresco_fn = fresco_fns{1};

        msg('+ loading of fresco image', verbose);
        [im_fresco_color,im_fresco_alpha] = load_image(imread(fresco_fn, false);
        im_fresco_gray                    = rgb2gray(im_fresco_color);
        fresco_nb_pixels                  = numel(im_fresco_gray);
        fresco_size                       = size(im_fresco_gray);
        nb_channels                       = size(im_fresco_color,3);

        % We look for the fragment images
        frag_fns = get_matching_files(frags_dir, '.*\.png');
        %frag_fns{numel(frag_fns)+1} = 'my_eroded_fragment.png'; % DEBUG, A RETIRER ABSOLUMENT A TERME !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        if isempty(frag_fns)
            error('Unable to find fragment images. Wrong path, empty directory or unknown file format?');
        end

        % We create results directories
        if ~isfolder(results_dir)
            mkdir(results_dir);
        end

            % We load fresco


            % We load fragment images
            msg('+ loading of fragments', verbose);
            frags_infos        = cell(1,numel(frag_fns));
            true_frags_est_idx = [];

            parfor k=1:numel(frag_fns)
                [im_frag_color,im_frag_alpha] = load_image(frag_fns{k}, false);
                frags_infos{k}                = struct('color', im_frag_color, 'alpha', im_frag_alpha);
            end
                msg(sprintf('  + fragment %d/%d | size=(%d,%d), area=%d, std=%f, inner circle=(%d,%d)|%.2f, outer circle=(%.2f,%.2f)|%.2f', ...
                            k, numel(frag_fns), frag_info.frag_size, frag_info.area, frag_info.std, frag_info.inner_circle_center, frag_info.inner_circle_radius, ...
                            frag_info.outer_circle_center, frag_info.outer_circle_radius), verbose);

                % We estimate true fragments as the set of of square images
                if size(frag_info.alpha,1)==size(frag_info.alpha,2)
                    true_frags_est_idx = [true_frags_est_idx,k];
                end
            end

            all_frags_idx          = 1:numel(frag_fns);
            spurious_frags_est_idx = setdiff(all_frags_idx, true_frags_est_idx);

            all_frags_areas = cellfun(@(x) x.area, frags_infos);

            all_frags_cover_rate          = sum(all_frags_areas)/fresco_nb_pixels*100.0;
            true_frags_est_cover_rate     = sum(all_frags_areas(true_frags_est_idx))/fresco_nb_pixels*100.0;
            spurious_frags_est_cover_rate = sum(all_frags_areas(spurious_frags_est_idx))/fresco_nb_pixels*100.0;

            msg('--------------------------------------------------------', verbose);
            msg(sprintf('+ true fragments (est.)     -> cardinality=%d, cover rate=%.2f%% (w.r.t. image)', numel(true_frags_est_idx), true_frags_est_cover_rate), verbose);
            msg(sprintf('+ spurious fragments (est.) -> cardinality=%d, cover rate=%.2f%% (w.r.t. image)', numel(spurious_frags_est_idx), spurious_frags_est_cover_rate), verbose);
            msg(sprintf('+ all fragments             -> cardinality=%d, cover rate=%.2f%% (w.r.t. image)', numel(all_frags_idx), all_frags_cover_rate), verbose);

            % We load ground truth (if available)
            if ~isfile(gt_fn)
                frags_gt                      = {};
                true_frags_idx                = [];
                spurious_frags_idx            = [];
                true_frags_cover_rate         = [];
                spurious_frags_cover_rate     = [];
            else
                msg('+ loading of ground truth', verbose);
                [id,tx,ty,angles] = textread(gt_fn, '%d %d %d %f');

                if numel(id)~=numel(tx) || numel(id)~=numel(ty) || numel(id)~=numel(angles)
                    error('The format of the ground truth file is incorrect');
                end

                frags_gt       = cell(1,numel(id));
                true_frags_idx = [];

                parfor k=1:numel(id)
                    angle               = -angles(k); % CAUTION: OPPOSITE ANGLE IS TAKEN
                    q                   = apply_forward_transform(frags_infos{id(k)+1}.offset, [0,0], angle, [0,0]);
                    translation         = [ty(k),tx(k)]-q;
                    fs                  = round(0.5*frags_infos{id(k)+1}.size);
                    inner_circle_center = round(apply_forward_transform([0,0], translation, angle, [0,0]));
                    inner_circle_radius = frags_infos{id(k)+1}.inner_circle_radius;
                    outer_circle_center = round(apply_forward_transform(frags_infos{id(k)+1}.outer_circle_center, translation, angle, fs));
                    outer_circle_radius = frags_infos{id(k)+1}.outer_circle_radius;
                    frags_gt{k}         = struct('idx', id(k)+1, 'translation', translation, 'angle', angle, 'inner_circle_center', inner_circle_center, ...
                                                 'inner_circle_radius', inner_circle_radius, 'outer_circle_center', outer_circle_center, ...
                                                 'outer_circle_radius', outer_circle_radius, 'fresco_coords', [], 'frag_coords', []);
                    true_frags_idx      = [true_frags_idx,id(k)+1];
                    %msg(sprintf('  + fragment | id=%d, translation=(%d,%d), angle=%f, inner circle center=(%.2f,%.2f), outer circle center=(%.2f,%.2f)', ...
                    %            id(k), translation, angles(k), inner_circle_center, outer_circle_center), verbose);
                end

                all_frags_idx      = 1:numel(frag_fns);
                spurious_frags_idx = setdiff(all_frags_idx, true_frags_idx);

                all_frags_areas = cellfun(@(x) x.area, frags_infos);

                all_frags_cover_rate      = sum(all_frags_areas)/fresco_nb_pixels*100.0;
                true_frags_cover_rate     = sum(all_frags_areas(true_frags_idx))/fresco_nb_pixels*100.0;
                spurious_frags_cover_rate = sum(all_frags_areas(spurious_frags_idx))/fresco_nb_pixels*100.0;

                msg('--------------------------------------------------------', verbose);
                msg(sprintf('+ true fragments     -> cardinality=%d, cover rate=%.2f%% (w.r.t. image)', numel(true_frags_idx), true_frags_cover_rate), verbose);
                msg(sprintf('+ spurious fragments -> cardinality=%d, cover rate=%.2f%% (w.r.t. image)', numel(spurious_frags_idx), spurious_frags_cover_rate), verbose);
                msg(sprintf('+ all fragments      -> cardinality=%d, cover rate=%.2f%% (w.r.t. image)', numel(all_frags_idx), all_frags_cover_rate), verbose);

                %[im_filled_frags1,im_filled_frags2,im_bnd_frags,im_rec_frags] = get_reconstructed_fresco(im_fresco_color, frags_infos, frags_gt, interpolation_type, background_color);
                %neighbors_fn = [results_dir filesep 'neighbors.png'];
                %dist_ifd1_fn = [results_dir filesep 'dist_ifd1.png'];
                %dist_ifd2_fn = [results_dir filesep 'dist_ifd2.png'];
                %[ifd1,ifd2] = get_inter_fragments_distance_estimate(im_filled_frags1, neighbors_fn, dist_ifd1_fn, dist_ifd2_fn)
                %figure, imshow(im_filled_frags1,[]);
                %imdistline;
                %return;

                % Ground truth results
                if save_ground_truth_results
                    [~,im_filled_frags2,im_bnd_frags,im_rec_frags] = get_reconstructed_fresco(im_fresco_color, frags_infos, frags_gt, interpolation_type, background_color);

                    imwrite(im_filled_frags2, [results_dir filesep 'gt_filled_frags2.png']);
                    imwrite(im_bnd_frags, [results_dir filesep 'gt_bnd_frags.png']);
                    imwrite(im_rec_frags, [results_dir filesep 'gt_rec_frags.png']);

                    show_reconstructed_fresco(im_filled_frags2, frags_gt, [], [], [], [], [], false, false, false, true, show_figures);
                    fn = [results_dir filesep 'gt_filled_frags2_n.png'];
                    saveas(gcf, fn);
                    system(sprintf('mogrify -trim %s', fn));
                    close(gcf);

                    show_reconstructed_fresco(im_bnd_frags, frags_gt, [], [], [], [], [], false, false, false, true, show_figures);
                    fn = [results_dir filesep 'gt_bnd_frags_n.png'];
                    saveas(gcf, fn);
                    system(sprintf('mogrify -trim %s', fn));
                    close(gcf);

                    show_reconstructed_fresco(im_rec_frags, frags_gt, [], [], [], [], [], false, false, false, true, show_figures);
                    fn = [results_dir filesep 'gt_rec_frags_n.png'];
                    saveas(gcf, fn);
                    system(sprintf('mogrify -trim %s', fn));
                    close(gcf);
                end
            end

            preprocessing_time = toc(ttt);

            if save_intermediate_results
                save(preprocessing_fn, 'im_fresco_color', 'im_fresco_gray', 'fresco_nb_pixels', 'fresco_size', ...
                                       'all_frags_idx', 'spurious_frags_est_idx', ...
                                       'true_frags_est_idx', 'spurious_frags_idx', ...
                                       'true_frags_idx', 'frags_infos', 'frags_gt', ...
                                       'preprocessing_time', 'mean_inter_fragments_distance', '-v7.3');
            end
        else
            if ~isfile(preprocessing_fn)
                error(sprintf('Unable to load ''%s''', preprocessing_fn));
            end

            msg('+ loading of preprocessing results', verbose);

            load(preprocessing_fn, 'im_fresco_color', 'im_fresco_gray', 'fresco_nb_pixels', 'fresco_size', ...
                                   'all_frags_idx', 'spurious_frags_est_idx', ...
                                   'true_frags_est_idx', 'spurious_frags_idx', ...
                                   'true_frags_idx', 'frags_infos', 'frags_gt', ...
                                   'preprocessing_time', 'mean_inter_fragments_distance');
        end

        return;

        %------------------------------------------------------------------
        % Parameters
        alpha  = 1.0;
        beta   = 1.0;
        gamma  = 1.0;
        eta    = 100.0;
        lambda = 100.0;
        kappa  = 100.0;
        %------------------------------------------------------------------

        %------------------------------------------------------------------
%         % CODE FOR TESTING PAIRWISE FRAGMENTS REGISTRATION
%         im_fresco_gray2 = im2double(im_fresco_gray);
%         [im_fresco_grad_x,im_fresco_grad_y] = imgradientxy(im_fresco_gray2, 'sobel');
% 
%         frags1 = frags_gt;
% 
%         %frags_gt = {frags_gt{2},frags_gt{51},frags_gt{21}};
%         %frags1 = frags_gt;
%         %frags1{2}.translation = frags1{2}.translation-randi([50,200],1,2);
%         %frags1{3}.translation = frags1{3}.translation+randi([50,200],1,2);
% 
%         % Fragments 2 et 21
%         %frags_gt = {frags_gt{2},frags_gt{21}};
%         %frags1 = frags_gt;
%         %frags1{1}.translation = frags1{1}.translation+[100,150];
%         %frags1{2}.translation = frags1{2}.translation+[70,70];
% 
%         % Fragments 21 et 51
%         %frags_gt = {frags_gt{21},frags_gt{51}};
%         %frags1 = frags_gt;
%         %frags1{1}.translation = frags1{1}.translation+[70,70];
% 
%         % Fragments 51 et 2
%         %frags_gt = {frags_gt{51},frags_gt{2}};
%         %frags1 = frags_gt;
%         %frags1{2}.translation = frags1{2}.translation+[100,150];
% 
%         % Fragments 2, 51 et 21
%         %frags_gt = {frags_gt{2},frags_gt{51},frags_gt{21}};
%         %frags1 = frags_gt;
%         %frags1{1}.translation = frags1{1}.translation+[100,150];
%         %frags1{3}.translation = frags1{3}.translation+[70,70];
% 
%         %load('my_frags.mat');
%         %save('my_frags.mat', 'frags1');
% 
%         %tic;
%         frags2 = get_registered_fragments(im_fresco_gray2, im_fresco_grad_x, im_fresco_grad_y, frags_infos, frags1, ...
%                                           interpolation_type, mean_inter_fragments_distance, max_inter_fragments_distance, lambda, beta, kappa, true);
%         %pause(3);
%         %toc;
% 
%         %-------------------
%         [~,~,~,im_rec_frags] = get_reconstructed_fresco(im_fresco_color, frags_infos, frags_gt, interpolation_type, background_color);
%         show_reconstructed_fresco(im_rec_frags, frags_gt, [], [], [], [], [], false, false, false, true, show_figures);
%         fn = 'verite_terrain.png';
%         saveas(gcf, fn);
%         system(sprintf('mogrify -trim %s', fn));
%         close(gcf);
%         %-------------------
%         [~,~,~,im_rec_frags] = get_reconstructed_fresco(im_fresco_color, frags_infos, frags1, interpolation_type, background_color);
%         [~,~,~,~,~,~,~,~,ina] = compare_solution_to_gt(frags1, frags_gt, length(frags1), 2.0, 2.0);
%         show_reconstructed_fresco(im_rec_frags, frags1, [], [], [], [], ina, false, false, false, true, show_figures);
%         fn = 'fresque_a_recaler.png';
%         saveas(gcf, fn);
%         system(sprintf('mogrify -trim %s', fn));
%         close(gcf);
%         %-------------------
%         [~,~,~,im_rec_frags] = get_reconstructed_fresco(im_fresco_color, frags_infos, frags2, interpolation_type, background_color);
%         [~,~,~,~,~,~,~,~,ina] = compare_solution_to_gt(frags2, frags_gt, length(frags2), 5.0, 5.0);
%         show_reconstructed_fresco(im_rec_frags, frags2, [], [], [], [], ina, false, false, true, true, show_figures);
%         length(ina)
%         fn = 'fresque_recalee.png';
%         saveas(gcf, fn);
%         system(sprintf('mogrify -trim %s', fn));
%         close(gcf);
%         return;
        %------------------------------------------------------------------

        %------------------------------------------------------------------
%         % CODE FOR TESTING ACCURATE IMAGE REGISTRATION
%         im_fresco_gray2 = im2double(im_fresco_gray);
%         [im_fresco_grad_x,im_fresco_grad_y] = imgradientxy(im_fresco_gray2, 'sobel');
% 
%         frags_gt = frags_gt;
%         frags1 = frags_gt;
%         for k=1:length(frags1)
%             %[frags1{k}.translation,frags1{k}.angle]'
%             frags1{k}.translation = frags1{k}.translation+rand_bounds([-10,-10],[+10,+10]);
%             frags1{k}.angle       = frags1{k}.angle+rand_bounds(-10,+10);
%             %frags1{k}.translation = [frags1{k}.translation(1)-10,frags1{k}.translation(2)];
%             %frags1{k}.angle = frags1{k}.angle-10;
%             %disp('------------------------------------------');
%             %[frags1{k}.translation,frags1{k}.angle]'
%         end
%         load('my_frags.mat');
%         %save('my_frags.mat', 'frags1');
%         tic;
%         frags2 = get_registered_fragment(im_fresco_gray2, im_fresco_grad_x, im_fresco_grad_y, frags_infos, frags1, interpolation_type, ...
%                                          mean_inter_fragments_distance, max_inter_fragments_distance, alpha, eta, false);
%         toc;
%         mte1 = [];
%         mte2 = [];
%         moe  = [];
%         for k=1:length(frags2)
%             t1 = frags2{k}.translation;
%             t2 = frags_gt{k}.translation;
%             a1 = frags2{k}.angle;
%             a2 = frags_gt{k}.angle;
%             disp(sprintf('+ fragment %d | t1=(%f,%f), a1=%f | t2=(%f,%f), a2=%f | delta_t=(%f,%f), delta_angle=%f', k, t1(1), t1(2), a1, t2(1), t2(2), a2, abs(t1(1)-t2(1)), abs(t1(2)-t2(2)), get_angular_difference(a1,a2)));
%             mte1 = [mte1,abs(t1(1)-t2(1))];
%             mte2 = [mte2,abs(t1(2)-t2(2))];
%             moe  = [moe,get_angular_difference(a1,a2)];
%         end
%         mean(mte1)
%         mean(mte2)
%         mean(moe)
%         %-------------------
%         [~,~,~,im_rec_frags] = get_reconstructed_fresco(im_fresco_color, frags_infos, frags_gt, interpolation_type, background_color);
%         show_reconstructed_fresco(im_rec_frags, frags_gt, [], [], [], [], [], false, false, false, true, show_figures);
%         fn = 'verite_terrain.png';
%         saveas(gcf, fn);
%         system(sprintf('mogrify -trim %s', fn));
%         close(gcf);
%         %-------------------
%         [~,~,~,im_rec_frags] = get_reconstructed_fresco(im_fresco_color, frags_infos, frags1, interpolation_type, background_color);
%         [~,~,~,~,~,~,~,~,ina] = compare_solution_to_gt(frags1, frags_gt, length(frags1), 2.0, 2.0);
%         show_reconstructed_fresco(im_rec_frags, frags1, [], [], [], [], ina, false, false, false, true, show_figures);
%         fn = 'fresque_a_recaler.png';
%         saveas(gcf, fn);
%         system(sprintf('mogrify -trim %s', fn));
%         close(gcf);
%         %-------------------
%         [~,~,~,im_rec_frags] = get_reconstructed_fresco(im_fresco_color, frags_infos, frags2, interpolation_type, background_color);
%         [~,~,~,~,~,~,~,~,ina] = compare_solution_to_gt(frags2, frags_gt, length(frags2), 5.0, 5.0);
%         show_reconstructed_fresco(im_rec_frags, frags2, [], [], [], [], ina, false, false, false, true, show_figures);
%         length(ina)
%         fn = 'fresque_recalee.png';
%         saveas(gcf, fn);
%         system(sprintf('mogrify -trim %s', fn));
%         close(gcf);
%         return;
        %------------------------------------------------------------------

        %---------------------------------------------------------------------------------------------------------------------------------------------
        %---------------------------------------------------------------------------------------------------------------------------------------------
        %---------------------------------------------------------------------------------------------------------------------------------------------

        if recompute_color_matching
            ttt = tic;

            % We compute normalized histogram of fresco image
            msg('+ computing fresco histogram', verbose);
            [fresco_hist,fresco_hist_idx] = get_histogram(im_fresco_color, [], color_matching_nb_bins_per_channel);
            fresco_hist_n = (fresco_hist / sum(fresco_hist));

            % For each fragment, we search regions sharing the same color
            msg('+ color matching of fragments', verbose);
            frags_covers_rates = [];
            frags_outside_idx  = [];

            parfor k=1:numel(frags_infos)
                frag_info = frags_infos{k};

                % We separate rgb channels from alpha channel for convenience
                im_frag_color = frag_info.color;
                im_frag_alpha = frag_info.alpha;

                % We compute binary image of inscribed circle
                ic_radius_t                         = (frag_info.inner_circle_radius*0.8);
                ic_center_t                         = frag_info.inner_circle_center;
                im_d                                = zeros(size(im_frag_alpha));
                im_d(ic_center_t(1),ic_center_t(2)) = 1;
                im_inner_circle                     = bwdist(im_d>0, 'euclidean')<ic_radius_t;

                % Color matching based on histogram backprojection
                im_map = get_confidence_map(fresco_hist_n, fresco_hist_idx, color_matching_nb_bins_per_channel, ...
                                            im_frag_color, im_inner_circle, ic_radius_t, color_matching_nb_rectangles);

                % We binarize the grayscale confidence map
                im_map2 = binarize_confidence_map(im_map, color_matching_threshold, color_matching_dilation_radius);

                % We keep track of cover rate for current fragment
                frag_cover_rate    = sum(im_map2(:))/fresco_nb_pixels*100.0;
                frags_covers_rates = [frags_covers_rates frag_cover_rate];

                % In case of true fragment, we check if the map includes at least the registered center of the inscribed circle
                if ~isempty(frags_gt)
                    fresco_idx = is_fragment_in_gt(frags_gt, k);

                    if ~isempty(fresco_idx)
                        % We project the center of the inscribed circle in the fresco and check that the map contains it
                        q = round(apply_forward_transform([0,0], frags_gt{fresco_idx}.translation, frags_gt{fresco_idx}.angle, [0,0]));

                        if im_map2(q(1),q(2))==0
                            msg(sprintf('  + fragment %d | OUTSIDE !!!!!!!!!!!!!!!!!!!!!!!', k), verbose);
                            frags_outside_idx = [frags_outside_idx,k];

                            %------ For debugging ------
                            %figure('units','normalized','outerposition',[0 0 1 1],'visible','off');
                            %imshow(im_map,[]);
                            %hold on;
                            %plot(q(2),q(1),'r+','MarkerSize',20,'LineWidth',3);
                            %saveas(gcf, [results_dir filesep sprintf('foobar_%04d.jpg', k)]);
                            %close(gcf);
                            %---------------------------
                        else
                            msg(sprintf('  + fragment %d | INSIDE (cover rate=%.2f%%)', k, frag_cover_rate), verbose);
                        end

                        % For debugging
                        %figure, imshow(im_fresco_color,[]);
                        %figure, imshow(im_frag_color,[]);
                    else
                        msg(sprintf('  + fragment %d | UNKNOWN (cover rate=%.2f%%)', k, frag_cover_rate), verbose);
                    end
                end

                % We save the confidence map
                if save_intermediate_results
                    imwrite(im_map, [results_dir filesep sprintf('confidence_map_%04d.jpg', k)]);
                end
            end

            %------ For debugging ------
            %h = figure;
            %histogram(frags_covers_rates, 100);
            %xlabel('Cover rate (in [0,100])');
            %fn = [results_dir filesep 'cover_rates_distribution.png'];
            %saveas(h, fn);
            %system(sprintf('mogrify -trim %s', fn));
            %---------------------------

            % We display statistics of fragments covers
            msg(sprintf('----------------------------------'), verbose);
            msg(sprintf('[ stats on cover rates of confidence maps ]'), verbose);
            msg(sprintf('  + mean=%f, std=%f, median=%f', mean(frags_covers_rates), std(frags_covers_rates), median(frags_covers_rates)), verbose);
            msg(sprintf('  + min=%f, max=%f', min(frags_covers_rates), max(frags_covers_rates)), verbose);

            % Running time
            color_matching_time = toc(ttt);

            % We save variables
            if save_intermediate_results
                save(color_matching_fn, 'frags_covers_rates', 'frags_outside_idx', 'color_matching_time', '-v7.3');
            end
        else
            if ~isfile(color_matching_fn)
                error(sprintf('Unable to load ''%s''', color_matching_fn));
            end

            msg('+ loading of color matching results', verbose);

            load(color_matching_fn, 'frags_covers_rates', 'frags_outside_idx', 'color_matching_time');
        end

        %---------------------------------------------------------------------------------------------------------------------------------------------
        %---------------------------------------------------------------------------------------------------------------------------------------------
        %---------------------------------------------------------------------------------------------------------------------------------------------

        if recompute_features_matching
            ttt = tic;

            % We detect and extract features on fresco
            msg('+ detection/extraction of fresco features', verbose);

            im_fresco_mask2 = padarray(ones(fresco_size, 'logical'), [features_matching_fresco_padding,features_matching_fresco_padding], 'both');
            im_fresco_gray2 = padarray(im_fresco_gray, [features_matching_fresco_padding,features_matching_fresco_padding], 'both', 'symmetric');

            fresco_points                    = detectFASTFeatures(im_fresco_gray2, 'MinContrast', features_detection_threshold1, 'MinQuality', features_detection_threshold2);
            [fresco_features,fresco_points2] = extractFeatures(im_fresco_gray2, fresco_points, 'method', features_extraction_method);
            [fresco_points2,fresco_features] = filter_keypoints_and_features(im_fresco_mask2, fresco_points2, fresco_features);
            fresco_points2.Location          = fresco_points2.Location-features_matching_fresco_padding;

            % We detect and extract features on fragments
            msg('+ detection/extraction of fragment features', verbose);
            results = cell(1,numel(frags_infos));

            parfor k=1:numel(results)
                msg(sprintf('  + fragment %d', k), verbose);

                % We convert fragment to grayscale
                frag_info    = frags_infos{k};
                im_frag_gray = rgb2gray(frag_info.color);

                % We slightly erode fragment and extend image borders
                im_frag_alpha = imerode(frag_info.alpha, strel('disk', 1));
                im_frag_gray2 = extend_image_borders(im_frag_alpha, im_frag_gray);

                % We detect features and only keep those lying in fragment
                frag_points = detectFASTFeatures(im_frag_gray2, 'MinContrast', features_detection_threshold1, 'MinQuality', features_detection_threshold2);

                % We extract features
                [frag_features,frag_points2] = extractFeatures(im_frag_gray2, frag_points, 'method', features_extraction_method);

                % We filter both keypoints and features
                [frag_points2_f,frag_features_f] = filter_keypoints_and_features(im_frag_alpha, frag_points2, frag_features);

                % We check if there are enough features
                if isempty(frag_points2_f) || isempty(frag_features_f)
                    results{k} = struct('tform', [], 'status', 1, 'nb_filtered_frag_points', 0, 'nb_filtered_fresco_points', 0, 'nb_matched_points', 0, 'nb_tform_points', 0);
                    continue;
                end

                %------ For debugging ------
                %figure, imshow(frag_info.color,[]); hold on; plot(frag_points2); hold off;
                %figure, imshow(frag_info.color,[]); hold on; plot(fresco_points2); hold off;
                %---------------------------

                % We get the inner and outer circles
                outer_circle_radius = frag_info.outer_circle_radius;
                outer_circle_center = frag_info.outer_circle_center;
                inner_circle_radius = frag_info.inner_circle_radius;
                inner_circle_center = frag_info.inner_circle_center;

                % We load and binarize the confidence map
                im_map = im2double(imread([results_dir filesep sprintf('confidence_map_%04d.jpg', k)]));
                im_map = binarize_confidence_map(im_map, color_matching_threshold*max(im_map(:)), color_matching_dilation_radius);

                % We filter both keypoints and features using the dilated confidence map
                dilation_radius                      = round(double(features_matching_dilation_rate*0.5*(outer_circle_radius-inner_circle_radius+norm(outer_circle_center-inner_circle_center))));
                im_map                               = imdilate(im_map, strel('square', 2*dilation_radius+1));
                [fresco_points2_f,fresco_features_f] = filter_keypoints_and_features(im_map, fresco_points2, fresco_features);

                % We check if there are enough features
                if isempty(fresco_points2_f) || isempty(fresco_features_f)
                    results{k} = struct('tform', [], 'status', 1, 'nb_filtered_frag_points', size(frag_points2_f,1), 'nb_filtered_fresco_points', 0, 'nb_matched_points', 0, 'nb_tform_points', 0);
                    continue;
                end

                % We match fresco features against fragment features
                index_pairs    = matchFeatures(fresco_features_f, frag_features_f, 'MatchThreshold', features_matching_threshold, 'MaxRatio', features_matching_max_ratio, 'Unique', true);
                fresco_points3 = fresco_points2_f(index_pairs(:, 1), :);
                frag_points3   = frag_points2_f(index_pairs(:, 2), :);

                %------ For debugging ------
                %figure, imshow(frag_info.color,[]); hold on; plot(frag_points3); hold off;
                %if k==17
                %    figure, showMatchedFeatures(im_fresco_color, frag_info.color, fresco_points3, frag_points3);
                %end
                %---------------------------

                % We estimate the (rigid) geometric transform
                if ~verbose
                    warning('off', 'vision:ransac:maxTrialsReached');
                end
                [tform,frag_points4,fresco_points4,status] = estimateGeometricTransform(frag_points3, fresco_points3, 'similarity');

                % We store matching results
                results{k} = struct('tform', tform, 'status', status, 'nb_filtered_frag_points', size(frag_points2_f,1), 'nb_filtered_fresco_points', size(fresco_points2_f,1), 'nb_matched_points', size(index_pairs,1), 'nb_tform_points', size(frag_points4,1));

                %------ For debugging ------
                %im_map = zeros(fresco_size, 'logical');
                %im_map(im_confidence_maps{k}) = 1;
                %figure, imshow(im_map,[]);
                %figure, showMatchedFeatures(im_fresco_color, frag_info.color, fresco_points4, frag_points4);
                %---------------------------
            end

            % We construct the initialization
            msg('+ construction of the initialization', verbose);
            [nb,idx] = sort(cellfun(@(x) x.nb_tform_points, results), 'descend');
            frags_order = idx(nb>0);

            matched_frags_idx     = []; % Fragments placed
            unmatched_frags_idx   = []; % Fragments having matching problems
            outside_frags_idx     = []; % Fragments outside fresco
            overlapping_frags_idx = []; % Fragments overlapping with other ones

            init_frags = {};

            for k=1:numel(frags_order)
                kk            = frags_order(k);
                frag_info     = frags_infos{kk};
                im_frag_color = frag_info.color;
                im_frag_alpha = frag_info.alpha;
                frag_size     = frag_info.size;
                frag_area     = frag_info.area;
                tform         = results{kk}.tform;
                status        = results{kk}.status;

                if status>0
                    msg(sprintf('  + fragment %d | FAIL (matching problem)', kk), verbose);
                    unmatched_frags_idx = [unmatched_frags_idx,kk];
                    continue;
                end

                % We extract parameters from the estimated geometric transform matrix
                [translation,angle,~] = get_transform_parameters(tform, frag_size);

                % We register the fragment to the fresco
                [fresco_coords_t,frag_coords_t] = get_transformed_fragment(im_frag_alpha, translation, angle, fresco_size);
                frag_area_t                     = size(fresco_coords_t,1);
                ic_center_t                     = round(apply_forward_transform([0,0], translation, angle, [0,0]));
                oc_center_t                     = round(apply_forward_transform(frag_info.outer_circle_center, translation, angle, frag_info.inner_circle_center));
                ic_radius_t                     = frag_info.inner_circle_radius;
                oc_radius_t                     = frag_info.outer_circle_radius;

                % We check if the registered fragment lies inside fresco
                if ~is_fragment_inside_fresco(oc_center_t, frag_area_t, fresco_size, frag_area, outside_fragment_tolerance)
                    msg(sprintf('  + fragment %d | FAIL (outside fresco)', kk), verbose);
                    outside_frags_idx = [outside_frags_idx,kk];
                    continue;
                end

                % We check if the registered fragment does not intersect with neighboring ones
                if fragments_overlap_tolerance<1
                    no_intersections = 1;

                    for i=1:numel(init_frags)
                        fresco_coords_t2 = init_frags{i}.fresco_coords;
                        oc_center_t2     = init_frags{i}.outer_circle_center;
                        oc_radius_t2     = init_frags{i}.outer_circle_radius;

                        if are_fragments_intersected(fresco_coords_t, oc_center_t, oc_radius_t, fresco_coords_t2, oc_center_t2, oc_radius_t2, fragments_overlap_tolerance)
                            no_intersections = 0;
                            break;
                        end
                    end

                    if ~no_intersections
                        msg(sprintf('  + fragment %d | FAIL (intersect with other fragments)', kk), verbose);
                        overlapping_frags_idx = [overlapping_frags_idx,kk];
                        continue;
                    end
                end

                % We add fragment to the list
                matched_frags_idx    = [matched_frags_idx,kk];
                frag_intensities_t   = get_intensities(im_frag_color, frag_coords_t, interpolation_type)/255.0;
                fresco_intensities_t = get_intensities(im_fresco_color, fresco_coords_t, interpolation_type)/255.0;
                init_frag            = struct('idx', kk, 'translation', translation, 'angle', angle, 'area', frag_area_t, ...
                                              'fresco_coords', fresco_coords_t, 'frag_coords', frag_coords_t, 'frag_intensities', frag_intensities_t, ...
                                              'fresco_intensities', fresco_intensities_t, 'inner_circle_center', ic_center_t, 'outer_circle_center', oc_center_t, ...
                                              'inner_circle_radius', ic_radius_t, 'outer_circle_radius', oc_radius_t, 'neighbors', [], 'color_idx', []);
                init_frags           = [init_frags,{init_frag}];

                if isempty(frags_gt)
                    msg(sprintf('  + fragment %d | UNKNOWN', kk), verbose);
                else
                    % We compare the parameters of the estimated geometric transform against ground truth (if available)
                    idx = is_fragment_in_gt(frags_gt, kk);

                    if isempty(idx)
                        msg(sprintf('  + fragment %d | WRONGLY PLACED', kk), verbose);
                    else
                        if is_fragment_identical_to_gt(init_frag, frags_gt{idx}, translation_tolerance, angle_tolerance)
                            msg(sprintf('  + fragment %d | ACCURATELY PLACED', kk), verbose);
                        else
                            msg(sprintf('  + fragment %d | INACCURATELY PLACED', kk), verbose);
                        end
                    end
                end
            end

            % We compute dilated fragments
            parfor i=1:numel(init_frags)
                fresco_coords                 = init_frags{i}.fresco_coords;
                fresco_idx                    = sub2ind(fresco_size, fresco_coords(:,1), fresco_coords(:,2));
                im_frag_t                     = zeros(fresco_size);
                im_frag_t(fresco_idx)         = 1;
                [rows_d,cols_d]               = find(imdilate(im_frag_t, strel('square', round(2*mean_inter_fragments_distance+1))));
                init_frags{i}.fresco_coords_d = [rows_d,cols_d];
            end

            % Running time
            features_matching_time = toc(ttt);

            % Evaluation w.r.t. ground truth
            if isempty(frags_gt)
                tp        = [];
                fp        = [];
                tn        = [];
                fn        = [];
                accuracy  = [];
                f_measure = [];
                ina       = [];
            else
                [tp,fp,tn,fn,accuracy,f_measure,~,~,ina] = compare_solution_to_gt(init_frags, frags_gt, numel(frags_infos), translation_tolerance, angle_tolerance);
            end

            % We show and save initilization results
            msg('-----------------------------------------------', verbose);
            msg('+ saving of initialization', verbose);

            [~,im_filled_frags2,im_bnd_frags,im_rec_frags] = get_reconstructed_fresco(im_fresco_color, frags_infos, init_frags, interpolation_type, background_color);

            imwrite(im_filled_frags2, [results_dir filesep 'init_filled_frags2.png']);
            imwrite(im_bnd_frags, [results_dir filesep 'init_bnd_frags.png']);
            imwrite(im_rec_frags, [results_dir filesep 'init_rec_frags.png']);

            show_reconstructed_fresco(im_filled_frags2, init_frags, tp, fp, tn, fn, ina, false, false, false, true, show_figures);
            results_fn = [results_dir filesep 'init_filled_frags2_n.png'];
            saveas(gcf, results_fn);
            system(sprintf('mogrify -trim %s', results_fn));
            close(gcf);

            show_reconstructed_fresco(im_bnd_frags, init_frags, tp, fp, tn, fn, ina, false, false, false, true, show_figures);
            results_fn = [results_dir filesep 'init_bnd_frags_n.png'];
            saveas(gcf, results_fn);
            system(sprintf('mogrify -trim %s', results_fn));
            close(gcf);

            show_reconstructed_fresco(im_rec_frags, init_frags, tp, fp, tn, fn, ina, false, false, false, true, show_figures);
            results_fn = [results_dir filesep 'init_rec_frags_n.png'];
            saveas(gcf, results_fn);
            system(sprintf('mogrify -trim %s', results_fn));
            close(gcf);

            save_registered_fragments_list(init_frags, frags_infos, [results_dir filesep 'init_rec_frags.txt']);

            % We save the solution
            if save_intermediate_results
                save(features_matching_fn, 'features_matching_time', 'results', 'init_frags', ...
                                           'matched_frags_idx', 'unmatched_frags_idx', 'outside_frags_idx', 'overlapping_frags_idx', ...
                                           'tp', 'fp', 'tn', 'fn', 'accuracy', 'f_measure', 'ina', '-v7.3');
            end
        else
            if ~isfile(features_matching_fn)
                error(sprintf('Unable to load ''%s''', features_matching_fn));
            end

            msg('+ loading of features matching results', verbose);

            load(features_matching_fn, 'features_matching_time', 'results', 'init_frags', ...
                                       'matched_frags_idx', 'unmatched_frags_idx', 'outside_frags_idx', 'overlapping_frags_idx', ...
                                       'tp', 'fp', 'tn', 'fn', 'accuracy', 'f_measure', 'ina');
        end

        % Counting
        frags_area = cellfun(@(x) x.area, frags_infos);

        msg('-----------------------------------------------', verbose);
        msg(sprintf('+ nb matched frags       -> %d (cover rate w.r.t. image=%.2f%%)', numel(matched_frags_idx), sum(frags_area(matched_frags_idx))/fresco_nb_pixels*100.0), verbose);
        msg(sprintf('+ nb unmatched frags     -> %d (cover rate w.r.t. image=%.2f%%)', numel(unmatched_frags_idx), sum(frags_area(unmatched_frags_idx))/fresco_nb_pixels*100.0), verbose);
        msg(sprintf('+ nb outside frags       -> %d (cover rate w.r.t. image=%.2f%%)', numel(outside_frags_idx), sum(frags_area(outside_frags_idx))/fresco_nb_pixels*100.0), verbose);
        msg(sprintf('+ nb overlapping frags   -> %d (cover rate w.r.t. image=%.2f%%)', numel(overlapping_frags_idx), sum(frags_area(overlapping_frags_idx))/fresco_nb_pixels*100.0), verbose);

        % Print evaluation w.r.t. ground truth
        if ~isempty(frags_gt)
            msg('-----------------------------------------------', verbose);
            msg(sprintf('+ nb wrongly placed frags (FP)    -> %d (cover rate w.r.t. image=%.2f%%)', numel(fp), sum(frags_area(fp))/fresco_nb_pixels*100.0), verbose);
            msg(sprintf('+ nb accurately placed frags (TP) -> %d (cover rate w.r.t. image=%.2f%%)', numel(tp), sum(frags_area(tp))/fresco_nb_pixels*100.0), verbose);
            msg(sprintf('+ nb truly not placed frags (TN)  -> %d (cover rate w.r.t. image=%.2f%%)', numel(tn), sum(frags_area(tn))/fresco_nb_pixels*100.0), verbose);
            msg(sprintf('+ nb missing frags (FN)           -> %d (cover rate w.r.t. image=%.2f%%)', numel(fn), sum(frags_area(fn))/fresco_nb_pixels*100.0), verbose);
            msg(sprintf('+ nb inaccurately placed frags    -> %d (cover rate w.r.t. image=%.2f%%)', numel(ina), sum(frags_area(ina))/fresco_nb_pixels*100.0), verbose);
            msg(sprintf('+ accuracy                        -> %.2f%%', accuracy), verbose);
            msg(sprintf('+ f-measure                       -> %.2f%%', f_measure), verbose);
        end

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
