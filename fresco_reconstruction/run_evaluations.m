% Function performing evaluation of all frescoes.
function run_evaluations
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

        % We create a parallel pool if needed
        %if isempty(gcp('nocreate'))
        %    parpool();
        %end

        %----------------------------

        % Variables
        field_names = {'MSAF', ...
                       'MSTF', ...
                       'MSSF', ...
                       'TNF', ...
                       'NTF', ...
                       'RTF', ...
                       'CTF', ...
                       'NSF', ...
                       'RSF', ...
                       'CSF', ...
                       'TP', ...
                       'FP', ...
                       'TN', ...
                       'FN', ...
                       'RCR', ...
                       'ACC', ...
                       'FM', ...
                       'PT', ...
                       'CMT', ...
                       'FMT', ...
                       'TT', ...
                       'MNFMP-PLC', ...
                       'MNFMP-ALL', ...
                       'MTE', ...
                       'MOE', ...
                       'MFC', ...
                       'DFI', ...
                       'MNFFK'};
        field_desc = {'Mean size of all fragments ($>0$)', ...
                      'Mean size of true fragments ($>0$)', ...
                      'Mean size of spurious fragments ($>0$)', ...
                      'Total number of fragments ($\geq 0$)', ...
                      'Number of true fragments in ground truth ($\geq 0$)', ...
                      'Ratio of true fragments in ground truth ($\geq 0$)', ...
                      'Cover of true fragments in ground truth (in $[0,100]$)', ...
                      'Number of spurious fragments in ground truth ($\geq 0$)', ...
                      'Ratio of spurious fragments in ground truth ($\geq 0$)', ...
                      'Cover of spurious fragments in ground truth (in $[0,100]$)', ...
                      'Number of true positives against ground truth ($\geq 0$)', ...
                      'Number of false positives against ground truth ($\geq 0$)', ...
                      'Number of true negatives against ground truth ($\geq 0$)', ...
                      'Number of false negatives against ground truth ($\geq 0$)', ...
                      'Relative cover rate of fragments against ground truth ($>0$)', ...
                      'Accuracy (in $[0,100]$)', ...
                      'F-measure (in $[0,100]$)', ...
                      'Preprocessing time in secs ($\geq 0$)', ...
                      'Color matching time in secs ($\geq 0$)', ...
                      'Features matching time in secs ($\geq 0$)', ...
                      'Total time in secs ($\geq 0$)', ...
                      'Mean number of features matching points among placed fragments ($>0$)', ...
                      'Mean number of features matching points among all fragments ($>0$)', ...
                      'Mean translation error ($>0$)', ...
                      'Mean orientation error ($>0$)', ...
                      'Mean fragments contrast (in $[0,1]$)', ...
                      'Diagonal of fresco image ($>0$)', ...
                      'Mean number of filtered fragment keypoints ($>0$)'};
        translation_tolerance = 10.0; % Tolerance in translation in pixels (>=0)
        angle_tolerance       = 5.0;  % Tolerance in rotation in degrees (in [0,360])
        max_nb_frags          = 5000; % Upper bound on the maximum number of fragments for a fresco (>=0)
        results_root_dir      = ['..' filesep 'new_test_results'];
        %figures_root_dir      = ['..' filesep 'new_test_figures_tt=' num2str(translation_tolerance) '_rt=' num2str(angle_tolerance)];
        figures_root_dir      = ['..' filesep 'foobar_figures'];
        common_tools_dir      = ['..' filesep 'common_tools'];
        verbose               = 0;
        show_figs             = 'on';

        %------------------------------

        % We add required paths recursively
        addpath_recurse(['..' filesep 'common_tools']);

        % We check if directories exist
        dirs1                = get_matching_dirs(results_root_dir, '.*');
        fresco_names         = {};
        config_names         = {};
        all_measurements     = [];
        all_sum_measurements = [];
        avg_sum_measurements = [];
        all_tr_errors        = [];
        all_ori_errors       = [];

        if ~isdir(results_root_dir)
            disp(sprintf('error: directory %s not found', results_root_dir));
            return;
        end

        if ~isdir(figures_root_dir)
            mkdir(figures_root_dir);
        end

        % We check if field names are all distinct
        if length(field_names)~=length(unique(field_names))
            disp('error: duplicate field names are detected and should be removed');
            return;
        end

        % We check if field names and description are of the same size
        if length(field_names)~=length(field_desc)
            disp('error: the number of field names and field descriptions must be the same');
            return;
        end

        % We run evaluation on each fresco
        %frescoes_range        = 1:length(dirs1);
        frescoes_range = [2,6,7,19,20,30,32];
        nb_configs_per_fresco = zeros(1,length(frescoes_range));

        for i=frescoes_range
            a = split(dirs1{i}, filesep);
            fresco_name = a{end};
            fresco_names = {fresco_names{:},fresco_name};
            disp(sprintf('+ %s (%d/%d)', fresco_name, i, length(frescoes_range)));
            dirs2 = get_matching_dirs(dirs1{i}, '.*');

            if isempty(dirs2)
                nb_configs_per_fresco(i) = 1;

                % If only one configuration is found, we just run evaluation on it
                measurements = run_evaluation(results_root_dir, fresco_name, '', field_names, translation_tolerance, angle_tolerance, max_nb_frags);

                if isempty(measurements)
                    return;
                end

                % We sum measurements
                sum_measurements = summing_measurements(measurements);

                % We print measurements
                print_measurements(field_names, sum_measurements, verbose);

                % We concatenate measurements
                all_measurements     = [all_measurements;measurements];
                all_sum_measurements = [all_sum_measurements;sum_measurements];
                avg_sum_measurements = [avg_sum_measurements;sum_measurements];

                % We extract translation/orientation errors
                tr_errors  = measurements(1,find(strcmp(field_names,'MTE')),:);
                tr_errors  = shiftdim(tr_errors(tr_errors>=0),1);
                tr_errors  = tr_errors*length(tr_errors);
                ori_errors = measurements(1,find(strcmp(field_names,'MOE')),:);
                ori_errors = shiftdim(ori_errors(ori_errors>=0),1);
                ori_errors = ori_errors*length(ori_errors);

                % We concatenate errors
                all_tr_errors    = [all_tr_errors,tr_errors];
                all_ori_errors   = [all_ori_errors,ori_errors];

                % We save distributions of errors
                %save_distribution(tr_errors, 80, 'Localization error (in pixels)', '', [figures_root_dir filesep 'loc_err_dist_' fresco_name '.png'], [], show_figs);
                %save_distribution(ori_errors, 80, 'Orientation error (in degrees)', '', [figures_root_dir filesep 'ori_err_dist_' fresco_name '.png'], [], show_figs);

                % We save individual clouds
                %save_cloud(measurements, field_names, 'MFC', 'MNFFK', 'Fragment contrast', 'Number of filtered fragment keypoints', '', [figures_root_dir filesep 'cloud_mfc_vs_mnffk_' fresco_name '.png'], show_figs);
                %save_cloud(measurements, field_names, 'MSAF', 'MNFFK', 'Fragment size', 'Number of filtered fragment keypoints', '', [figures_root_dir filesep 'cloud_msaf_vs_mnffk_' fresco_name '.png'], show_figs);
            else
                % If multiple configurations are found, we run evaluation on each of them successively
                sum_measurements2        = [];
                tr_errors2               = [];
                ori_errors2              = [];
                %configs_range            = 1:length(dirs2);
                configs_range            = [3];
                nb_configs_per_fresco(i) = length(configs_range);

                for j=configs_range
                    a = split(dirs2{j}, filesep);
                    config_name = a{end};
                    config_names = {config_names{:},config_name};
                    disp(sprintf('  + %s (%d/%d)', config_name, j, length(configs_range)));
                    measurements = run_evaluation(results_root_dir, fresco_name, config_name, field_names, translation_tolerance, angle_tolerance, max_nb_frags);

                    if isempty(measurements)
                        return;
                    end

                    % We sum measurements
                    sum_measurements = summing_measurements(measurements);

                    % We print measurements
                    print_measurements(field_names, sum_measurements, verbose);

                    % We concatenate measurements
                    all_measurements     = [all_measurements;measurements];
                    sum_measurements2    = [sum_measurements2;sum_measurements];
                    all_sum_measurements = [all_sum_measurements;sum_measurements];

                    % We extract translation/orientation errors
                    tr_errors  = measurements(1,find(strcmp(field_names,'MTE')),:);
                    tr_errors  = shiftdim(tr_errors(tr_errors>=0),1);
                    tr_errors  = tr_errors*length(tr_errors);
                    ori_errors = measurements(1,find(strcmp(field_names,'MOE')),:);
                    ori_errors = shiftdim(ori_errors(ori_errors>=0),1);
                    ori_errors = ori_errors*length(ori_errors);

                    % We concatenate errors
                    tr_errors2     = [tr_errors2,tr_errors];
                    ori_errors2    = [ori_errors2,ori_errors];
                    all_tr_errors  = [all_tr_errors,tr_errors];
                    all_ori_errors = [all_ori_errors,ori_errors];

                    % We save distributions of errors
                    %save_distribution(tr_errors, 80, 'Localization error (in pixels)', '', [figures_root_dir filesep 'loc_err_dist_' config_name '.png'], [], show_figs);
                    %save_distribution(ori_errors, 80, 'Orientation error (in degrees)', '', [figures_root_dir filesep 'ori_err_dist_' config_name '.png'], [], show_figs);

                    % We save individual clouds
                    save_cloud(measurements, field_names, 'MFC', 'MNFMP-ALL', 'Fragment contrast', 'Number of matched keypoints', '', [figures_root_dir filesep 'cloud_mfc_vs_mnfmp_' config_name '.png'], show_figs);
                    save_cloud(measurements, field_names, 'MSAF', 'MNFMP-ALL', 'Fragment size', 'Number of matched keypoints', '', [figures_root_dir filesep 'cloud_msaf_vs_mnfmp_' config_name '.png'], show_figs);
                    save_cloud(measurements, field_names, 'MFC', 'MSAF', 'Fragment contrast', 'Fragment size', '', [figures_root_dir filesep 'cloud_mfc_vs_msaf_' config_name '.png'], show_figs);
                end

                % We average available measurements
                m = averaging_measurements(sum_measurements2);

                % We concatenate averaged measurements
                avg_sum_measurements = [avg_sum_measurements;m];

                % We save distributions of errors
                %save_distribution(tr_errors2, 80, 'Localization error (in pixels)', strrep(fresco_name, '_', '-'), [figures_root_dir filesep 'loc_err_dist_' fresco_name '.png'], [], show_figs);
                %save_distribution(ori_errors2, 80, 'Orientation error (in degrees)', strrep(fresco_name, '_', '-'), [figures_root_dir filesep 'ori_err_dist_' fresco_name '.png'], [], show_figs);
            end
        end
        return;

        % We save overall distributions of errors
        save_distribution(all_tr_errors, 80, 'Localization error (in pixels)', '', [figures_root_dir filesep 'overall_translation_error_dist.png'], [0,50], show_figs);
        save_distribution(all_ori_errors, 80, 'Orientation error (in degrees)', '', [figures_root_dir filesep 'overall_orientation_error_dist.png'], [0,20], show_figs);

        % We save measurements (sorted by some field denoted by last parameter)
        prefix_fn = [figures_root_dir filesep 'all_measurements'];
        fields_fn = [figures_root_dir filesep 'fields'];
        save_measurements(config_names, field_names, field_desc, fields_fn, all_sum_measurements, [prefix_fn '_acc'], 'Performance of non-dense assembly per configuration (sorted by ACC).', 'ACC', 'descend');
        save_measurements(config_names, field_names, field_desc, fields_fn, all_sum_measurements, [prefix_fn '_fm'], 'Performance of non-dense assembly per configuration (sorted by FM).', 'FM', 'descend');
        save_measurements(config_names, field_names, field_desc, fields_fn, all_sum_measurements, [prefix_fn '_mte'], 'Performance of non-dense assembly per configuration (sorted by MTE).', 'MTE', 'ascend');
        save_measurements(config_names, field_names, field_desc, fields_fn, all_sum_measurements, [prefix_fn '_moe'], 'Performance of non-dense assembly per configuration (sorted by MOE).', 'MOE', 'ascend');
        save_measurements(config_names, field_names, field_desc, fields_fn, all_sum_measurements, [prefix_fn '_tt'], 'Performance of non-dense assembly per configuration (sorted by TT).', 'TT', 'ascend');
        save_measurements(config_names, field_names, field_desc, fields_fn, all_sum_measurements, [prefix_fn '_rcr'], 'Performance of non-dense assembly per configuration (sorted by RCR).', 'RCR', 'ascend');

        % We save averaged measurements (sorted by some field denoted by last parameter)
        prefix_fn = [figures_root_dir filesep 'avg_measurements'];
        fields_fn = [figures_root_dir filesep 'fields'];
        save_measurements(fresco_names, field_names, field_desc, fields_fn, avg_sum_measurements, [prefix_fn '_acc'], 'Averaged performance of non-dense assembly per fresco (sorted by ACC).', 'ACC', 'descend');
        save_measurements(fresco_names, field_names, field_desc, fields_fn, avg_sum_measurements, [prefix_fn '_fm'], 'Averaged performance of non-dense assembly per fresco (sorted by FM).', 'FM', 'descend');
        save_measurements(fresco_names, field_names, field_desc, fields_fn, avg_sum_measurements, [prefix_fn '_mte'], 'Averaged performance of non-dense assembly per fresco (sorted by MTE).', 'MTE', 'ascend');
        save_measurements(fresco_names, field_names, field_desc, fields_fn, avg_sum_measurements, [prefix_fn '_moe'], 'Averaged performance of non-dense assembly per fresco (sorted by MOE).', 'MOE', 'ascend');
        save_measurements(fresco_names, field_names, field_desc, fields_fn, avg_sum_measurements, [prefix_fn '_tt'], 'Averaged performance of non-dense assembly per fresco (sorted by TT).', 'TT', 'ascend');
        save_measurements(fresco_names, field_names, field_desc, fields_fn, avg_sum_measurements, [prefix_fn '_rcr'], 'Averaged performance of non-dense assembly per fresco (sorted by RCR).', 'RCR', 'ascend');

        % We save box plots
        save_box_plot(all_sum_measurements, nb_configs_per_fresco, field_names, 'ACC', 'ACC (in %)', [figures_root_dir filesep 'box_plot_acc.png'], show_figs);
        save_box_plot(all_sum_measurements, nb_configs_per_fresco, field_names, 'FM', 'FM (in %)', [figures_root_dir filesep 'box_plot_fm.png'], show_figs);
        save_box_plot(all_sum_measurements, nb_configs_per_fresco, field_names, 'MTE', 'MTE (in pixels)', [figures_root_dir filesep 'box_plot_mte.png'], show_figs);
        save_box_plot(all_sum_measurements, nb_configs_per_fresco, field_names, 'MOE', 'MOE (in degrees)', [figures_root_dir filesep 'box_plot_moe.png'], show_figs);
        save_box_plot(all_sum_measurements, nb_configs_per_fresco, field_names, 'TT', 'Overall running time (in secs)', [figures_root_dir filesep 'box_plot_tt.png'], show_figs);
        save_box_plot(all_sum_measurements, nb_configs_per_fresco, field_names, 'RCR', 'RCR (in %)', [figures_root_dir filesep 'box_plot_rcr.png'], show_figs);

        % We save overall clouds
        save_overall_cloud(all_sum_measurements, nb_configs_per_fresco, field_names, 'DFI', 'TNF', 'PT', 'Fresco size (in pixels)', 'Total number of fragments', [figures_root_dir filesep 'running_time_pt.png'], show_figs);
        save_overall_cloud(all_sum_measurements, nb_configs_per_fresco, field_names, 'DFI', 'TNF', 'CMT', 'Fresco size (in pixels)', 'Total number of fragments', [figures_root_dir filesep 'running_time_cmt.png'], show_figs);
        save_overall_cloud(all_sum_measurements, nb_configs_per_fresco, field_names, 'DFI', 'TNF', 'FMT', 'Fresco size (in pixels)', 'Total number of fragments', [figures_root_dir filesep 'running_time_fmt.png'], show_figs);
        save_overall_cloud(all_sum_measurements, nb_configs_per_fresco, field_names, 'DFI', 'TNF', 'TT', 'Fresco size (in pixels)', 'Total number of fragments', [figures_root_dir filesep 'running_time_tt.png'], show_figs);

        % We save and print overall statistics
        save_and_print_overall_stats(all_sum_measurements, field_names, [figures_root_dir filesep 'overall_stats.txt']);
    end

    % Function saving overall clouds
    function save_overall_cloud( measurements, nb_configs_per_fresco, field_names, field_name_x, field_name_y, field_name_z, my_xlabel, my_ylabel, output_fn, show_figs )
        field_idx_x = find(strcmp(field_names, field_name_x));
        field_idx_y = find(strcmp(field_names, field_name_y));
        field_idx_z = find(strcmp(field_names, field_name_z));

        if isempty(field_idx_x) || isempty(field_idx_y) || isempty(field_idx_z)
            return;
        end

        mx = measurements(:,field_idx_x);
        mx = mx(mx>=0);
        my = measurements(:,field_idx_y);
        my = my(my>=0);
        mz = measurements(:,field_idx_z);
        mz = mz(mz>=0);

        if length(mx)~=length(my) || length(mx)~=length(mz) || length(my)~=length(mz)
            return;
        end

