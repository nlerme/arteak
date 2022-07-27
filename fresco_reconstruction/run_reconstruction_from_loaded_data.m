% This function runs fresco reconstruction from loaded data (fresco, fragments, parameters, etc.)
% 
% Inputs:
%   * im_fresco:              fresco image (non empty RGBA matrix)
%   * frags_infos:            collection of fragments (non empty cell array)
%   * general_parameters:     general parameters for reconstruction (cell array)
%   * init_parameters:        init parameters for reconstruction (cell array)
%   * mpp_parameters:         mpp parameters for reconstruction (cell array)
%   * gen_parameters:         parameters used for generating fresco (cell array)
%   * geometric_constraints:  constraints used for the placement of fragments (struct)
% 
% Outputs:
%   * final_frags_sol:  resulting fragments of the reconstructed fresco (cell array)
function final_frags_sol = run_reconstruction_from_loaded_data( im_fresco, frags_infos, general_parameters, init_parameters, ...
                                                                mpp_parameters, gen_parameters, geometric_constraints )
    % We set some useful variables
    show_figures              = get_parameter_value(general_parameters, 'show_figures');
    background_color          = get_parameter_value(general_parameters, 'background_color');
    results_dir               = get_parameter_value(general_parameters, 'results_dir');
    gt_dir                    = get_parameter_value(general_parameters, 'gt_dir');
    verbose                   = get_parameter_value(general_parameters, 'verbose');
    save_ground_truth_results = get_parameter_value(general_parameters, 'save_ground_truth_results');
    save_intermediate_results = get_parameter_value(general_parameters, 'save_intermediate_results');
    interpolation_type        = get_parameter_value(general_parameters, 'interpolation_type');
    recompute_preprocessing   = get_parameter_value(general_parameters, 'recompute_preprocessing');
    recompute_init            = get_parameter_value(init_parameters, 'recompute_init');
    recompute_mpp             = get_parameter_value(mpp_parameters, 'recompute_mpp');
    true_frags_fn             = [gt_dir filesep 'fragments.txt'];
    neighbors_fn              = [gt_dir filesep 'neighbors.txt'];
    preprocessing_data_fn     = [results_dir filesep 'preprocessing.mat'];
    init_data_fn              = [results_dir filesep 'init.mat'];
    mpp_data_fn               = [results_dir filesep 'mpp.mat'];
    im_fresco_color           = im_fresco(:,:,1:3);
    im_fresco_alpha           = im_fresco(:,:,4);

    % Firstly, we preprocess fragment images if asked or needed
    if recompute_preprocessing || ~isfile(preprocessing_data_fn)
        % Message
        msg(sprintf('+ preprocessing fragments'), verbose);

        % Starting timer
        ttt = tic;

        % We set some useful variables
        nearby_frags_gap = gen_parameters.nearby_frags_gap;
        fresco_nb_pixels = numel(im_fresco_alpha);
        im_fresco_gray   = rgb2gray(im_fresco_color);
        fresco_size      = size(im_fresco_gray);
        nb_channels      = size(im_fresco_color,3);

        % We loop over fragment images and preprocess them
        final_frags_infos = cell(1, numel(frags_infos));

        for k=1:numel(final_frags_infos)
            % We get previously loaded fragment image
            im_frag_color = frags_infos{k}.color;
            im_frag_alpha = frags_infos{k}.alpha;

            % We pad fragment image with zeros
            im_frag_color = padarray(im_frag_color, [1,1], 'both');
            im_frag_alpha = padarray(im_frag_alpha, [1,1], 'both');

            % We threshold alpha channel to ensure that it is a binary image
            im_frag_alpha = (im_frag_alpha>0);

            % We slightly erode the fragment to cope with interpolation issues
            im_frag_alpha = imerode(im_frag_alpha, strel('disk', 1));
            frag_idx      = find(im_frag_alpha==0);

            for c=1:nb_channels
                im_tmp               = im_frag_color(:,:,c);
                im_tmp(frag_idx)     = 0;
                im_frag_color(:,:,c) = im_tmp;
            end

            % We compute area and mean standard deviation of fragment
            interpolation_type = get_parameter_value(general_parameters, 'interpolation_type');
            frag_area_t        = sum(im_frag_alpha(:));
            [rows,cols]        = find(im_frag_alpha);
            frag_int           = get_intensities(im_frag_color, [rows,cols], interpolation_type);
            frag_std           = mean(std(frag_int, 0, 1));

            % We compute inscribed and circumscribed circles
            [outer_circle_center,outer_circle_radius] = get_outer_circle(im_frag_alpha, 200, false); % nb_iterations = 200
            [inner_circle_center,inner_circle_radius] = get_inner_circle(im_frag_alpha, outer_circle_center);

            % If the fragment is too small, we pad it again and update centers of circles
            extrapolation_distance = (3*nearby_frags_gap);       % extrapolation gap (must be larger than 2*mean_inter_fragments_distance)
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

            % We convert fragment image in grayscale levels
            im_frag_gray = im2double(rgb2gray(im_frag_color));

            % We compute the dilated domain of the fragment
            im_frag_alpha_d = imdilate(im_frag_alpha, strel('disk', round(extrapolation_distance)));

            % We do color extrapolation on resulting fragment
            im_frag_color_ext = inpaintExemplar(im2double(im_frag_color), ~im_frag_alpha, 'FillOrder', 'tensor', 'PatchSize', [5,5]);
            frag_idx          = find(im_frag_alpha_d==0);

            for c=1:nb_channels
               im_tmp = im_frag_color_ext(:,:,c);
               im_tmp(frag_idx) = 0;
               im_frag_color_ext(:,:,c) = im_tmp;
            end

            % We convert extrapolated fragment image in grayscale levels
            im_frag_gray_ext = rgb2gray(im_frag_color_ext);

            % We compute gradients of grayscale extrapolated fragment image
            [im_frag_gray_ext_grad_x,im_frag_gray_ext_grad_y] = imgradientxy(im_frag_gray_ext, 'sobel');

            % We compute nearest-neighbor transform to the domain of the fragment
            [~,im_frag_alpha_nn]                  = bwdist(im_frag_alpha, 'euclidean');
            [im_frag_alpha_nny,im_frag_alpha_nnx] = ind2sub(size(im_frag_alpha_nn), im_frag_alpha_nn);

            % We add the fragment to the list
            frag_info = struct('alpha', im_frag_alpha, 'alpha_d', im_frag_alpha_d, 'color', im_frag_color, 'gray', im_frag_gray, 'gray_ext', im_frag_gray_ext, ...
                               'nny', im_frag_alpha_nny, 'nnx', im_frag_alpha_nnx, 'gray_ext_grad_x', im_frag_gray_ext_grad_x, 'gray_ext_grad_y', im_frag_gray_ext_grad_y, 'area', frag_area_t, ...
                               'std', frag_std, 'size', frag_size, 'outer_circle_center', outer_circle_center, 'outer_circle_radius', outer_circle_radius, ...
                               'inner_circle_center', inner_circle_center, 'inner_circle_radius', inner_circle_radius, 'offset', offset);

            final_frags_infos{k} = frag_info;

            % Message
            msg(sprintf('  + fragment %d/%d | size=(%d,%d), area=%d, std=%f, inner circle=(%d,%d)|%.2f, outer circle=(%.2f,%.2f)|%.2f', ...
                        k, numel(frags_infos), frag_size, frag_area_t, frag_std, inner_circle_center, inner_circle_radius, outer_circle_center, outer_circle_radius), verbose);
        end

        % Ending timer
        preprocessing_time = toc(ttt);

        % We save results
        if save_intermediate_results
            save(preprocessing_data_fn, 'im_fresco_color', 'im_fresco_gray', 'fresco_nb_pixels', 'fresco_size', 'final_frags_infos', 'preprocessing_time', '-v7.3');
        end
    else
        msg('+ loading preprocessed fragments', verbose);
        load(preprocessing_data_fn, 'im_fresco_color', 'im_fresco_gray', 'fresco_nb_pixels', 'fresco_size', 'final_frags_infos', 'preprocessing_time');
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

        for k=1:numel(id)
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
            [~,im_rec_gray,im_rec_color] = get_reconstructed_fresco(im_fresco_color, final_frags_infos, frags_gt, interpolation_type, background_color);
            im_rec_gray                  = uint8((im_rec_gray>0)*255);

            imwrite(im_rec_gray, [results_dir filesep 'gt_rec_gray.png']);
            imwrite(im_rec_color, [results_dir filesep 'gt_rec_color.png']);

            fh = show_reconstructed_fresco(im_rec_gray, frags_gt, [], [], [], [], [], false, false, false, true, true, show_figures);
            fn = [results_dir filesep 'gt_rec_gray_n.png'];
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
        msg(sprintf('+ building initialization'), verbose);

        % Starting timer
        ttt = tic;

        if sum(im_fresco_alpha(:))==0
            % We deal with the case where the fresco image is unavailable
            msg(sprintf('  + blind placement'), verbose);
            init_frags_sol = run_init_blind_reconstruction(im_fresco, final_frags_infos, general_parameters, init_parameters, gen_parameters, geometric_constraints, frags_gt);
        else
            % We deal with the case where the fresco image is at least partially available
            msg(sprintf('  + non-blind placement'), verbose);
            init_frags_sol = init_non_blind_reconstruction(im_fresco, final_frags_infos, general_parameters, init_parameters, gen_parameters, geometric_constraints, frags_gt);
        end

        % Ending timer
        init_time = toc(ttt);

        % We save results
        if save_intermediate_results
            % Message
            msg('  + saving results', verbose);

            % PNG files
            [~,im_init_rec_bnd,im_init_rec_color] = get_reconstructed_fresco(im_fresco_color, final_frags_infos, init_frags_sol, interpolation_type, background_color);
            im_init_rec_bnd                       = uint8(255*(im_init_rec_bnd>0));
            imwrite(im_init_rec_bnd, [results_dir filesep 'init_rec_bnd.png'], 'Alpha', im_fresco_alpha);
            imwrite(im_init_rec_color, [results_dir filesep 'init_rec_color.png'], 'Alpha', im_fresco_alpha);

            % MAT file
            init_time = toc(ttt);
            save(init_data_fn, 'init_frags_sol', 'im_init_rec_bnd', 'im_init_rec_color', 'init_time', '-v7.3');
        end
    else
        % We load results
        msg(sprintf('+ loading initialization'), verbose);
        load(init_data_fn, 'init_frags_sol', 'im_init_rec_bnd', 'im_init_rec_color', 'init_time');
    end

    %----------------------------------------------------------------------
    %----------------------------------------------------------------------
    %----------------------------------------------------------------------

