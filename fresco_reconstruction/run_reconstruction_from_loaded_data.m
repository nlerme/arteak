% This function runs fresco reconstruction from loaded data (fresco, fragments, parameters, etc.)
% 
% Inputs:
%   * im_fresco_color:        color image of fresco (non empty uint8 matrix)
%   * im_fresco_alpha:        alpha image of fresco (non empty uint8 matrix)
%   * frags_infos:            collection of fragments (non empty cell array)
%   * general_parameters:     general parameters for reconstruction (cell array)
%   * init_parameters:        init parameters for reconstruction (cell array)
%   * mpp_parameters:         mpp parameters for reconstruction (cell array)
%   * gen_parameters:         parameters used for generating fresco (cell array)
%   * geometric_constraints:  constraints used for the placement of fragments (struct)
% 
% Outputs:
%   * final_frags_sol:  resulting fragments of the reconstructed fresco (cell array)
function final_frags_sol = run_reconstruction_from_loaded_data( im_fresco_color, im_fresco_alpha, frags_infos, general_parameters, ...
                                                                init_parameters, mpp_parameters, gen_parameters, geometric_constraints )
    % We set some useful variables
    show_figures              = get_parameter_value(general_parameters, 'show_figures');
    background_color          = get_parameter_value(general_parameters, 'background_color');
    results_dir               = get_parameter_value(general_parameters, 'results_dir');
    gt_dir                    = get_parameter_value(general_parameters, 'gt_dir');
    verbose                   = get_parameter_value(general_parameters, 'verbose');
    save_ground_truth_results = get_parameter_value(general_parameters, 'save_ground_truth_results');
    translation_tolerance     = get_parameter_value(general_parameters, 'translation_tolerance');
    angle_tolerance           = get_parameter_value(general_parameters, 'angle_tolerance');
    save_intermediate_results = get_parameter_value(general_parameters, 'save_intermediate_results');
    interpolation_type        = get_parameter_value(general_parameters, 'interpolation_type');
    recompute_preprocessing   = get_parameter_value(general_parameters, 'recompute_preprocessing');
    recompute_init            = get_parameter_value(init_parameters, 'recompute_init');
    recompute_mpp             = get_parameter_value(mpp_parameters, 'recompute_mpp');
    frags_overlap_tolerance   = get_parameter_value(mpp_parameters, 'fragments_overlap_tolerance');
    true_frags_fn             = [gt_dir filesep 'fragments.txt'];
    neighbors_fn              = [gt_dir filesep 'neighbors.txt'];
    preprocessing_data_fn     = [results_dir filesep 'preprocessing.mat'];
    init_data_fn              = [results_dir filesep 'init.mat'];
    mpp_data_fn               = [results_dir filesep 'mpp.mat'];
    fresco_nb_pixels          = numel(im_fresco_alpha);

    % We create the results directory if necessary
    if ~isfolder(results_dir)
        mkdir(results_dir);
    end

    % Firstly, we preprocess fragment images if asked or needed
    if recompute_preprocessing || ~isfile(preprocessing_data_fn)
        % Message
        msg(sprintf('+ preprocessing fragments'), verbose);

        % Starting timer
        ttt = tic;

        % We loop over fragment images and preprocess them
        nearby_frags_gap  = gen_parameters.nearby_frags_gap;
        final_frags_infos = cell(1, numel(frags_infos));

        parfor k=1:numel(final_frags_infos)
            % We get previously loaded fragment image
            im_frag_color = frags_infos{k}.color;
            im_frag_alpha = frags_infos{k}.alpha;

            % We pad fragment image with zeros
            im_frag_color = padarray(im_frag_color, [1,1], 'both');
            im_frag_alpha = padarray(im_frag_alpha, [1,1], 'both');

            % We correct image intensities near fragment boundary due to interpolation
            for c=1:size(im_frag_color,3)
                im_tmp = double(im_frag_color(:,:,c));
                fresco_idx_t = find(im_frag_alpha>0);
                im_tmp(fresco_idx_t) = (255.0*im_tmp(fresco_idx_t)./(1+double(im_frag_alpha(fresco_idx_t))));
                im_frag_color(:,:,c) = uint8(im_tmp);
            end

            % We threshold alpha channel to ensure that it is a binary image and compute its area
            im_frag_alpha = (im_frag_alpha>0);
            frag_area     = sum(im_frag_alpha(:));

            % We compute inscribed and circumscribed circles
            [outer_circle_center,outer_circle_radius] = get_outer_circle(im_frag_alpha, 200, false); % nb_iterations = 200
            [inner_circle_center,inner_circle_radius] = get_inner_circle(im_frag_alpha, outer_circle_center);

            % If the fragment is too small, we pad it again and update centers of circles
            extrapolation_distance = max(5, 3*nearby_frags_gap); % extrapolation gap (must be larger than nearby_frags_gap)
            margin                 = (2*extrapolation_distance); % overall gap (must be larger than 2*extrapolation_distance)
            d                      = get_largest_distance(inner_circle_center, im_frag_alpha);
            fs                     = round(d+margin-0.5*min(size(im_frag_alpha)));

            if fs>0
                padding             = double([fs,fs]);
                im_frag_color       = padarray(im_frag_color, padding, 'both');
                im_frag_alpha       = padarray(im_frag_alpha, padding, 'both');
                inner_circle_center = inner_circle_center + padding;
                outer_circle_center = outer_circle_center + padding;
            end

            % We shift fragment to the inner circle center for convenience
            frag_size           = size(im_frag_alpha);
            offset              = round(0.5*frag_size)-inner_circle_center;
            im_frag_alpha       = imtranslate(im_frag_alpha, flip(offset), 'method', interpolation_type);
            im_frag_color       = imtranslate(im_frag_color, flip(offset), 'method', interpolation_type);
            outer_circle_center = outer_circle_center-inner_circle_center+round(0.5*frag_size);
            inner_circle_center = round(0.5*frag_size);

            % We compute eroded and dilated fragment domains
            im_frag_alpha_e = imerode(im_frag_alpha, strel('disk', round(frags_overlap_tolerance), 0));
            im_frag_alpha_d = imdilate(im_frag_alpha, strel('disk', round(extrapolation_distance), 0));

            % We do extrapolation on grayscale fragment image
            im_frag_color_ext          = im2double(inpaintExemplar(im_frag_color, ~im_frag_alpha, 'FillOrder', 'tensor', 'PatchSize', [5,5]));
            im_frag_gray_ext           = rgb2gray(im_frag_color_ext);
            im_frag_gray               = im2double(rgb2gray(im_frag_color));
            frag_idx                   = find(im_frag_alpha_d==0);
            im_frag_gray_ext(frag_idx) = 0;

            for c=1:size(im_frag_color,3)
                im_tmp = im_frag_color_ext(:,:,c);
                im_tmp(frag_idx) = 0;
                im_frag_color_ext(:,:,c) = im_tmp;
            end
            imwrite(im_frag_color_ext, sprintf('im_frag_ext_%04d.png', k));
            %imwrite(im_frag_color, sprintf('im_frag_%04d.png', k));

            % We compute gradients of grayscale extrapolated fragment image
            [im_frag_gray_ext_grad_x,im_frag_gray_ext_grad_y] = imgradientxy(im_frag_gray_ext, 'sobel');

            % We compute nearest-neighbor transform to the domain of the fragment
            [~,im_frag_alpha_nn]                  = bwdist(im_frag_alpha, 'euclidean');
            [im_frag_alpha_nny,im_frag_alpha_nnx] = ind2sub(size(im_frag_alpha_nn), im_frag_alpha_nn);

            % We compute mean standard deviation of fragment
            [rows,cols]      = find(im_frag_alpha);
            coords           = [rows,cols];
            frag_intensities = get_intensities(im_frag_color, coords, interpolation_type);
            frag_std         = mean(std(frag_intensities, 0, 1));

            % We get pixel coordinates of eroded and dilated fragment domains
            [rows,cols] = find(im_frag_alpha_d);
            coords_d    = [rows,cols];
            [rows,cols] = find(im_frag_alpha_e);
            coords_e    = [rows,cols];

            % We add the fragment to the list
            frag_info = struct('alpha', im_frag_alpha, 'alpha_d', im_frag_alpha_d, 'alpha_e', im_frag_alpha_e, 'color', im_frag_color, 'gray', im_frag_gray, 'color_ext', im_frag_color_ext, 'gray_ext', im_frag_gray_ext, ...
                               'nny', im_frag_alpha_nny, 'nnx', im_frag_alpha_nnx, 'gray_ext_grad_x', im_frag_gray_ext_grad_x, 'gray_ext_grad_y', im_frag_gray_ext_grad_y, ...
                               'area', frag_area, 'std', frag_std, 'size', frag_size, 'outer_circle_center', outer_circle_center, 'outer_circle_radius', outer_circle_radius, ...
                               'inner_circle_center', inner_circle_center, 'inner_circle_radius', inner_circle_radius, 'offset', offset, ...
                               'coords', coords, 'coords_d', coords_d, 'coords_e', coords_e, 'extrapolation_distance', extrapolation_distance);

            final_frags_infos{k} = frag_info;

            % Message
            msg(sprintf('  + fragment %d/%d | size=(%d,%d), area=%d, std=%f, inner circle=(%d,%d)|%.2f, outer circle=(%.2f,%.2f)|%.2f', ...
                        k, numel(frags_infos), frag_size, frag_area, frag_std, inner_circle_center, inner_circle_radius, outer_circle_center, outer_circle_radius), verbose);
        end

        % Stopping timer
        preprocessing_time = toc(ttt);

        msg('  -----------------------------------------------', verbose);
        msg(sprintf('  * running time -> %.2f', preprocessing_time), verbose);

        % We save results
        if save_intermediate_results
            save(preprocessing_data_fn, 'final_frags_infos', 'preprocessing_time', '-v7.3');
        end
    else
        msg('+ loading preprocessed fragments', verbose);
        load(preprocessing_data_fn, 'final_frags_infos', 'preprocessing_time');
    end

    % We check if ground truth is available
    if ~isfile(true_frags_fn) || ~isfile(neighbors_fn)
        frags_gt                      = {};
        true_frags_idx                = [];
        spurious_frags_idx            = [];
        true_frags_cover_rate         = [];
        spurious_frags_cover_rate     = [];
        all_frags_idx                 = [];
    else
        % If so, we load it
        msg('+ loading ground truth', verbose);
        [id,tx,ty,angles] = textread(true_frags_fn, '%d %f %f %f');

        if numel(id)~=numel(tx) || numel(id)~=numel(ty) || numel(id)~=numel(angles)
            error('The format of the ground truth file is incorrect');
        end

        frags_gt       = cell(1,numel(id));
        true_frags_idx = [];

        parfor k=1:numel(id)
            idx = id(k)+1;

            if idx>numel(final_frags_infos)
                continue;
            end

            angle               = -angles(k); % CAUTION: OPPOSITE ANGLE IS TAKEN
            q                   = apply_forward_transform(final_frags_infos{idx}.offset, [0,0], angle, [0,0]);
            translation         = [ty(k),tx(k)]-q;
            fs                  = round(0.5*final_frags_infos{idx}.size);
            inner_circle_center = round(apply_forward_transform([0,0], translation, angle, [0,0]));
            inner_circle_radius = final_frags_infos{idx}.inner_circle_radius;
            outer_circle_center = round(apply_forward_transform(final_frags_infos{id(k)+1}.outer_circle_center, translation, angle, fs));
            outer_circle_radius = final_frags_infos{idx}.outer_circle_radius;
            frags_gt{k}         = struct('idx', idx, 'translation', translation, 'angle', angle, 'inner_circle_center', inner_circle_center, ...
                                         'inner_circle_radius', inner_circle_radius, 'outer_circle_center', outer_circle_center, ...
                                         'outer_circle_radius', outer_circle_radius, 'neighbors', [], 'color_idx', 3, 'fresco_coords', [], 'frag_coords', []);
            true_frags_idx      = [true_frags_idx,id(k)+1];

            msg(sprintf('  + fragment | id=%d, translation=(%d,%d), angle=%f, inner circle=(%d,%d)|%.2f, outer circle=(%.2f,%.2f)|%.2f', ...
                        idx, translation, angle, inner_circle_center, inner_circle_radius, outer_circle_center, outer_circle_radius), verbose);
        end

        % We load neighboring relationships
        if isfile(neighbors_fn)
            msg('  + loading neighboring relationships', verbose);

            [neighbors1,neighbors2] = textread(neighbors_fn, '%d %d');
            neighbors1              = neighbors1 + 1;
            neighbors2              = neighbors2 + 1;

            if numel(neighbors1)~=numel(neighbors2)
                error('Arrays neighbors1 and neighbors2 must be of the same size');
            end

            for k=1:numel(frags_gt)
                %msg(sprintf('  + fragment | id=%d', frags_gt{k}.idx), verbose);

                idx_n     = neighbors2(find(neighbors1==frags_gt{k}.idx));
                neighbors = [];

                for i=1:numel(idx_n)
                    j = find(cellfun(@(x) x.idx, frags_gt)==idx_n(i));
    
                    if numel(j)==1 && j>=1 && j<=numel(frags_gt)
                        neighbors = [neighbors,j];
                    end
                end

                frags_gt{k}.neighbors = neighbors;
            end
        end

        all_frags_idx      = 1:numel(final_frags_infos);
        spurious_frags_idx = setdiff(all_frags_idx, true_frags_idx);

        all_frags_areas = cellfun(@(x) x.area, final_frags_infos);

        all_frags_cover_rate      = sum(all_frags_areas)/fresco_nb_pixels*100.0;
        true_frags_cover_rate     = sum(all_frags_areas(true_frags_idx))/fresco_nb_pixels*100.0;
        spurious_frags_cover_rate = sum(all_frags_areas(spurious_frags_idx))/fresco_nb_pixels*100.0;

        msg('  --------------------------------------------------------', verbose);
        msg(sprintf('  * true fragments     -> cardinality=%d, cover rate=%.2f%% (w.r.t. image)', numel(true_frags_idx), true_frags_cover_rate), verbose);
        msg(sprintf('  * spurious fragments -> cardinality=%d, cover rate=%.2f%% (w.r.t. image)', numel(spurious_frags_idx), spurious_frags_cover_rate), verbose);
        msg(sprintf('  * all fragments      -> cardinality=%d, cover rate=%.2f%% (w.r.t. image)', numel(all_frags_idx), all_frags_cover_rate), verbose);
        msg('  --------------------------------------------------------', verbose);

        % Ground truth results
        if save_ground_truth_results
            msg('  + saving ground truth results', verbose);
            [~,im_rec_bnd,im_rec_color] = get_reconstructed_fresco(im_fresco_color, final_frags_infos, frags_gt, interpolation_type, background_color);
            im_rec_bnd                  = uint8((im_rec_bnd>0)*255);

            imwrite(im_rec_bnd, [results_dir filesep 'gt_rec_bnd.png'], 'Alpha', im_fresco_alpha);
            imwrite(im_rec_color, [results_dir filesep 'gt_rec_color.png'], 'Alpha', im_fresco_alpha);
            %imwrite(im_rec_bnd, [results_dir filesep 'gt_rec_bnd.png']);
            %imwrite(im_rec_color, [results_dir filesep 'gt_rec_color.png']);

            fh = show_reconstructed_fresco(im_rec_bnd, frags_gt, [], [], [], [], [], false, false, false, true, true, show_figures);
            fn = [results_dir filesep 'gt_rec_bnd_n.png'];
            saveas(fh, fn);
            system(sprintf('mogrify -trim %s', fn));
            close(fh);

            fh = show_reconstructed_fresco(im_rec_color, frags_gt, [], [], [], [], [], false, false, false, true, true, show_figures);
            fn = [results_dir filesep 'gt_rec_color_n.png'];
            saveas(fh, fn);
            system(sprintf('mogrify -trim %s', fn));
            close(fh);
        end
    end

    %----------------------------------------------------------------------
    %----------------------------------------------------------------------
    %----------------------------------------------------------------------

    % Secondly, we construct the initialization if asked or needed
    if recompute_init || ~isfile(init_data_fn)
        % Message
        msg(sprintf('+ initialization'), verbose);

        % Starting timer
        ttt = tic;
        load(mpp_data_fn, 'mpp_frags_sol');
        init_frags_sol = mpp_frags_sol;

