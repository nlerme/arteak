% This function saves the ideal fresco reconstructions (eventually
% superimposed with neighboring relationships between fragments).
% 
% Inputs:
%   * im_rec_color:     RGB fresco color (all formats)
%   * frags_sol:        solution composed of fragments (cell array)
%   * idx_color:        color used for displaying fragment numbers (RGB/string)
%   * neighbors_color:  color used for displaying neighboring relationships between fragments (RGB/string)
%   * filename:         name of the saved file
% 
% Outputs:
%   None
function save_reconstructed_fresco( im_rec_color, frags_sol, idx_color, neighbors_color, filename )
    if ~isempty(frags_sol)
        % If neighboring relationships between fragments are available, we superimpose them onto the ideal reconstructed fresco
        h = figure('units', 'normalized', 'outerposition', [0 0 1 1], 'visible', false);
        imshow(im_rec_color, []);
        hold on;

        % Neighboring relationships
        for i=1:numel(frags_sol)
            translation1 = frags_sol{i}.translation;

            for j=frags_sol{i}.neighbors
                translation2 = frags_sol{j}.translation;
                plot([translation1(2),translation2(2)], [translation1(1),translation2(1)], 'Color', neighbors_color, 'LineWidth', 4);
            end
        end

        % Numbering of individual fragments
        for i=1:numel(frags_sol)
            idx         = frags_sol{i}.idx;
            translation = frags_sol{i}.translation;

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