%     % Thirdly, we apply MPP-based optimization to get a refined solution
%     if recompute_mpp || ~isfile(mpp_data_fn)
%         % Message
%         msg(sprintf('+ mpp-based optimization'), verbose);
% 
%         % Starting timer
%         ttt = tic;
% 
%         if sum(im_fresco_alpha(:))==0
%             % We deal with the case where the fresco image is unavailable
%             msg(sprintf('  + blind placement'), verbose);
%             frags_sol = run_mpp_blind_reconstruction(im_fresco, init_frags_sol, final_frags_infos, general_parameters, init_parameters, gen_parameters, geometric_constraints, frags_gt);
%         else
%             % We deal with the case where the fresco image is at least partially available
%             msg(sprintf('  + non-blind placement'), verbose);
%             frags_sol = mpp_non_blind_reconstruction(im_fresco, init_frags_sol, final_frags_infos, general_parameters, init_parameters, gen_parameters, geometric_constraints, frags_gt);
%         end
% 
%         % Ending timer
%         mpp_time = toc(ttt);
% 
%         % We save results
%         if save_intermediate_results
%             % Message
%             msg('  + saving results', verbose);
% 
%             % PNG files
%             [~,im_init_rec_bnd,im_init_rec_color] = get_reconstructed_fresco(im_fresco_color, final_frags_infos, init_frags_sol, interpolation_type, background_color);
%             im_init_rec_bnd                       = uint8(255*(im_init_rec_bnd>0));
%             imwrite(im_mpp_rec_bnd, [results_dir filesep 'mpp_rec_bnd.png']), 'Alpha', im_fresco_alpha);
%             imwrite(im_mpp_rec_color, [results_dir filesep 'mpp_rec_color.png'], 'Alpha', im_fresco_alpha);
% 
%             % MAT file
%             mpp_time = toc(ttt);
%             save(mpp_data_fn, 'frags_sol', 'im_mpp_rec_bnd', 'im_mpp_rec_color', 'mpp_time', '-v7.3');
%         end
%     else
%         % We load results
%         msg(sprintf('+ loading mpp solution'), verbose);
%         load(mpp_data_fn, 'mpp_frags_sol', 'im_mpp_rec_bnd', 'im_mpp_rec_color', 'mpp_time');
%     end

    final_frags_sol = init_frags_sol;
end