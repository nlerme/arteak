close all;
clear all;
clc;

%--- Parameters -----------------------------------------------------------
results_dir      = 'new_results';
erosion_levels   = {{0,2},{0,2},{0,3},{0,3},{0,2},{0,2},{0,2},{0,2}};
fresco_names     = {'piero_73','piero_183','giotto_95','giotto_189','signorelli_71','signorelli_175','vasari_75','vasari_189'};
colorspace_names = {'grayscale','rgb'};
g_names          = {'l0.05_norm','l2_norm','harmonic_means','adhoc1'};
save_figures     = true;

%--- Sigmoids -------------------------------------------------------------
disp('------[ sigmoids ]------');

% We loop over frescoes
for i=1:numel(fresco_names)
    disp(sprintf('+ %s', fresco_names{i}));

    % We loop over erosion levels
    erosion_levels2 = erosion_levels{i};

    for j=1:numel(erosion_levels2)
        disp(sprintf('  + erosion level=%d', erosion_levels2{j}));
        fh = figure('units', 'normalized', 'outerposition', [0 0 1 1], 'visible', save_figures);

        % We load results
        load([results_dir filesep fresco_names{i} '_esf_' num2str(erosion_levels2{j}) '.mat'], ...
             'frag_i_intensities_tn', 'frag_j_intensities_tn', 'frag_i_intensities_fn', 'frag_j_intensities_fn');

        % We check if the size of arrays is consistent
        a = numel(frag_i_intensities_tn);
        b = numel(frag_j_intensities_tn);
        c = numel(frag_i_intensities_fn);
        d = numel(frag_j_intensities_fn);

        if a~=b || c~=d
            error('true and false neighbors arrays must have the same size');
        end

        % We loop over colorspaces
        for k=1:numel(colorspace_names)
            disp(sprintf('    + %s', colorspace_names{k}));

            % We convert image intensities to grayscale if necessary
            frag_i_intensities_tn2 = frag_i_intensities_tn;
            frag_j_intensities_tn2 = frag_j_intensities_tn;
            frag_i_intensities_fn2 = frag_i_intensities_fn;
            frag_j_intensities_fn2 = frag_j_intensities_fn;

            if strcmp(colorspace_names{k}, 'grayscale')
                for l=1:numel(frag_i_intensities_tn2)
                    frag_i_intensities_tn2{l} = rgb2gray(shiftdim(frag_i_intensities_tn{l},-1));
                    frag_j_intensities_tn2{l} = rgb2gray(shiftdim(frag_j_intensities_tn{l},-1));
                end

                for l=1:numel(frag_i_intensities_fn2)
                    frag_i_intensities_fn2{l} = rgb2gray(shiftdim(frag_i_intensities_fn{l},-1));
                    frag_j_intensities_fn2{l} = rgb2gray(shiftdim(frag_j_intensities_fn{l},-1));
                end
            end

            % We loop over g functions
            for l=1:numel(g_names)
                disp(sprintf('      + %s', g_names{l}));

                subplot(numel(g_names),numel(colorspace_names),(l-1)*numel(colorspace_names)+k);
                hold on;
                grid on;
                xlim([-1.2,+1]);
                ylim([-1,+1]);

                % False neighbors
                normalized_costs_fn = [];

                for m=1:numel(frag_i_intensities_fn2)
                    [~,normalized_cost_fn] = get_cost(frag_i_intensities_fn2{m}(:), frag_j_intensities_fn2{m}(:), g_names{l});
                    normalized_costs_fn    = [normalized_costs_fn,normalized_cost_fn];
                end

                % True neighbors
                normalized_costs_tn = [];

                for m=1:numel(frag_i_intensities_tn2)
                    [~,normalized_cost_tn] = get_cost(frag_i_intensities_tn2{m}(:), frag_j_intensities_tn2{m}(:), g_names{l});
                    normalized_costs_tn    = [normalized_costs_tn,normalized_cost_tn];
                end

                % Parameters estimation of the sigmoid from labelled data
                lambda0 = 20.0;
                mu0     = mean([normalized_costs_tn,normalized_costs_fn]);
                x0      = [-lambda0,lambda0*mu0];
                options = optimset('Display', 'off');
                theta   = fminunc(@(x) get_loss_value(x, [normalized_costs_tn,normalized_costs_fn], [zeros(size(normalized_costs_tn)),ones(size(normalized_costs_fn))]), x0, options);
                theta   = [max(eps,-theta(1)),min(1,max(-1,-theta(2)/theta(1)))];

                % We look for best threshold
                [best_threshold,best_tpr,fpr] = find_best_threshold([normalized_costs_tn,normalized_costs_fn], [zeros(size(normalized_costs_tn)),ones(size(normalized_costs_fn))]);

                % Plotting
                x = -1.2:0.001:+1;
                f = @(x) 2./(1+exp(-theta(1)*(x-theta(2))))-1;
                plot(x, f(x), 'k-');
                plot(normalized_costs_fn, f(normalized_costs_fn), 'ro', 'MarkerSize', 10); % false neighbors
                plot(normalized_costs_tn, f(normalized_costs_tn), 'bo', 'MarkerSize', 8); % true neighbors
                g = @(x) 2*(x>best_threshold)-1;
                plot(x, g(x), 'k--');

                %disp(sprintf('v1=%d, v2=%d | v3=%d, v4=%d', numel(normalized_costs_tn), numel(frag_i_intensities_tn2), numel(normalized_costs_fn), numel(frag_i_intensities_fn2)));

                % Title + legend
                legend({sprintf('\\psi_{\\theta} with \\theta=(\\mu=%.2f,\\lambda=%.2f)', -theta(2)/theta(1), -theta(1)), 'True neighbors', 'False neighbors', sprintf('FPR=%.2f', fpr)}, 'Location', 'south');
                title(['E_sf: ' strrep(fresco_names{i},'_',' ') ', erosion=' num2str(erosion_levels2{j}) ', g=' strrep(g_names{l},'_',' ') ' (' strrep(colorspace_names{k},'_',' ') ')']);
                hold off;
            end
        end

        %pbaspect([1 1 1]);

        if save_figures
            fn = [results_dir filesep sprintf('esf_%s_%d_sigmoids.png', fresco_names{i}, erosion_levels2{j})];
            saveas(fh, fn);
            system(sprintf('mogrify -trim %s', fn));
            close(fh);
        end
    end
