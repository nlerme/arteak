% This function returns a first guess of fresco reconstruction, when 
% the fresco image is at least partially available.
% 
% Inputs:
%   * im_fresco_color:        color image of fresco (non empty uint8 matrix)
%   * im_fresco_alpha:        alpha image of fresco (non empty logical matrix)
%   * frags_infos:            collection of fragments (cell array with RGBA images)
%   * general_parameters:     value of general parameters (non empty cell array)
%   * init_parameters:        value of init parameters (non empty cell array)
%   * gen_parameters:         value of parameters used for generating the fragmented fresco (non empty struct)
%   * geometric_constraints:  geometric constraints (non empty struct)
%   * frags_gt:               ground truth ([non empty] cell array)
% 
% Outputs:
%   * frags_sol:  solution composed of fragments (cell array)
function frags_sol = run_init_non_blind_reconstruction( im_fresco_color, im_fresco_alpha, frags_infos, general_parameters, init_parameters, gen_parameters, geometric_constraints, frags_gt, verbose )
    % We initialize variables
    interpolation_type          = get_parameter_value(general_parameters, 'interpolation_type');
    verbose                     = get_parameter_value(general_parameters, 'verbose');
    results_dir                 = get_parameter_value(general_parameters, 'results_dir');
    outside_fragment_tolerance  = get_parameter_value(init_parameters, 'outside_fragment_tolerance');
    fragments_overlap_tolerance = get_parameter_value(init_parameters, 'fragments_overlap_tolerance');
    max_cover_rate              = get_parameter_value(init_parameters, 'max_cover_rate');
    frags_sol                   = {};
    fresco_size                 = size(im_fresco_alpha);
    fresco_nb_pixels            = numel(im_fresco_alpha);

    if ~isempty(geometric_constraints.locations) && ~isempty(geometric_constraints.orientations)
        %------------------------------------------------------------------
        % If both locations and orientations are constrained to a finite 
        % subset, we perform exhaustive search
        %------------------------------------------------------------------
        % We compute and stores all costs (#rotations x #fragments x #locations) as L2
        % norm between each fragment and the fresco model (only non-masked areas are 
        % taken into account) without regards to overlapping and non inclusion constraints.
        sizes          = [numel(frags_infos),numel(geometric_constraints.orientations),size(geometric_constraints.locations,1)];
        used           = zeros(1,numel(frags_infos),'logical');
        costs          = -ones(1,prod(sizes));
        nm_areas_size  = cell(1,prod(sizes));

        %----------------------
        %fresco_name   = 'signorelli_71';
        %erosion_level = 2;
        %save_all_ed_terms(im_fresco_color, im_fresco_alpha, frags_infos, general_parameters, init_parameters, geometric_constraints, frags_gt, fresco_name, erosion_level);
        %save_all_esf_terms(frags_infos, general_parameters, init_parameters, geometric_constraints, frags_gt, fresco_name, erosion_level);
        %----------------------

        parfor l=1:numel(costs)
            [i,j,k]     = ind2sub(sizes, l);
            angle       = -geometric_constraints.orientations(j);
            translation = flip(geometric_constraints.locations(k,:));
            frag        = place_fragment(frags_infos, i, translation, angle, {}, im_fresco_color, im_fresco_alpha, interpolation_type, outside_fragment_tolerance, fragments_overlap_tolerance);

            if ~isempty(frag)
                nm_areas_size{l} = [nm_areas_size{l},numel(frag.nm_fresco_intensities)];

                if numel(frag.nm_fresco_intensities)>0
                    % cost between 0 and 1
                    costs(l) = sum((frag.nm_fresco_intensities(:)-frag.nm_frag_intensities(:)).^2) / numel(frag.fresco_intensities);
                    %costs(l) = 1-ssim(frag.nm_fresco_intensities(:), frag.nm_frag_intensities(:));
                    %tmp = corrcoef(frag.nm_fresco_intensities(:), frag.nm_frag_intensities(:));
                    %costs(l) = 1-(tmp(1,2)+1)*0.5;
                else
                    costs(l) = 0;
                end
            end
        end

        nm_areas_size2 = cell(1,size(geometric_constraints.locations,1));

        for l=1:numel(costs)
            [~,~,k]           = ind2sub(sizes, l);
            nm_areas_size2{k} = [nm_areas_size2{k},nm_areas_size{l}];
        end

        mean_nm_areas_size = zeros(1,numel(nm_areas_size2));

        for k=1:numel(mean_nm_areas_size)
            mean_nm_areas_size(k) = mean(nm_areas_size2{k});
        end

        % We sort locations in descending order of their mean non-masked 
        % areas. Then, for each location considered in that order, we select 
        % the rotated fragment with the cheapest cost that does not intersect 
        % with already placed ones and is not part of the reconstruction yet.
        [~,order]  = sort(mean_nm_areas_size, 'descend');
        cover_rate = 0.0;

        for k=order
            if isnan(mean_nm_areas_size(k))
                continue;
            else
                best_cost = realmax;
                best_l    = [];
                best_frag = {};

                for i=find(~used)
                    for j=1:sizes(2)
                        l = sub2ind(sizes, i, j, k);
    
                        if costs(l)>=0 && costs(l)<best_cost
                            angle       = -geometric_constraints.orientations(j);
                            translation = flip(geometric_constraints.locations(k,:));
                            frag        = place_fragment(frags_infos, i, translation, angle, frags_sol, im_fresco_color, im_fresco_alpha, interpolation_type, outside_fragment_tolerance, fragments_overlap_tolerance);
    
                            if ~isempty(frag)
                                best_cost = costs(l);
                                best_l    = l;
                                best_frag = frag;
                            end
                        end
                    end
                end

                if ~isempty(best_l)>0
                    [best_i,~,~]  = ind2sub(sizes, best_l);
                    cover_rate    = cover_rate + (best_frag.area/fresco_nb_pixels);
                    frags_sol     = [frags_sol,{best_frag}];
                    used(best_i)  = 1;
                    %disp(sprintf('frag idx=%d (%d) added | new_cover_rate=%f | sigma(used)=%d', frags{best_l}.idx, best_i, cover_rate, sum(used)));
                end

                if cover_rate>=max_cover_rate
                    break;
                end
            end
        end
    elseif isempty(geometric_constraints.locations) && isempty(geometric_constraints.orientations)
        %------------------------------------------------------------------
        % If both locations and orientations are not constrained to a 
        % finite subset, we perform features based matching
        %------------------------------------------------------------------
        fresco_nb_pixels = prod(fresco_size);
        im_fresco_gray   = rgb2gray(im_fresco_color);

        save_intermediate_results = get_parameter_value(general_parameters, 'save_intermediate_results');

        features_detection_threshold1      = get_parameter_value(init_parameters, 'features_detection_threshold1');
        features_detection_threshold2      = get_parameter_value(init_parameters, 'features_detection_threshold2');
        features_extraction_method         = get_parameter_value(init_parameters, 'features_extraction_method');
        features_matching_threshold        = get_parameter_value(init_parameters, 'features_matching_threshold');
        features_matching_max_ratio        = get_parameter_value(init_parameters, 'features_matching_max_ratio');
        features_matching_fresco_padding   = get_parameter_value(init_parameters, 'features_matching_fresco_padding');
        features_matching_dilation_rate    = get_parameter_value(init_parameters, 'features_matching_dilation_rate');
        color_matching_nb_bins_per_channel = get_parameter_value(init_parameters, 'color_matching_nb_bins_per_channel');
        color_matching_nb_rectangles       = get_parameter_value(init_parameters, 'color_matching_nb_rectangles');
        color_matching_dilation_radius     = get_parameter_value(init_parameters, 'color_matching_dilation_radius');
        color_matching_threshold           = get_parameter_value(init_parameters, 'color_matching_threshold');

        % We compute normalized histogram of fresco image
        msg('    + computing fresco histogram', verbose);
        [fresco_hist,fresco_hist_idx] = get_histogram(im_fresco_color.*uint8(im_fresco_alpha>0), [], color_matching_nb_bins_per_channel);
        fresco_hist_n = (fresco_hist / sum(fresco_hist));

        % For each fragment, we search regions sharing the same color
        msg('    + color matching of fragments', verbose);
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
                        %msg(sprintf('      + fragment %d | OUTSIDE !!!!!!!!!!!!!!!!!!!!!!!', k), verbose);
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
                        %msg(sprintf('      + fragment %d | INSIDE (cover rate=%.2f%%)', k, frag_cover_rate), verbose);
                    end

                    % For debugging
                    %figure, imshow(im_fresco_color,[]);
                    %figure, imshow(im_frag_color,[]);
                else
                    %msg(sprintf('      + fragment %d | UNKNOWN (cover rate=%.2f%%)', k, frag_cover_rate), verbose);
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
        %msg(sprintf('    ----------------------------------'), verbose);
        %msg(sprintf('    [ stats on cover rates of confidence maps ]'), verbose);
        %msg(sprintf('    + mean=%f, std=%f, median=%f', mean(frags_covers_rates), std(frags_covers_rates), median(frags_covers_rates)), verbose);
        %msg(sprintf('    + min=%f, max=%f', min(frags_covers_rates), max(frags_covers_rates)), verbose);

        %---------------------------------------------------------------------------------------------------------------------------------------------
        %---------------------------------------------------------------------------------------------------------------------------------------------
        %---------------------------------------------------------------------------------------------------------------------------------------------

        % We detect and extract features on fresco
        msg('    + detection/extraction of fresco features', verbose);

        im_fresco_mask2 = padarray(im_fresco_alpha>0, [features_matching_fresco_padding,features_matching_fresco_padding], 'both');
        im_fresco_gray2 = padarray(im_fresco_gray, [features_matching_fresco_padding,features_matching_fresco_padding], 'both', 'symmetric');

        fresco_points                    = detectFASTFeatures(im_fresco_gray2, 'MinContrast', features_detection_threshold1, 'MinQuality', features_detection_threshold2);
        [fresco_features,fresco_points2] = extractFeatures(im_fresco_gray2, fresco_points, 'method', features_extraction_method);
        [fresco_points2,fresco_features] = filter_keypoints_and_features(im_fresco_mask2, fresco_points2, fresco_features);
        fresco_points2.Location          = fresco_points2.Location-features_matching_fresco_padding;

        % We detect and extract features on fragments
        msg('    + detection/extraction of fragment features', verbose);
        results = cell(1,numel(frags_infos));

        for k=1:numel(results)
            %msg(sprintf('      + fragment %d', k), verbose);

            % We convert fragment image to grayscale levels
            frag_info    = frags_infos{k};
            im_frag_gray = rgb2gray(frag_info.color);

            % We slightly erode fragment and do color extrapolation
            im_frag_alpha = imerode(frag_info.alpha, strel('disk', 1, 0));
            im_frag_gray2 = extend_image_borders(im_frag_alpha, im_frag_gray);

            % We detect features
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
        msg('    + placement of the fragments', verbose);
        [nb,idx] = sort(cellfun(@(x) x.nb_tform_points, results), 'descend');
        frags_order = idx(nb>0);

        matched_frags_idx     = []; % Fragments placed
        unmatched_frags_idx   = []; % Fragments having matching problems
        outside_frags_idx     = []; % Fragments outside fresco
        overlapping_frags_idx = []; % Fragments overlapping with other ones

        frags_sol  = {};
        cover_rate = 0.0;

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
                %msg(sprintf('      + fragment %d | FAIL (matching problem)', kk), verbose);
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
                %msg(sprintf('      + fragment %d | FAIL (outside fresco)', kk), verbose);
                outside_frags_idx = [outside_frags_idx,kk];
                continue;
            end

            % We check if the registered fragment does not intersect with neighboring ones
            if fragments_overlap_tolerance<1
                no_intersections = 1;

                for i=1:numel(frags_sol)
                    fresco_coords2 = frags_sol{i}.fresco_coords;
                    oc_center2     = frags_sol{i}.outer_circle_center;
                    oc_radius2     = frags_sol{i}.outer_circle_radius;

                    if are_fragments_intersected(fresco_coords_t, oc_center_t, oc_radius_t, fresco_coords2, oc_center2, oc_radius2, fragments_overlap_tolerance)
                        no_intersections = 0;
                        break;
                    end
                end

                if ~no_intersections
                    %msg(sprintf('      + fragment %d | FAIL (intersect with other fragments)', kk), verbose);
                    overlapping_frags_idx = [overlapping_frags_idx,kk];
                    continue;
                end
            end

            % We add fragment to the list
            cover_rate        = cover_rate + (frag_area_t / fresco_nb_pixels);
            matched_frags_idx = [matched_frags_idx,kk];
            init_frag         = struct('idx', kk, 'translation', translation, 'angle', angle, 'area', frag_area_t, ...
                                       'fresco_coords', fresco_coords_t, 'frag_coords', frag_coords_t, ...
                                       'inner_circle_center', ic_center_t, 'outer_circle_center', oc_center_t, ...
                                       'inner_circle_radius', ic_radius_t, 'outer_circle_radius', oc_radius_t, 'neighbors', [], 'color_idx', []);
            frags_sol         = [frags_sol,{init_frag}];

%             if isempty(frags_gt)
%                 msg(sprintf('      + fragment %d | UNKNOWN', kk), verbose);
%             else
%                 % We compare the parameters of the estimated geometric transform against ground truth (if available)
%                 idx = is_fragment_in_gt(frags_gt, kk);
% 
%                 if isempty(idx)
%                     msg(sprintf('      + fragment %d | WRONGLY PLACED', kk), verbose);
%                 else
%                     if is_fragment_identical_to_gt(init_frag, frags_gt{idx}, translation_tolerance, angle_tolerance)
%                         msg(sprintf('      + fragment %d | ACCURATELY PLACED', kk), verbose);
%                     else
%                         msg(sprintf('      + fragment %d | INACCURATELY PLACED', kk), verbose);
%                     end
%                 end
%             end

            if cover_rate>=max_cover_rate
                break;
            end
        end

%         % Evaluation w.r.t. ground truth
%         if isempty(frags_gt)
%             tp        = [];
%             fp        = [];
%             tn        = [];
%             fn        = [];
%             accuracy  = [];
%             f_measure = [];
%             ina       = [];
%         else
%             [tp,fp,tn,fn,accuracy,f_measure,~,~,ina] = compare_solution_to_gt(frags_sol, frags_gt, numel(frags_infos), translation_tolerance, angle_tolerance);
%         end
% 
%         % Counting
%         frags_area = cellfun(@(x) x.area, frags_infos);
% 
%         msg('    -----------------------------------------------', verbose);
%         msg(sprintf('    + nb matched frags     -> %d (cover rate w.r.t. image=%.2f%%)', numel(matched_frags_idx), sum(frags_area(matched_frags_idx))/fresco_nb_pixels*100.0), verbose);
%         msg(sprintf('    + nb unmatched frags   -> %d (cover rate w.r.t. image=%.2f%%)', numel(unmatched_frags_idx), sum(frags_area(unmatched_frags_idx))/fresco_nb_pixels*100.0), verbose);
%         msg(sprintf('    + nb outside frags     -> %d (cover rate w.r.t. image=%.2f%%)', numel(outside_frags_idx), sum(frags_area(outside_frags_idx))/fresco_nb_pixels*100.0), verbose);
%         msg(sprintf('    + nb overlapping frags -> %d (cover rate w.r.t. image=%.2f%%)', numel(overlapping_frags_idx), sum(frags_area(overlapping_frags_idx))/fresco_nb_pixels*100.0), verbose);

%         % Print evaluation w.r.t. ground truth
%         if ~isempty(frags_gt)
%             msg('-----------------------------------------------', verbose);
%             msg(sprintf('+ nb wrongly placed frags (FP)    -> %d (cover rate w.r.t. image=%.2f%%)', numel(fp), sum(frags_area(fp))/fresco_nb_pixels*100.0), verbose);
%             msg(sprintf('+ nb accurately placed frags (TP) -> %d (cover rate w.r.t. image=%.2f%%)', numel(tp), sum(frags_area(tp))/fresco_nb_pixels*100.0), verbose);
%             msg(sprintf('+ nb truly not placed frags (TN)  -> %d (cover rate w.r.t. image=%.2f%%)', numel(tn), sum(frags_area(tn))/fresco_nb_pixels*100.0), verbose);
%             msg(sprintf('+ nb missing frags (FN)           -> %d (cover rate w.r.t. image=%.2f%%)', numel(fn), sum(frags_area(fn))/fresco_nb_pixels*100.0), verbose);
%             msg(sprintf('+ nb inaccurately placed frags    -> %d (cover rate w.r.t. image=%.2f%%)', numel(ina), sum(frags_area(ina))/fresco_nb_pixels*100.0), verbose);
%             msg(sprintf('+ accuracy                        -> %.2f%%', accuracy), verbose);
%             msg(sprintf('+ f-measure                       -> %.2f%%', f_measure), verbose);
%         end
    elseif isempty(geometric_constraints.locations) && ~isempty(geometric_constraints.orientations)
        %------------------------------------------------------------------
        % If locations are not constrained but orientations are, we perform
        % maximum correlation with masked images. (TODO)
        %------------------------------------------------------------------
        disp('error: this part of the software is not implemented yet');
        frags_sol = {};
    elseif ~isempty(geometric_constraints.locations) && isempty(geometric_constraints.orientations)
        %------------------------------------------------------------------
        % If orientations are not constrained but locations are, we perform
        % gradient descent. (TODO)
        %------------------------------------------------------------------
        disp('error: this part of the software is not implemented yet');
        frags_sol = {};
    end

    % We erase fields containing pixel coordinates to ensure that they will only be devoted to the fresco reconstruction
    for k=1:numel(frags_sol)
        frags_sol{k}.fresco_coords = [];
        frags_sol{k}.frag_coords   = [];
    end
end

function save_all_ed_terms( im_fresco_color, im_fresco_alpha, frags_infos, general_parameters, init_parameters, geometric_constraints, frags_gt, fresco_name, erosion_level )
    % We normalize intensities of fragment and fresco images
    im_fresco_color = im2double(im_fresco_color);

    for k=1:numel(frags_infos)
        frags_infos{k}.color = im2double(frags_infos{k}.color);
    end

    % We get the value of some parameters
    translation_tolerance       = get_parameter_value(general_parameters, 'translation_tolerance');
    angle_tolerance             = get_parameter_value(general_parameters, 'angle_tolerance');
    outside_fragment_tolerance  = get_parameter_value(init_parameters, 'outside_fragment_tolerance');
    fragments_overlap_tolerance = get_parameter_value(init_parameters, 'fragments_overlap_tolerance');
    interpolation_type          = get_parameter_value(general_parameters, 'interpolation_type');
    verbose                     = get_parameter_value(general_parameters, 'verbose');
    sizes                       = [numel(frags_infos),numel(geometric_constraints.orientations),size(geometric_constraints.locations,1)];

    % We loop over all acceptable configurations
    %ttt = tic;
    msg('[ computing all acceptable E_d terms ]', verbose);

    frag_intensities_tf   = {}; % true fragment
    fresco_intensities_tf = {}; % true fragment
    frag_intensities_ff   = {}; % false fragment
    fresco_intensities_ff = {}; % false fragment

    parfor l=1:prod(sizes)
        [i,j,k]     = ind2sub(sizes, l);
        angle       = -geometric_constraints.orientations(j);
        translation = flip(geometric_constraints.locations(k,:));
        frag        = place_fragment(frags_infos, i, translation, angle, {}, im_fresco_color, im_fresco_alpha, interpolation_type, outside_fragment_tolerance, fragments_overlap_tolerance);

        if ~isempty(frag) && numel(frag.nm_frag_intensities)>0 && numel(frag.nm_fresco_intensities)>0
            [tp,~,~,~,~,~,~,~,~] = compare_solution_to_gt({frag}, frags_gt, numel(frags_infos), translation_tolerance, angle_tolerance);

            if ~isempty(tp)
                frag_intensities_tf   = [frag_intensities_tf,{frag.nm_frag_intensities}];
                fresco_intensities_tf = [fresco_intensities_tf,{frag.nm_fresco_intensities}];
            else
                frag_intensities_ff   = [frag_intensities_ff,{frag.nm_frag_intensities}];
                fresco_intensities_ff = [fresco_intensities_ff,{frag.nm_fresco_intensities}];
            end
        end
    end

    %numel(frag_intensities_tf)
    %numel(fresco_intensities_tf)
    %numel(frag_intensities_ff)
    %numel(fresco_intensities_ff)
    save(sprintf('new_results/%s_ed_%d.mat', fresco_name, erosion_level), '-v7.3', 'frag_intensities_tf', 'fresco_intensities_tf', 'frag_intensities_ff', 'fresco_intensities_ff');
    %msg(sprintf('[ running time -> %f ]', toc(ttt)), verbose);
end

function save_all_esf_terms( frags_infos, general_parameters, init_parameters, geometric_constraints, frags_gt, fresco_name, erosion_level )
    % We normalize intensities of fragment and fresco images
    for k=1:numel(frags_infos)
        frags_infos{k}.color = im2double(frags_infos{k}.color);
    end

    % We get the value of some parameters
    translation_tolerance = get_parameter_value(general_parameters, 'translation_tolerance');
    angle_tolerance       = get_parameter_value(general_parameters, 'angle_tolerance');
    interpolation_type    = get_parameter_value(general_parameters, 'interpolation_type');
    verbose               = get_parameter_value(general_parameters, 'verbose');
    sizes                 = [numel(frags_infos),numel(geometric_constraints.orientations),size(geometric_constraints.locations,1)];

    % We loop over all acceptable configurations
    %ttt = tic;
    msg('[ computing all acceptable E_sf terms ]', verbose);

    frag_i_intensities_tn = {}; % true neighbors i
    frag_j_intensities_tn = {}; % true neighbors j
    frag_i_intensities_fn = {}; % false neighbors i
    frag_j_intensities_fn = {}; % false neighbors j

    for i=1:sizes(1)
        ii                  = find(cellfun(@(x) x.idx==i, frags_gt));
        frag_i_translation  = frags_gt{ii}.translation;
        frag_i_size         = frags_infos{i}.size;
        frag_i_center       = round(0.5*frag_i_size);
        frag_i_coords_d     = frags_infos{i}.coords_d;
        im_frag_i_color_ext = frags_infos{i}.color_ext;

        for j=1:sizes(1)
            if i==j
                continue;
            end

            if numel(find(frags_gt{ii}.neighbors==j))>0
                jj = frags_gt{ii}.neighbors(find(frags_gt{ii}.neighbors==j));
            else
                jj = frags_gt{ii}.neighbors(1);
            end

            frag_j_translation = frags_gt{jj}.translation;
            frag_j_size        = frags_infos{j}.size;
            frag_j_center      = round(0.5*frag_j_size);
            im_frag_j_alpha_d  = frags_infos{j}.alpha_d;

            for k=1:sizes(2)
                for l=1:sizes(2)
                    frag_i_angle        = -geometric_constraints.orientations(k);
                    frag_j_angle        = -geometric_constraints.orientations(l);
                    im_frag_j_color_ext = frags_infos{j}.color_ext;

                    frag_i_coords_d_Pwj = apply_forward_backward_transforms(frag_i_coords_d, frag_i_translation, frag_i_angle, frag_i_center, frag_j_translation, frag_j_angle, frag_j_center);
                    keep                = find(frag_i_coords_d_Pwj(:,1)>=1 & frag_i_coords_d_Pwj(:,1)<=frag_j_size(1) & frag_i_coords_d_Pwj(:,2)>=1 & frag_i_coords_d_Pwj(:,2)<=frag_j_size(2));
                    frag_i_coords_d_Pwi = frag_i_coords_d(keep,:);
                    frag_i_coords_d_Pwj = frag_i_coords_d_Pwj(keep,:);

                    %++++++++++++++++++++++++++++++++++++++++++++++++++++++
%                     if i==1 && j==8
%                         coords      = round(frag_i_coords_d_Pwj);
%                         idx         = sub2ind(frag_j_size, coords(:,1), coords(:,2));
%                         im_tmp      = zeros(size(im_frag_j_color_ext));
%                         intensities = get_intensities(im_frag_i_color_ext, frag_i_coords_d_Pwi, interpolation_type);
%                         for c=1:size(im_frag_j_color_ext,3)
%                             im_tmp2       = zeros(frag_j_size);
%                             im_tmp2(idx)  = intensities(:,c);
%                             im_tmp(:,:,c) = im_tmp2;
%                         end
%                         figure;
%                         hold on;
%                         subplot(1,3,1);
%                         imshow(im_tmp,[]);
%                         subplot(1,3,2);
%                         imshow(im_frag_j_color_ext,[]);
%                         subplot(1,3,3);
%                         imshow(abs(im_frag_j_color_ext-im_tmp),[]);
%                     end
                    %++++++++++++++++++++++++++++++++++++++++++++++++++++++

                    %--------------------

                    coords              = round(frag_i_coords_d_Pwj);
                    idx                 = sub2ind(frag_j_size, coords(:,1), coords(:,2));
                    keep                = im_frag_j_alpha_d(idx)>0;
                    frag_i_coords_d_Pwi = frag_i_coords_d_Pwi(keep,:);
                    frag_i_coords_d_Pwj = frag_i_coords_d_Pwj(keep,:);

                    %--------------------

                    frag_i_intensities = get_intensities(im_frag_i_color_ext, frag_i_coords_d_Pwi, interpolation_type);
                    frag_j_intensities = get_intensities(im_frag_j_color_ext, frag_i_coords_d_Pwj, interpolation_type);

                    %--------------------

                    frag_i               = struct('idx', i, 'translation', frag_i_translation, 'angle', frag_i_angle);
                    frag_j               = struct('idx', j, 'translation', frag_j_translation, 'angle', frag_j_angle);
                    [tp,~,~,~,~,~,~,~,~] = compare_solution_to_gt({frag_i,frag_j}, frags_gt, numel(frags_infos), translation_tolerance, angle_tolerance);

                    % Two fragments are considered as true positives if 
                    % they are neighbors in the ground truth and their relative
                    % orientation match with each other, i.e. we do not
                    % care about absolute positioning of fragments.
                    if numel(tp)==2
                        frag_i_intensities_tn = [frag_i_intensities_tn,{frag_i_intensities}];
                        frag_j_intensities_tn = [frag_j_intensities_tn,{frag_j_intensities}];
                    else
                        frag_i_intensities_fn = [frag_i_intensities_fn,{frag_i_intensities}];
                        frag_j_intensities_fn = [frag_j_intensities_fn,{frag_j_intensities}];
                    end
                end
            end
        end
    end

    %numel(frag_i_intensities_tn)
    %numel(frag_j_intensities_tn)
    %numel(frag_i_intensities_fn)
    %numel(frag_j_intensities_fn)
    save(sprintf('new_results/%s_esf_%d.mat', fresco_name, erosion_level), '-v7.3', 'frag_i_intensities_tn', 'frag_j_intensities_tn', 'frag_i_intensities_fn', 'frag_j_intensities_fn');
    %msg(sprintf('[ running time -> %f ]', toc(ttt)), verbose);
end