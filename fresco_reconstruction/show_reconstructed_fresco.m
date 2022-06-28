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
%   * show_inner_circles:  show/hide inner circles (true or false)
%   * show_outer_circles:  show/hide outer circles (true or false)
%   * show_coloring:       show/hide graph coloring (true or false)
%   * show_ids:            show/hide fragments ids (true or false)
%   * show_figs:           show/hide figure ('on' or 'off')
% 
% Outputs:
%   None
function show_reconstructed_fresco( im_map, frags_sol, tp, fp, tn, fn, ina, show_inner_circles, show_outer_circles, show_coloring, show_ids, show_figures )
    % We create figure and display map
    figure('units', 'normalized', 'outerposition', [0 0 1 1], 'visible', show_figures);
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
                color = 'cyan'; % CAUTION: do not use `white' (otherwise, markers and text appear as black when using `saveas')
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
            plot(ic_center(2), ic_center(1), 'r+', 'MarkerSize', 0.5*ic_radius, 'Color', color, 'LineWidth', 4);
            text(double(ic_center(2)+10), double(ic_center(1)+10), sprintf('%d', idx), 'Color', color, 'FontSize', 12);
        end

        % We plot outer circle (optional)
        if show_outer_circles
            oc_center = frags_sol{i}.outer_circle_center;
            oc_radius = frags_sol{i}.outer_circle_radius;
            viscircles(flip(oc_center), oc_radius, 'Color', color);
        end

        % We plot graph coloring (optional)
        if show_coloring
            ic_center = frags_sol{i}.inner_circle_center;
            ic_radius = frags_sol{i}.inner_circle_radius;
            plot(ic_center(2), ic_center(1), 'r+', 'MarkerSize', 0.5*ic_radius, 'Color', color, 'LineWidth', 4);

            for j=frags_sol{i}.neighbors
                ic_center2 = frags_sol{j}.inner_circle_center;
                plot([ic_center(2),ic_center2(2)], [ic_center(1),ic_center2(1)], 'g-', 'LineWidth', 2, 'Color', 'white');
            end
        end
    end

    hold off;
end