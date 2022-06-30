% This function saves the ideal fresco reconstructions (eventually superimposed with neighboring relationships between fragments)
function save_reconstructed_fresco( im_rec_color, frag_neighbors, frag_translations, idx_color, neighbors_color, filename )
    if ~isempty(frag_neighbors) && ~isempty(frag_translations)
        % If neighboring relationships between fragments are available, we superimpose them onto the ideal reconstructed fresco
        h = figure('units', 'normalized', 'outerposition', [0 0 1 1], 'visible', false);
        imshow(im_rec_color, []);
        hold on;

        % Neighboring relationships
        for idx1=1:size(frag_neighbors,1)
            translation1 = frag_translations(idx1);
            translation1 = translation1{1};

            for idx2=1:size(frag_neighbors,2)
                if frag_neighbors(idx1,idx2)==0
                    continue;
                end

                translation2 = frag_translations(idx2);
                translation2 = translation2{1};
                plot([translation1(2),translation2(2)], [translation1(1),translation2(1)], 'Color', neighbors_color, 'LineWidth', 4);
            end
        end

        % Numbering of individual fragments
        for idx=1:size(frag_neighbors,1)
            translation = frag_translations(idx);
            translation = translation{1};

            if ~isempty(translation)
                text(translation(2)-10, translation(1), sprintf('%d', idx-1), 'Color', idx_color, 'FontSize', 16);
            end
        end

        hold off;

        % Cropping and saving
        saveas(gcf, filename);
        system(sprintf('mogrify -trim %s', filename));
        close(gcf);
    else
        % Otherwise, we just save the ideal reconstructed fresco
        imwrite(im_rec_color, filename);
    end
end