end

%--- Histograms -----------------------------------------------------------
disp('------[ histograms ]------');

% We loop over frescoes
for i=1:numel(fresco_names)
    disp(sprintf('+ %s', fresco_names{i}));

    % We loop over erosion levels
    erosion_levels2 = erosion_levels{i};

    for j=1:numel(erosion_levels2)
        disp(sprintf('  + erosion level=%d', erosion_levels2{j}));
        fh = figure('units', 'normalized', 'outerposition', [0 0 1 1], 'visible', save_figures);

        % We load results
        load([results_dir filesep fresco_names{i} '_esf_' num2str(erosion_levels2{j}) '.mat'], ...
             'frag_i_intensities_tn', 'frag_j_intensities_tn', 'frag_i_intensities_fn', 'frag_j_intensities_fn');

        % We check if the size of arrays is consistent
        a = numel(frag_i_intensities_tn);
        b = numel(frag_j_intensities_tn);
        c = numel(frag_i_intensities_fn);
        d = numel(frag_j_intensities_fn);

        if a~=b || c~=d
            error('true and false neighbors arrays must have the same size');
        end

        % We loop over colorspaces
        for k=1:numel(colorspace_names)
            disp(sprintf('    + %s', colorspace_names{k}));

            % We convert image intensities to grayscale if necessary
            frag_i_intensities_tn2 = frag_i_intensities_tn;
            frag_j_intensities_tn2 = frag_j_intensities_tn;
            frag_i_intensities_fn2 = frag_i_intensities_fn;
            frag_j_intensities_fn2 = frag_j_intensities_fn;

            if strcmp(colorspace_names{k}, 'grayscale')
                for l=1:numel(frag_i_intensities_tn2)
                    frag_i_intensities_tn2{l} = rgb2gray(shiftdim(frag_i_intensities_tn{l},-1));
                    frag_j_intensities_tn2{l} = rgb2gray(shiftdim(frag_j_intensities_tn{l},-1));
                end

                for l=1:numel(frag_i_intensities_fn2)
                    frag_i_intensities_fn2{l} = rgb2gray(shiftdim(frag_i_intensities_fn{l},-1));
                    frag_j_intensities_fn2{l} = rgb2gray(shiftdim(frag_j_intensities_fn{l},-1));
                end
            end

            % We loop over g functions
            for l=1:numel(g_names)
                disp(sprintf('      + %s', g_names{l}));

                subplot(numel(g_names),numel(colorspace_names),(l-1)*numel(colorspace_names)+k);
                hold on;
                grid on;

                % False neighbors
                unnormalized_costs_fn = [];

                for m=1:numel(frag_i_intensities_fn2)
                    [unnormalized_cost_fn,~] = get_cost(frag_i_intensities_fn2{m}(:), frag_j_intensities_fn2{m}(:), g_names{l});
                    unnormalized_costs_fn    = [unnormalized_costs_fn,unnormalized_cost_fn];
                end

                [counts_fn,bins_fn] = hist(unnormalized_costs_fn, 200);
                yyaxis right;
                plot(bins_fn, counts_fn, 'r-');

                % True neighbors
                unnormalized_costs_tn = [];

                for m=1:numel(frag_i_intensities_tn2)
                    [unnormalized_cost_tn,~] = get_cost(frag_i_intensities_tn2{m}(:), frag_j_intensities_tn2{m}(:), g_names{l});
                    unnormalized_costs_tn    = [unnormalized_costs_tn,unnormalized_cost_tn];
                end

                [counts_tn,bins_tn] = hist(unnormalized_costs_tn, 200);
                yyaxis left;
                plot(bins_tn, counts_tn, 'b-');

                %disp(sprintf('v1=%d, v2=%d, v3=%d | v4=%d, v5=%d, v6=%d', sum(counts_tn), numel(frag_i_intensities_tn), numel(frag_j_intensities_tn2), sum(counts_fn), numel(frag_i_intensities_fn), numel(frag_j_intensities_fn2)));

                % Title + legend
                legend({'True neighbors', 'False neighbors'}, 'Location', 'northeast');
                title(['E_sf: ' strrep(fresco_names{i},'_',' ') ', erosion=' num2str(erosion_levels2{j}) ', g=' strrep(g_names{l},'_',' ') ' (' strrep(colorspace_names{k},'_',' ') ')']);
                hold off;
            end
        end

        %pbaspect([1 1 1]);

        if save_figures
            fn = [results_dir filesep sprintf('esf_%s_%d_histograms.png', fresco_names{i}, erosion_levels2{j})];
            saveas(fh, fn);
            system(sprintf('mogrify -trim %s', fn));
            close(fh);
        end
    end
