close all;
clear all;
clc;

%--- Parameters -----------------------------------------------------------
results_dir      = 'new_results';
erosion_levels   = {{0,2},{0,2},{0,3},{0,3},{0,2},{0,2},{0,2},{0,2}};
fresco_names     = {'piero_73','piero_183','giotto_95','giotto_189','signorelli_71','signorelli_175','vasari_75','vasari_189'};
colorspace_names = {'grayscale','rgb'};
g_names          = {'l1_norm','l2_norm','correlation'};
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
        load([results_dir filesep fresco_names{i} '_ed_' num2str(erosion_levels2{j}) '.mat'], ...
             'frag_intensities_tf', 'fresco_intensities_tf', 'frag_intensities_ff', 'fresco_intensities_ff');

        % We check the size of arrays is consistent
        a = numel(frag_intensities_tf);
        b = numel(fresco_intensities_tf);
        c = numel(frag_intensities_ff);
        d = numel(fresco_intensities_ff);

        if a~=b || c~=d
            error('true and false fragments arrays must have the same size');
        end

        % We loop over colorspaces
        for k=1:numel(colorspace_names)
            disp(sprintf('    + %s', colorspace_names{k}));

            % We convert image intensities to grayscale if necessary
            frag_intensities_tf2   = frag_intensities_tf;
            fresco_intensities_tf2 = fresco_intensities_tf;
            frag_intensities_ff2   = frag_intensities_ff;
            fresco_intensities_ff2 = fresco_intensities_ff;

            if strcmp(colorspace_names{k}, 'grayscale')
                for l=1:numel(frag_intensities_tf2)
                    frag_intensities_tf2{l}   = rgb2gray(shiftdim(frag_intensities_tf{l},-1));
                    fresco_intensities_tf2{l} = rgb2gray(shiftdim(fresco_intensities_tf{l},-1));
                end
    
                for l=1:numel(frag_intensities_ff2)
                    frag_intensities_ff2{l}   = rgb2gray(shiftdim(frag_intensities_ff{l},-1));
                    fresco_intensities_ff2{l} = rgb2gray(shiftdim(fresco_intensities_ff{l},-1));
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

                % False fragments
                normalized_costs_ff = [];

                for m=1:numel(frag_intensities_ff2)
                    [~,normalized_cost_ff] = get_cost(frag_intensities_ff2{m}(:), fresco_intensities_ff2{m}(:), g_names{l});
                    normalized_costs_ff    = [normalized_costs_ff,normalized_cost_ff];
                end

                % True fragments
                normalized_costs_tf = [];

                for m=1:numel(frag_intensities_tf2)
                    [~,normalized_cost_tf] = get_cost(frag_intensities_tf2{m}(:), fresco_intensities_tf2{m}(:), g_names{l});
                    normalized_costs_tf    = [normalized_costs_tf,normalized_cost_tf];
                end

                % Parameters estimation of the sigmoid from labelled data
                lambda0 = 20.0;
                mu0     = -0.9;
                x0      = [-lambda0,lambda0*mu0];
                options = optimset('Display', 'off');
                theta   = fminunc(@(x) get_loss_value(x, [normalized_costs_tf,normalized_costs_ff], [zeros(size(normalized_costs_tf)),ones(size(normalized_costs_ff))]), x0, options);
                theta   = [max(eps,-theta(1)),min(1,max(-1,-theta(2)/theta(1)))];

                % Plotting
                x = -1.2:0.01:+1;
                f = @(x) 2./(1+exp(-theta(1)*(x-theta(2))))-1;
                plot(x, f(x), 'Color', 'black');
                plot(normalized_costs_ff, f(normalized_costs_ff), 'ro', 'MarkerSize', 10); % false fragments
                plot(normalized_costs_tf, f(normalized_costs_tf), 'bo', 'MarkerSize', 8); % true fragments

                %disp(sprintf('v1=%d, v2=%d | v3=%d, v4=%d', numel(normalized_costs_tf), numel(frag_intensities_tf2), numel(normalized_costs_ff), numel(frag_intensities_ff2)));

                % Title + legend
                legend({sprintf('\\psi_{\\theta} with \\theta=(\\mu=%.2f,\\lambda=%.2f)', -theta(2)/theta(1), -theta(1)), 'True fragments', 'False fragments'}, 'Location', 'southeast');
                title(['E_d: ' strrep(fresco_names{i},'_',' ') ', erosion=' num2str(erosion_levels2{j}) ', g=' strrep(g_names{l},'_',' ') ' (' strrep(colorspace_names{k},'_',' ') ')']);
                hold off;
            end
        end

        %pbaspect([1 1 1]);

        if save_figures
            fn = [results_dir filesep sprintf('ed_%s_%d_sigmoids.png', fresco_names{i}, erosion_levels2{j})];
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
        load([results_dir filesep fresco_names{i} '_ed_' num2str(erosion_levels2{j}) '.mat'], ...
             'frag_intensities_tf', 'fresco_intensities_tf', 'frag_intensities_ff', 'fresco_intensities_ff');

        % We check the size of arrays is consistent
        a = numel(frag_intensities_tf);
        b = numel(fresco_intensities_tf);
        c = numel(frag_intensities_ff);
        d = numel(fresco_intensities_ff);

        if a~=b || c~=d
            error('true and false fragments arrays must have the same size');
        end

        % We loop over colorspaces
        for k=1:numel(colorspace_names)
            disp(sprintf('    + %s', colorspace_names{k}));

            % We convert image intensities to grayscale if necessary
            frag_intensities_tf2   = frag_intensities_tf;
            fresco_intensities_tf2 = fresco_intensities_tf;
            frag_intensities_ff2   = frag_intensities_ff;
            fresco_intensities_ff2 = fresco_intensities_ff;

            if strcmp(colorspace_names{k}, 'grayscale')
                for l=1:numel(frag_intensities_tf2)
                    frag_intensities_tf2{l}   = rgb2gray(shiftdim(frag_intensities_tf{l},-1));
                    fresco_intensities_tf2{l} = rgb2gray(shiftdim(fresco_intensities_tf{l},-1));
                end

                for l=1:numel(frag_intensities_ff2)
                    frag_intensities_ff2{l}   = rgb2gray(shiftdim(frag_intensities_ff{l},-1));
                    fresco_intensities_ff2{l} = rgb2gray(shiftdim(fresco_intensities_ff{l},-1));
                end
            end

            % We loop over g functions
            for l=1:numel(g_names)
                disp(sprintf('      + %s', g_names{l}));

                subplot(numel(g_names),numel(colorspace_names),(l-1)*numel(colorspace_names)+k);
                hold on;
                grid on;

                % False fragments
                unnormalized_costs_ff = [];

                for m=1:numel(frag_intensities_ff2)
                    [unnormalized_cost_ff,~] = get_cost(frag_intensities_ff2{m}(:), fresco_intensities_ff2{m}(:), g_names{l});
                    unnormalized_costs_ff    = [unnormalized_costs_ff,unnormalized_cost_ff];
                end

                [counts_ff,bins_ff] = hist(unnormalized_costs_ff, 200);
                yyaxis right;
                plot(bins_ff, counts_ff, 'r-');

                % True fragments
                unnormalized_costs_tf = [];

                for m=1:numel(frag_intensities_tf2)
                    [unnormalized_cost_tf,~] = get_cost(frag_intensities_tf2{m}(:), fresco_intensities_tf2{m}(:), g_names{l});
                    unnormalized_costs_tf    = [unnormalized_costs_tf,unnormalized_cost_tf];
                end

                [counts_tf,bins_tf] = hist(unnormalized_costs_tf, 200);
                yyaxis left;
                plot(bins_tf, counts_tf, 'b-');

                %disp(sprintf('v1=%d, v2=%d | v3=%d, v4=%d', sum(counts_tf), numel(frag_intensities_tf2), sum(counts_ff), numel(frag_intensities_ff2)));

                % Title + legend
                legend({'True fragments', 'False fragments'}, 'Location', 'northeast');
                title(['E_d: ' strrep(fresco_names{i},'_',' ') ', erosion=' num2str(erosion_levels2{j}) ', g=' strrep(g_names{l},'_',' ') ' (' strrep(colorspace_names{k},'_',' ') ')']);
                hold off;
            end
        end

        %pbaspect([1 1 1]);

        if save_figures
            fn = [results_dir filesep sprintf('ed_%s_%d_histograms.png', fresco_names{i}, erosion_levels2{j})];
            saveas(fh, fn);
            system(sprintf('mogrify -trim %s', fn));
            close(fh);
        end
    end