%         if sum(im_fresco_alpha(:))==0
%             % We deal with the case where the fresco image is unavailable
%             msg(sprintf('  + blind placement'), verbose);
%             init_frags_sol = run_init_blind_reconstruction(im_fresco_color, im_fresco_alpha, final_frags_infos, general_parameters, init_parameters, gen_parameters, geometric_constraints, frags_gt);
%         else
%             % We deal with the case where the fresco image is at least partially available
%             msg(sprintf('  + non-blind placement'), verbose);
%             init_frags_sol = run_init_non_blind_reconstruction(im_fresco_color, im_fresco_alpha, final_frags_infos, general_parameters, init_parameters, gen_parameters, geometric_constraints, frags_gt);
%         end

        % The initialization is taken as randomly selected fragments
        %init_frags_sol = run_init_blind_reconstruction(im_fresco_color, im_fresco_alpha, final_frags_infos, general_parameters, init_parameters, gen_parameters, geometric_constraints, frags_gt);

        % Stopping timer
        init_time = toc(ttt);

        % Message
        msg('  -----------------------------------------------', verbose);
        msg(sprintf('  * running time -> %.2f secs', init_time), verbose);

        % Comparison against ground truth
        if ~isempty(frags_gt)
            [tp,fp,tn,fn,accuracy,f_measure,~,~,ina] = compare_solution_to_gt(init_frags_sol, frags_gt, numel(final_frags_infos), translation_tolerance, angle_tolerance);
            msg('  -----------------------------------------------', verbose);
            msg(sprintf('  * nb wrongly placed frags (FP)    -> %d', numel(fp)), verbose);
            msg(sprintf('  * nb accurately placed frags (TP) -> %d', numel(tp)), verbose);
            msg(sprintf('  * nb truly not placed frags (TN)  -> %d', numel(tn)), verbose);
            msg(sprintf('  * nb missing frags (FN)           -> %d', numel(fn)), verbose);
            msg(sprintf('  * nb inaccurately placed frags    -> %d', numel(ina)), verbose);
            msg(sprintf('  * accuracy                        -> %.2f%%', accuracy), verbose);
            msg(sprintf('  * f-measure                       -> %.2f%%', f_measure), verbose);
        end

        % We save results
        if save_intermediate_results
            % Message
            msg('  -----------------------------------------------', verbose);
            msg('  + saving results', verbose);

            % PNG files
            [~,im_init_rec_bnd,im_init_rec_color] = get_reconstructed_fresco(im_fresco_color, final_frags_infos, init_frags_sol, interpolation_type, background_color);
            im_init_rec_bnd                       = uint8(255*(im_init_rec_bnd>0));
            %imwrite(im_init_rec_bnd, [results_dir filesep 'init_rec_bnd.png'], 'Alpha', im_fresco_alpha);
            %imwrite(im_init_rec_color, [results_dir filesep 'init_rec_color.png'], 'Alpha', im_fresco_alpha);
            imwrite(im_init_rec_bnd, [results_dir filesep 'init_rec_bnd.png']);
            imwrite(im_init_rec_color, [results_dir filesep 'init_rec_color.png']);

            fh = show_reconstructed_fresco(im_init_rec_color, init_frags_sol, tp, fp, tn, fn, ina, false, false, false, false, true, show_figures);
            fn = [results_dir filesep 'init_rec_color_n.png'];
            saveas(fh, fn);
            system(sprintf('mogrify -trim %s', fn));
            close(fh);

            fh = show_reconstructed_fresco(im_init_rec_bnd, init_frags_sol, tp, fp, tn, fn, ina, false, false, false, false, true, show_figures);
            fn = [results_dir filesep 'init_rec_bnd_n.png'];
            saveas(fh, fn);
            system(sprintf('mogrify -trim %s', fn));
            close(fh);

            % MAT file
            save(init_data_fn, 'init_frags_sol', 'init_time', '-v7.3');
        end
    else
        % We load results
        msg(sprintf('+ loading initialization'), verbose);
        load(init_data_fn, 'init_frags_sol', 'init_time');
    end

    %----------------------------------------------------------------------
    %----------------------------------------------------------------------
    %----------------------------------------------------------------------

    % Thirdly, we apply MPP-based optimization to get the final solution
    if recompute_mpp || ~isfile(mpp_data_fn)
        % Message
        msg(sprintf('+ mpp-based optimization'), verbose);

        % Starting timer
        ttt = tic;

        % We run the reconstruction algorithm, whatever the fresco model availability
        mpp_frags_sol = run_mpp_reconstruction(im_fresco_color, im_fresco_alpha, init_frags_sol, final_frags_infos, general_parameters, init_parameters, mpp_parameters, gen_parameters, geometric_constraints, frags_gt);

        % Stopping timer
        mpp_time = toc(ttt);

        % Message
        msg('  -----------------------------------------------', verbose);
        msg(sprintf('  * running time -> %.2f secs', mpp_time), verbose);

        % Comparison against ground truth
       if ~isempty(frags_gt)
           [tp,fp,tn,fn,accuracy,f_measure,~,~,ina] = compare_solution_to_gt(mpp_frags_sol, frags_gt, numel(final_frags_infos), translation_tolerance, angle_tolerance);
           msg('  -----------------------------------------------', verbose);
           msg(sprintf('  * nb wrongly placed frags (FP)    -> %d', numel(fp)), verbose);
           msg(sprintf('  * nb accurately placed frags (TP) -> %d', numel(tp)), verbose);
           msg(sprintf('  * nb truly not placed frags (TN)  -> %d', numel(tn)), verbose);
           msg(sprintf('  * nb missing frags (FN)           -> %d', numel(fn)), verbose);
           msg(sprintf('  * nb inaccurately placed frags    -> %d', numel(ina)), verbose);
           msg(sprintf('  * accuracy                        -> %.2f%%', accuracy), verbose);
           msg(sprintf('  * f-measure                       -> %.2f%%', f_measure), verbose);
       end

        % We save results
        if save_intermediate_results
            % Message
            msg('  -----------------------------------------------', verbose);
            msg('  + saving results', verbose);

            % PNG files
            [~,im_mpp_rec_bnd,im_mpp_rec_color] = get_reconstructed_fresco(im_fresco_color, final_frags_infos, mpp_frags_sol, interpolation_type, background_color);
            im_mpp_rec_bnd                      = uint8(255*(im_mpp_rec_bnd>0));
            %imwrite(im_mpp_rec_bnd, [results_dir filesep 'mpp_rec_bnd.png'], 'Alpha', im_fresco_alpha);
            %imwrite(im_mpp_rec_color, [results_dir filesep 'mpp_rec_color.png'], 'Alpha', im_fresco_alpha);
            imwrite(im_mpp_rec_bnd, [results_dir filesep 'mpp_rec_bnd.png']);
            imwrite(im_mpp_rec_color, [results_dir filesep 'mpp_rec_color.png']);

            %fh = show_reconstructed_fresco(im_mpp_rec_color, mpp_frags_sol, tp, fp, tn, fn, ina, false, false, false, false, true, show_figures);
            %fn = [results_dir filesep 'mpp_rec_color_n.png'];
            %saveas(fh, fn);
            %system(sprintf('mogrify -trim %s', fn));
            %close(fh);

            %fh = show_reconstructed_fresco(im_mpp_rec_bnd, mpp_frags_sol, tp, fp, tn, fn, ina, false, false, false, false, true, show_figures);
            %fn = [results_dir filesep 'mpp_rec_bnd_n.png'];
            %saveas(fh, fn);
            %system(sprintf('mogrify -trim %s', fn));
            %close(fh);

            % MAT file
            %save(mpp_data_fn, 'mpp_frags_sol', 'mpp_time', '-v7.3');
        end
    else
        % We load results
        msg(sprintf('+ loading mpp solution'), verbose);
        load(mpp_data_fn, 'mpp_frags_sol', 'mpp_time');
    end

    final_frags_sol = mpp_frags_sol;
    return;

    %----------------------------------------------------------------------
    %----------------------------------------------------------------------
    %----------------------------------------------------------------------

    % Message
    msg('+ saving final results', verbose);

    % We save the reconstructed fresco image and fragments
    save_registered_fragments_list(final_frags_sol, final_frags_infos, [results_dir filesep 'fragments.txt']);

    % We save the neighboring relationships between fragments
    save_fragment_neighbors(final_frags_sol, [results_dir filesep 'neighbors.txt']);
end