end

function [best_threshold,best_tpr,fpr] = find_best_threshold( scores, gt_labels )
    % gt_labels(x)=0 <=> true neighbor
    % gt_labels(x)=1 <=> false neighbor
    thresholds = linspace(-1,+1,10000);
    tpr        = zeros(size(thresholds));
    fpr        = zeros(size(thresholds));

    % We loop over a set of thresholds
    for k=1:numel(thresholds)
        threshold = thresholds(k);
        tmp       = (scores>threshold);
        tp        = sum(tmp==0 & gt_labels==0);
        tn        = sum(tmp==1 & gt_labels==1);
        fp        = sum(tmp==0 & gt_labels==1);
        fn        = sum(tmp==1 & gt_labels==0);
        tpr(k)    = tp/(tp+fn)*100.0;
        fpr(k)    = fp/(fp+tn)*100.0;
        %disp(sprintf('+ threshold=%f, accuracy=%f', threshold, accuracies(k)));
    end

    % We select best threshold
    [best_tpr,index] = max(tpr);
    best_threshold   = thresholds(index);
    fpr              = fpr(index);
end

function L_Theta = get_loss_value( theta, scores, labels )
    p = 1./(1+exp(theta(1)*scores+theta(2)));
    L_Theta = -(sum(double(labels).*log(p+eps)) + sum((1-double(labels)).*log(1-p+eps)))/numel(labels);
end

function [unnormalized_cost,normalized_cost] = get_cost( frag_i_intensities, frag_j_intensities, g_name )
    if numel(frag_i_intensities)~=numel(frag_j_intensities)
        error('arrays of intensities of fragments must have the same size');
    end

    if strcmp(g_name, 'adhoc1')
        epsilon           = 0.1;
        alpha             = 0.5;
        d                 = abs(frag_i_intensities-frag_j_intensities);
        unnormalized_cost = max(0,sum(d(d>epsilon))-alpha*numel(frag_i_intensities)*epsilon);
        normalized_cost   = 2*(unnormalized_cost/(numel(frag_i_intensities)*(1-epsilon*alpha)))-1;
    elseif strcmp(g_name, 'harmonic_means')
        epsilon           = 0.0001;
        unnormalized_cost = harmmean(abs(frag_i_intensities-frag_j_intensities+epsilon));
        normalized_cost   = 2*unnormalized_cost-1;
    elseif strcmp(g_name, 'l0.05_norm')
        unnormalized_cost = norm(frag_i_intensities-frag_j_intensities,0.05)^0.05;
        normalized_cost   = 2*(unnormalized_cost/numel(frag_i_intensities))-1;
    elseif strcmp(g_name, 'l2_norm')
        unnormalized_cost = norm(frag_i_intensities-frag_j_intensities,2)^2;
        normalized_cost   = 2*(unnormalized_cost/numel(frag_i_intensities))-1;
    elseif strcmp(g_name, 'correlation')
        tmp               = corrcoef(frag_i_intensities, frag_j_intensities);
        unnormalized_cost = -tmp(1,2);
        normalized_cost   = unnormalized_cost;
    elseif strcmp(g_name, 'ssim')
        unnormalized_cost = 2*(1-ssim(frag_j_intensities, frag_i_intensities))-1;
        normalized_cost   = unnormalized_cost;
    else
        unnormalized_cost = [];
        normalized_cost   = [];
        error('unknown name for the g function');
    end
end