end

function L_Theta = get_loss_value( theta, scores, labels )
    p = 1./(1+exp(theta(1)*scores+theta(2)));
    L_Theta = -(sum(double(labels).*log(p+eps)) + sum((1-double(labels)).*log(1-p+eps)))/numel(labels);
end

function [unnormalized_cost,normalized_cost] = get_cost( frag_intensities, fresco_intensities, g_name )
    if numel(frag_intensities)~=numel(fresco_intensities)
        error('fragment and fresco intensities arrays must have the same size');
    end

    if strcmp(g_name, 'l1_norm')
        unnormalized_cost = norm(frag_intensities-fresco_intensities,1)^1;
        normalized_cost   = 2*(unnormalized_cost / numel(frag_intensities))-1;
    elseif strcmp(g_name, 'l2_norm')
        unnormalized_cost = norm(frag_intensities-fresco_intensities,2)^2;
        normalized_cost   = 2*(unnormalized_cost / numel(frag_intensities))-1;
    elseif strcmp(g_name, 'correlation')
        tmp               = corrcoef(frag_intensities, fresco_intensities);
        unnormalized_cost = -tmp(1,2);
        normalized_cost   = unnormalized_cost;
    elseif strcmp(g_name, 'ssim')
        unnormalized_cost = 2*(1-ssim(fresco_intensities, frag_intensities))-1;
        normalized_cost   = unnormalized_cost;
    else
        unnormalized_cost = [];
        normalized_cost   = [];
        error('unknown name for the g function');
    end
end