% Function displaying the reconstructed fresco.
% 
% Inputs:
%   * im_map:              multi-channels fresco image
%   * frags_sol:           solution composed of fragments
%   * tp:                  true positives indexes (can be empty)
%   * fp:                  false positives indexes (can be empty)
%   * tn:                  true negatives indexes (can be empty)
%   * fn:                  false negatives indexes (can be empty)
%   * ina:                 inaccurately placed fragments (can be empty)
%   * show_inner_circles:  shows/hides inner circles (true or false)
%   * show_outer_circles:  shows/hides outer circles (true or false)
%   * show_coloring:       shows/hides graph coloring (true or false)
%   * show_neighbors:      shows/hides graph coloring (true or false)
%   * show_ids:            shows/hides fragments ids (true or false)
%   * show_figures:        shows/hides figure (true or false)
% 
% Outputs:
%   h:  figure handler
function fh = show_reconstructed_fresco( im_map, frags_sol, tp, fp, tn, fn, ina, show_inner_circles, show_outer_circles, show_coloring, show_neighbors, show_ids, show_figures )
    % We create figure and display map
    if show_figures
        show_figures_str = 'on';
    else
        show_figures_str = 'off';
    end

    fh = figure('units', 'normalized', 'outerposition', [0 0 1 1], 'visible', show_figures_str);
    imshow(im_map,[]);
    hold on;

    % We get colormap
    colormap = get_colormap();

    % We loop over fragments
    for i=1:length(frags_sol)
        % We set some variables for convenience
        idx = frags_sol{i}.idx;

        % We choose a color for current fragment
        if show_coloring && ~isempty(frags_sol{i}.color_idx)
            color = colormap(frags_sol{i}.color_idx,:);
        else
            if isempty(tp) && isempty(fp) && isempty(tn) && isempty(fn) && isempty(ina)
                color = 'cyan'; % CAUTION: do not use `white' (markers and text will appear in black when using `saveas')
            else
                if ~isempty(ina) && sum(ina==idx)==1
                    color = [1,0.64,0]; % orange
                elseif ~isempty(fp) && sum(fp==idx)==1
                    color = 'red';
                else
                    color = 'green';
                end
            end
        end

        % We plot inner circle (optional)
        if show_inner_circles
            ic_center = frags_sol{i}.inner_circle_center;
            ic_radius = frags_sol{i}.inner_circle_radius;
            viscircles(flip(ic_center), ic_radius, 'Color', color);
        end

        % We plot fragment id (optional)
        if show_ids
            ic_center = frags_sol{i}.inner_circle_center;
            ic_radius = frags_sol{i}.inner_circle_radius;
            plot(ic_center(2), ic_center(1), 'ro', 'MarkerSize', 0.25*ic_radius, 'Color', color, 'LineWidth', 2);
            text(double(ic_center(2)+10), double(ic_center(1)+10), sprintf('%d', idx), 'Color', color, 'FontSize', 12);
        end

        % We plot outer circle (optional)
        if show_outer_circles
            oc_center = frags_sol{i}.outer_circle_center;
            oc_radius = frags_sol{i}.outer_circle_radius;
            viscircles(flip(oc_center), oc_radius, 'Color', color);
        end

        % We plot neighboring relationships (optional)
        if show_neighbors
            ic_center = frags_sol{i}.inner_circle_center;
            ic_radius = frags_sol{i}.inner_circle_radius;

            for j=frags_sol{i}.neighbors
                ic_center2 = frags_sol{j}.inner_circle_center;
                plot([ic_center(2),ic_center2(2)], [ic_center(1),ic_center2(1)], 'LineWidth', 2, 'Color', color);
            end
        end
    end

    hold off;
end