%         line_width = 3;
%         font_size = 22;
%         min_size = 100;
%         max_size = 2000;
%         figure('units','normalized','outerposition',[0 0 1 1],'visible',show_figs);
%         hold on;
%         grid;
%         scatter(mx, my, mz/max(mz)*(max_size-min_size)+min_size, 'LineWidth', line_width, 'MarkerEdgeColor', 'k');
%         xlabel(my_xlabel);
%         ylabel(my_ylabel);
%         set(gca, 'FontSize', font_size);
%         set(gca, 'LineWidth', line_width);
%         saveas(gcf, output_fn);
%         system(sprintf('mogrify -trim %s', output_fn));
%         close(gcf);

        %nb_frescoes = length(nb_configs_per_fresco);
        %colors = -ones(1,length(mx));
        %for k=1:nb_frescoes
        %    colors(((k-1)*nb_configs_per_fresco(k)+1):(k*nb_configs_per_fresco(k))) = k;
        %end
        line_width = 4;
        font_size = 22;
        figure('units','normalized','outerposition',[0 0 1 1],'visible',show_figs);
        hold on;
        grid;
        scatter(mx, my, 500, mz, 'LineWidth', line_width);
        colormap jet;
        colorbar;
        xlabel(my_xlabel);
        ylabel(my_ylabel);
        set(gca, 'FontSize', font_size);
        set(gca, 'LineWidth', line_width);
        saveas(gcf, output_fn);
        system(sprintf('mogrify -trim %s', output_fn));
        close(gcf);
    end

    % Function saving box plots
    function save_box_plot( measurements, nb_configs_per_fresco, field_names, field_name, my_ylabel, output_fn, show_figs )
        field_col = find(strcmp(field_names, field_name));

        if isempty(field_col)
            return;
        end

        nb_frescoes    = length(nb_configs_per_fresco);
        min_nb_configs = min(nb_configs_per_fresco);
        measurements2  = [];

        for k=1:nb_frescoes
            m = measurements(((k-1)*min_nb_configs+1):(k*min_nb_configs),field_col);
            measurements2 = [measurements2,m];
        end

        line_width = 3;
        font_size = 22;
        ticks_spacing = 5;
        figure('units','normalized','outerposition',[0 0 1 1],'visible',show_figs);
        hold on;
        grid;
        labels = cell(1,nb_frescoes);
        for k=1:nb_frescoes
            if k==1 || mod(k,ticks_spacing)==0
                labels{k} = num2str(k);
            else
                labels{k} = '';
            end
        end
        h = boxplot(measurements2,num2cell(1:nb_frescoes),'Labels',labels);
        xlabel('Fresco number');
        ylabel(my_ylabel);
        set(gca, 'FontSize', font_size);
        set(gca, 'LineWidth', line_width);
        set(findobj(gca,'type','line'),'linew',3);
        saveas(gcf, output_fn);
        system(sprintf('mogrify -trim %s', output_fn));
        close(gcf);
    end

    % Function saving individual clouds
    function save_cloud( measurements, field_names, field_name_x, field_name_y, my_xlabel, my_ylabel, my_title, output_fn, show_figs )
        field_idx_x = find(strcmp(field_names, field_name_x));
        field_idx_y = find(strcmp(field_names, field_name_y));

        if isempty(field_idx_x) || isempty(field_idx_y)
            return;
        end

        mx = shiftdim(measurements(1,field_idx_x,:),1);
        mx = mx(mx>=0);
        mx = mx*length(mx); % we multiply by the size of the vector to recover the sum of its elements

        my = shiftdim(measurements(1,field_idx_y,:),1);
        my = my(my>=0);
        my = my*length(my); % we multiply by the size of the vector to recover the sum of its elements

        if length(mx)~=length(my)
            return;
        end

        line_width = 3;
        font_size = 22;
        figure('units','normalized','outerposition',[0 0 1 1],'visible',show_figs);
        hold on;
        grid;

        tp_field_idx = find(strcmp(field_names,'TP'));
        fp_field_idx = find(strcmp(field_names,'FP'));
        tn_field_idx = find(strcmp(field_names,'TN'));
        fn_field_idx = find(strcmp(field_names,'FN'));

        if isempty(tp_field_idx) && isempty(fp_field_idx) && isempty(tn_field_idx) && isempty(fn_field_idx)
            plot(mx, my, 'k*', 'MarkerSize', 10, 'LineWidth', line_width);
        else
            labels = {};

            if ~isempty(tp_field_idx)
                tp = find(shiftdim(measurements(1,tp_field_idx,:),1)==1);
                if ~isempty(tp)
                    plot(mx(tp), my(tp), 'g*', 'MarkerSize', 10, 'LineWidth', line_width);
                    labels = {labels{:},'TP'};
                end
            end

            if ~isempty(fp_field_idx)
                fp = find(shiftdim(measurements(1,fp_field_idx,:),1)==1);
                if ~isempty(fp)
                    plot(mx(fp), my(fp), 'r*', 'MarkerSize', 10, 'LineWidth', line_width);
                    labels = {labels{:},'FP'};
                end
            end

            if ~isempty(tn_field_idx)
                tn = find(shiftdim(measurements(1,tn_field_idx,:),1)==1);
                if ~isempty(tn)
                    plot(mx(tn), my(tn), 'c*', 'MarkerSize', 10, 'LineWidth', line_width);
                    labels = {labels{:},'TN'};
                end
            end

            if ~isempty(fn_field_idx)
                fn = find(shiftdim(measurements(1,fn_field_idx,:),1)==1);
                if ~isempty(fn)
                    plot(mx(fn), my(fn), 'm*', 'MarkerSize', 10, 'LineWidth', line_width);
                    labels = {labels{:},'FN'};
                end
            end

            legend(labels);
        end

        if ~isempty(my_title)
            title(my_title);
        end

        xlabel(my_xlabel);
        ylabel(my_ylabel);
        set(gca, 'FontSize', font_size);
        set(gca, 'LineWidth', line_width);
        saveas(gcf, output_fn);
        system(sprintf('mogrify -trim %s', output_fn));
        close(gcf);
    end

    % Function saving distributions
    function save_distribution( occurrences, nb_bins, my_xlabel, my_title, output_fn, my_xlim, show_figs )
        line_width = 3;
        font_size = 22;
        figure('units','normalized','outerposition',[0 0 1 1],'visible',show_figs);
        hold on;
        grid;
        xlabel(my_xlabel);
        ylabel('Number of occurrences');
        if ~isempty(my_title)
            title(my_title);
        end
        if ~isempty(my_xlim)
            occurrences2 = occurrences(occurrences<=my_xlim(2));
            hist(occurrences2, nb_bins);
            xlim(my_xlim);
        else
            hist(occurrences, nb_bins);
        end
        set(gca, 'FontSize', font_size);
        set(gca, 'LineWidth', line_width);
        saveas(gcf, output_fn);
        system(sprintf('mogrify -trim %s', output_fn));
        close(gcf);
    end

    % Function summing measurements
    function m = summing_measurements( measurements )
        m = -ones(1,size(measurements,2));

        for j=1:size(measurements,2)
            a = measurements(1,j,:);
            b = a(a>=0);
            if ~isempty(b)
                m(1,j) = sum(b);
            else
                m(1,j) = nan;
            end
        end
    end

    % Function averaging measurements
    function m = averaging_measurements( measurements )
        m = -ones(1,size(measurements,2));
        for j=1:size(measurements,2)
            a = measurements(:,j);
            b = a(a>=0);
            if ~isempty(b)
                m(j) = mean(b);
            end
        end
    end

    % Function saving measurements in CSV format
    function save_measurements( fresco_names, field_names, field_desc, fields_fn, measurements, measurements_fn, caption, sort_key, sort_order )
        % We sort measurements if needed
        d = find(strcmp(field_names,sort_key));
        if ~isempty(d)
            [~,idx]      = sort(measurements(:,d), sort_order);
            measurements = measurements(idx,:);
            fresco_names = {fresco_names{idx}};
        end

        % We get the number of measurements
        [nb_rows,nb_cols] = size(measurements);

        % We save the fields as a CSV file
        fp = fopen([fields_fn '.csv'], 'w');
        fprintf(fp, 'Field,Description\n');

        for i=1:length(field_names)
            fprintf(fp, '%s,%s\n', field_names{i}, field_desc{i});
        end
        fclose(fp);

        % We save the measurements as a CSV file
        fp = fopen([measurements_fn '.csv'], 'w');
        str = 'NAME,';

        for j=1:nb_cols
            fmt = '%s';
            if j<nb_cols
                fmt = [fmt ','];
            end
            str = [str sprintf(fmt, field_names{j})];
        end

        fprintf(fp, '%s\n', str);

        for i=1:nb_rows
            str = sprintf('%s,', strrep(fresco_names{i}, '_', '-'));

            for j=1:nb_cols
                m = measurements(i,j);
                if m>=0
                    if round(m)==m
                        fmt = '%d';
                    else
                        fmt = '%.2f';
                    end
                    if j<nb_cols
                        fmt = [fmt ','];
                    end
                    str = [str sprintf(fmt, m)];
                else
                    fmt = 'NaN';
                    if j<nb_cols
                        fmt = [fmt ','];
                    end
                    str = [str fmt];
                end
            end

            fprintf(fp, '%s\n', str);
        end

        fclose(fp);

        % We create the LaTeX file including the previous CSV file
        [~,f_d2,~] = fileparts(fields_fn);
        [m_d1,m_d2,~] = fileparts(measurements_fn);
        fp = fopen([measurements_fn '.tex'], 'w');
        fprintf(fp, '\\documentclass[a3paper,10pt]{article}\n');
        fprintf(fp, '\\usepackage[english]{babel}\n');
        fprintf(fp, '\\usepackage[latin1]{inputenc}\n');
        fprintf(fp, '\\usepackage[T1]{fontenc}\n');
        fprintf(fp, '\\usepackage{amsmath,amssymb,csvsimple,booktabs,longtable,pdflscape,geometry}\n');
        fprintf(fp, '\\usepackage[table]{xcolor}\n');
        fprintf(fp, '\\geometry{margin=2cm}\n');
        fprintf(fp, '\\makeatletter\n');
        fprintf(fp, '\\csvset\n');
        fprintf(fp, '{\n');
        fprintf(fp, '    bordered/.style=\n');
        fprintf(fp, '    {\n');
        fprintf(fp, '        after head=\\csv@pretable\\begin{longtable}{|*{\\csv@columncount}{c|}}\\csv@tablehead,\n');
        fprintf(fp, '        table head=\\hline\\csvlinetotablerow\\\\\\hline,\n');
        fprintf(fp, '        late after line=\\\\\\hline,\n');
        fprintf(fp, '        late after last line=\\csv@tablefoot\\end{longtable}\\csv@posttable\n');
        fprintf(fp, '    }\n');
        fprintf(fp, '}\n');
        fprintf(fp, '\\makeatother');
        fprintf(fp, '\\rowcolors{2}{white}{gray!25}\n');
        fprintf(fp, '\\begin{document}\n');
        fprintf(fp, '    \\begin{landscape}\n');
        fprintf(fp, '        \\centering\n');
        fprintf(fp, '        {\\tiny\\csvautolongtable[bordered,table head=\\caption{Retained fields and their meaning.}\\\\\\hline\\csvlinetotablerow\\\\\\hline\\endfirsthead\\hline\\csvlinetotablerow\\\\\\hline\\endhead\\hline\\endfoot]{%s.csv}}\n', f_d2);
        fprintf(fp, '        {\\tiny\\csvautolongtable[bordered,table head=\\caption{%s}\\\\\\hline\\csvlinetotablerow\\\\\\hline\\endfirsthead\\hline\\csvlinetotablerow\\\\\\hline\\endhead\\hline\\endfoot]{%s.csv}}\n', caption, m_d2);
        fprintf(fp, '    \\end{landscape}\n');
        fprintf(fp, '\\end{document}');
        fclose(fp);

        % We run the LaTeX compiler
        system(sprintf('cd %s; pdflatex %s; pdflatex %s; cd -', m_d1, m_d2, m_d2));
    end

    % Function printing measurements on stdout
    function print_measurements( field_names, measurements, verbose )
        if ~verbose
            return;
        end

        for k=1:length(field_names)
            m = measurements(k);
            if m>=0
                if round(m)==m
                    fmt = '%d';
                else
                    fmt = '%.2f';
                end
                disp(sprintf(['    * %s=' fmt], field_names{k}, m));
            else
                disp(sprintf('    * %s=UNDEFINED', field_names{k}));
            end
        end
    end

    % Function saving and printing overall statistics
    function save_and_print_overall_stats( measurements, field_names, output_fn )
        disp('-----------------------------------------------------');
        disp('[ overall statistics ]');
        str = '';

        for k=1:length(field_names)
            m  = measurements(:,k);
            m  = m(m>=0);

            if ~isempty(m)
                s1 = min(m);
                s2 = max(m);
                s3 = median(m);
                s4 = mean(m);
                s5 = std(m);
            else
                s1 = nan;
                s2 = nan;
                s3 = nan;
                s4 = nan;
                s5 = nan;
            end
            a = sprintf('* %s | min=%f, max=%f, median=%f, mean=%f, std=%f', field_names{k}, s1, s2, s3, s4, s5);
            disp(a);
            str = [str,sprintf('%s\n',a)];
        end

        if ~isempty(output_fn)
            fp = fopen(output_fn, 'w');
            fprintf(fp, str);
            fclose(fp);
        end
    end

    % Function returning measurements and translation/orientation errors
    function measurements = run_evaluation( results_root_dir, fresco_name, config_name, field_names, translation_tolerance, angle_tolerance, max_nb_frags )
        % We allocate memory for storing results
        measurements = -ones(1,length(field_names),max_nb_frags);

        % We set directories and filenames
        if ~isempty(config_name)
            results_dir = [results_root_dir filesep fresco_name filesep config_name];
        else
            results_dir = [results_root_dir filesep fresco_name];
        end

        % We load intermediate files (*.mat)
        preprocessing_fn     = [results_dir filesep 'preprocessing.mat'];
        color_matching_fn    = [results_dir filesep 'color_matching.mat'];
        features_matching_fn = [results_dir filesep 'features_matching.mat'];

        if ~isfile(preprocessing_fn) || ~isfile(color_matching_fn) || ~isfile(features_matching_fn)
            disp(sprintf('error: unable to load intermediate files for fresco %s and config %s (*.mat)', fresco_name, config_name));
            measurements = [];
            return;
        end

        pp = load(preprocessing_fn);
        cm = load(color_matching_fn);
        fm = load(features_matching_fn);

        % We compute measurements against ground truth (if available)
        if ~isempty(pp.frags_gt)
            [tp,fp,tn,fn,accuracy,f_measure,tr_errors,ori_errors,~] = compare_solution_to_gt(fm.init_frags_sol, pp.frags_gt, length(pp.frags_infos), translation_tolerance, angle_tolerance);
        end

        % We get area and circumscribed circle radius of fragments
        nb_frags         = length(pp.frags_infos);
        frags_area       = cellfun(@(x) x.area, pp.frags_infos);
        frags_ocr        = cellfun(@(x) x.outer_circle_radius, pp.frags_infos);
        frags_contrast   = cellfun(@(x) x.std, pp.frags_infos)/255;

        % We fill measurements
        for i=1:length(field_names)
            % Mean size of all fragments (MSAF)
            if strcmp(field_names{i},'MSAF')
                measurements(1,i,1:nb_frags) = frags_ocr/nb_frags;
            end

            % Mean size of true fragments (MSTF)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'MSTF') && ~isempty(pp.true_frags_idx)
                measurements(1,i,pp.true_frags_idx) = frags_ocr(pp.true_frags_idx)/length(pp.true_frags_idx);
            end

            % Mean size of spurious fragments (MSSF)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'MSSF') && ~isempty(pp.spurious_frags_idx)
                measurements(1,i,pp.spurious_frags_idx) = frags_ocr(pp.spurious_frags_idx)/length(pp.spurious_frags_idx);
            end

            %--------------------------

            % Total number of fragments (TNF)
            if strcmp(field_names{i},'TNF')
                measurements(1,i,1:nb_frags) = 1;
            end

            % Total cover of fragments (TCF)
            if strcmp(field_names{i},'TCF')
                measurements(1,i,1:nb_frags) = frags_area/pp.fresco_nb_pixels*100.0;
            end

            % Number of true fragments (NTF)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'NTF')
                if ~isempty(pp.true_frags_idx)
                    measurements(1,i,pp.true_frags_idx) = 1;
                else
                    measurements(1,i,:) = 0;
                end
            end

            % Ratio of true fragments (RTF)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'RTF')
                if ~isempty(pp.true_frags_idx)
                    measurements(1,i,pp.true_frags_idx) = 1/nb_frags*100.0;
                else
                    measurements(1,i,:) = 0;
                end
            end

            % Cover of true fragments (CTF)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'CTF')
                if ~isempty(pp.true_frags_idx)
                    measurements(1,i,pp.true_frags_idx) = frags_area(pp.true_frags_idx)/pp.fresco_nb_pixels*100.0;
                else
                    measurements(1,i,:) = 0.0;
                end
            end

            % Number of spurious fragments (NSF)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'NSF')
                if ~isempty(pp.spurious_frags_idx)
                    measurements(1,i,pp.spurious_frags_idx) = 1;
                else
                    measurements(1,i,:) = 0;
                end
            end

            % Ratio of spurious fragments (RSF)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'RSF')
                if ~isempty(pp.spurious_frags_idx)
                    measurements(1,i,pp.spurious_frags_idx) = 1/nb_frags*100.0;
                else
                    measurements(1,i,:) = 0;
                end
            end

            % Cover of spurious fragments (CSF)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'CSF')
                if ~isempty(pp.spurious_frags_idx)
                    measurements(1,i,pp.spurious_frags_idx) = frags_area(pp.spurious_frags_idx)/pp.fresco_nb_pixels*100.0;
                else
                    measurements(1,i,:) = 0.0;
                end
            end

            %--------------------------

            % Number of true positives (TP)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'TP')
                if ~isempty(tp)
                    measurements(1,i,tp) = 1;
                else
                    measurements(1,i,:) = 0;
                end
            end

            % Cover rate of true positives (CTP)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'CTP')
                if ~isempty(tp)
                    measurements(1,i,tp) = frags_area(tp)/pp.fresco_nb_pixels*100.0;
                else
                    measurements(1,i,:) = 0.0;
                end
            end

            % Number of false positives (FP)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'FP')
                if ~isempty(fp)
                    measurements(1,i,fp) = 1;
                else
                    measurements(1,i,:) = 0;
                end
            end

            % Cover rate of false positives (CFP)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'CFP')
                if ~isempty(fp)
                    measurements(1,i,fp) = frags_area(fp)/pp.fresco_nb_pixels*100.0;
                else
                    measurements(1,i,:) = 0.0;
                end
            end

            % Number of true negatives (TN)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'TN')
                if ~isempty(tn)
                    measurements(1,i,tn) = 1;
                else
                    measurements(1,i,:) = 0;
                end
            end

            % Cover rate of true negatives (CTN)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'CTN')
                if ~isempty(tn)
                    measurements(1,i,tn) = frags_area(tn)/pp.fresco_nb_pixels*100.0;
                else
                    measurements(1,i,:) = 0.0;
                end
            end

            % Number of false negatives (FN)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'FN')
                if ~isempty(fn)
                    measurements(1,i,fn) = 1;
                else
                    measurements(1,i,:) = 0;
                end
            end

            % Cover rate of false negatives (CFN)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'CFN')
                if ~isempty(fn)
                    measurements(1,i,fn) = frags_area(fn)/pp.fresco_nb_pixels*100.0;
                else
                    measurements(1,i,:) = 0.0;
                end
            end

            %--------------------------

            % Relative Cover Rate against ground truth (RCR)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'RCR')
                total_frags_area_sol = sum(frags_area(fm.matched_frags_idx));
                total_frags_area_gt  = sum(frags_area(pp.true_frags_idx));
                measurements(1,i,1)  = (abs(total_frags_area_sol-total_frags_area_gt)/total_frags_area_gt)*100;
            end

            % Accuracy (ACC)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'ACC')
                measurements(1,i,1) = accuracy;
            end

            % F-Measure (FM)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'FM')
                measurements(1,i,1) = f_measure;
            end

            %--------------------------

            % Mean fragments cover for color matching (CM-MFC)
            if strcmp(field_names{i},'CM-MFC')
                measurements(1,i,1:nb_frags) = cm.frags_covers_rates/nb_frags;
            end

            % Number of outside fragments for color matching (CM-NFO)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'CM-NFO')
                if ~isempty(cm.frags_outside_idx)
                    measurements(1,i,cm.frags_outside_idx) = 1;
                else
                    measurements(1,i,:) = 0;
                end
            end

            %--------------------------

            % Number of matched fragments for features matching (FM-NMF)
            if strcmp(field_names{i},'FM-NMF')
                if ~isempty(fm.matched_frags_idx)
                    measurements(1,i,fm.matched_frags_idx) = 1;
                else
                    measurements(1,i,:) = 0;
                end
            end

            % Cover rate of matched fragments for features matching (FM-CMF)
            if strcmp(field_names{i},'FM-CMF')
                if ~isempty(fm.matched_frags_idx)
                    measurements(1,i,fm.matched_frags_idx) = frags_area(fm.matched_frags_idx)/pp.fresco_nb_pixels*100.0;
                else
                    measurements(1,i,:) = 0.0;
                end
            end

            % Number of unmatched fragments for features matching (FM-NUF)
            if strcmp(field_names{i},'FM-NUF')
                if ~isempty(fm.unmatched_frags_idx)
                    measurements(1,i,fm.unmatched_frags_idx) = 1;
                else
                    measurements(1,i,:) = 0;
                end
            end

            % Cover rate of unmatched fragments for features matching (FM-CUF)
            if strcmp(field_names{i},'FM-CUF')
                if ~isempty(fm.unmatched_frags_idx)
                    measurements(1,i,fm.unmatched_frags_idx) = frags_area(fm.unmatched_frags_idx)/pp.fresco_nb_pixels*100.0;
                else
                    measurements(1,i,:) = 0.0;
                end
            end

            % Number of outside fragments for features matching (FM-NOF)
            if strcmp(field_names{i},'FM-NOF')
                if ~isempty(fm.outside_frags_idx)
                    measurements(1,i,fm.outside_frags_idx) = 1;
                else
                    measurements(1,i,:) = 0;
                end
            end

            % Cover rate of outside fragments for features matching (FM-COF)
            if strcmp(field_names{i},'FM-COF')
                if ~isempty(fm.outside_frags_idx)
                    measurements(1,i,fm.outside_frags_idx) = frags_area(fm.outside_frags_idx)/pp.fresco_nb_pixels*100.0;
                else
                    measurements(1,i,:) = 0.0;
                end
            end

            % Number of overlapping fragments for features matching (FM-NVF)
            if strcmp(field_names{i},'FM-NVF')
                if ~isempty(fm.overlapping_frags_idx)
                    measurements(1,i,fm.overlapping_frags_idx) = 1;
                else
                    measurements(1,i,:) = 0;
                end
            end

            % Cover rate of overlapping fragments for features matching (FM-CVF)
            if strcmp(field_names{i},'FM-CVF')
                if ~isempty(fm.overlapping_frags_idx)
                    measurements(1,i,fm.overlapping_frags_idx) = frags_area(fm.overlapping_frags_idx)/pp.fresco_nb_pixels*100.0;
                else
                    measurements(1,i,:) = 0.0;
                end
            end

            %--------------------------

            % Preprocessing time (PT)
            if strcmp(field_names{i},'PT')
                measurements(1,i,1) = pp.preprocessing_time;
            end

            % Color matching time (CMT)
            if strcmp(field_names{i},'CMT')
                measurements(1,i,1) = cm.color_matching_time;
            end

            % Features matching time (FMT)
            if strcmp(field_names{i},'FMT')
                measurements(1,i,1) = fm.features_matching_time;
            end

            % Total time (TT)
            if strcmp(field_names{i},'TT')
                measurements(1,i,1) = fm.total_time;
            end

            %--------------------------

            % Mean number of features matching points among placed fragments (MNFMP-PLC)
            if strcmp(field_names{i},'MNFMP-PLC')
                idx = tr_errors(1,:);
                if ~isempty(idx)
                    m = arrayfun(@(x) x.nb_matched_points, [fm.results{idx}]);
                    measurements(1,i,idx) = m/length(idx);
                end
            end

            % Mean number of features matching points among TP among all fragments (MNFMP-ALL)
            if strcmp(field_names{i},'MNFMP-ALL')
                m = arrayfun(@(x) x.nb_matched_points, [fm.results{:}]);
                measurements(1,i,1:nb_frags) = m/nb_frags;
            end

            %--------------------------

            % Mean translation error (MTE)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'MTE') && ~isempty(tr_errors(1,:))
                measurements(1,i,tr_errors(1,:)) = tr_errors(2,:)/size(tr_errors,2);
            end

            % Mean orientation error (MOE)
            if ~isempty(pp.frags_gt) && strcmp(field_names{i},'MOE') && ~isempty(ori_errors(1,:))
                measurements(1,i,ori_errors(1,:)) = ori_errors(2,:)/size(ori_errors,2);
            end

            %--------------------------

            % Mean fragments contrast (MFC)
            if strcmp(field_names{i},'MFC')
                measurements(1,i,1:nb_frags) = frags_contrast/nb_frags;
            end

            %--------------------------

            % Diagonal of fresco image (DFI)
            if strcmp(field_names{i},'DFI')
                s = size(pp.im_fresco_gray);
                measurements(1,i,1) = sqrt(s(1)^2+s(2)^2);
            end

            %--------------------------

            % Mean number of filtered fragment keypoint (MNFFK)
            if strcmp(field_names{i},'MNFFK')
                m = arrayfun(@(x) x.nb_filtered_frag_points, [fm.results{:}]);
                measurements(1,i,1:nb_frags) = m/nb_frags;
            end
        end
    end
end
