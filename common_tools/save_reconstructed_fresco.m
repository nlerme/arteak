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
        % If a collection of fragments is available, we show the reconstruction fresco
        h = figure('units', 'normalized', 'outerposition', [0 0 1 1], 'visible', false);
        imshow(im_rec_color, []);
        hold on;

        % We superimpose information onto the reconstructed fresco
        for i=1:numel(frags_sol)
            idx          = frags_sol{i}.idx;
            translation1 = frags_sol{i}.translation;
            angle        = frags_sol{i}.angle;

            for j=frags_sol{i}.neighbors
                translation2 = frags_sol{j}.translation;
                plot([translation1(2),translation2(2)], [translation1(1),translation2(1)], 'Color', neighbors_color, 'LineWidth', 3);
            end
        end

        for i=1:numel(frags_sol)
            idx          = frags_sol{i}.idx;
            translation1 = frags_sol{i}.translation;
            angle        = frags_sol{i}.angle;
            text(translation1(2)-10, translation1(1), sprintf('%d', idx-1), 'Color', idx_color, 'FontSize', 14);
        end

        hold off;

        % We crop and save the resulting image
        saveas(gcf, filename);
        system(sprintf('mogrify -trim %s', filename));
        close(gcf);
    else
        % Otherwise, we just save the reconstructed fresco
        imwrite(im_rec_color, filename);
    end
end