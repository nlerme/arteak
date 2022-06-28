% Function returning an estimate of the inter fragments distance
% 
% Inputs:
%   * im_filled_fresco:    reconstructed fresco with number filled fragments (uint64 image).
%   * neighbors_filename:  filename for saving image with estimated neighboring relationships.
%   * ifd1_dist_filename:  filename concerning first inter fragments distance estimate
%   * ifd2_dist_filename:  filename concerning second inter fragments distance estimate
% 
% Outputs:
%   * ifd1:  first inter fragments distance estimate
%   * ifd2:  second inter fragments distance estimate
function [ifd1,ifd2] = get_inter_fragments_distance_estimate( im_filled_frags, neighbors_filename, ifd1_dist_filename, ifd2_dist_filename )
    % We get the number of fragments
    nb_frags = max(im_filled_frags(:));

    %----------------------------------------------------------------------

    % We compute the minimum distances per fragment
    ifd1 = [];

    for k=1:nb_frags
        im_tmp1 = (im_filled_frags==k);
        im_tmp2 = (im_filled_frags~=k & im_filled_frags>0);
        im_d    = bwdist(im_tmp1);
        idx     = find(im_tmp2>0);
        dists   = im_d(idx);
        ifd1     = [ifd1,min(dists)];
    end

    % Distribution
    figure('units', 'normalized', 'outerposition', [0 0 1 1], 'visible', 'off');
    hist(ifd1,50);
    grid;
    saveas(gcf, ifd1_dist_filename);
    system(sprintf('mogrify -trim %s', ifd1_dist_filename));
    close(gcf);

    % First estimate is set as median of all resulting minimum distances
    ifd1 = median(ifd1);

    %----------------------------------------------------------------------

    % We compute the minimum distances per couple of fragments
    %--- For debugging ---
    figure('units', 'normalized', 'outerposition', [0 0 1 1], 'visible', 'off');
    imshow((im_filled_frags>0)-imerode(im_filled_frags>0, strel('disk',2)),[]);
    hold on;
    %---------------------

    ifd2 = [];

    for i=1:nb_frags
        % Lower bound on inter fragments distance
        im_tmp1 = (im_filled_frags==i);
        im_tmp2 = (im_filled_frags~=i & im_filled_frags>0);
        im_d    = bwdist(im_tmp1);
        idx     = find(im_tmp2>0);
        dists   = im_d(idx);
        min_d   = min(dists);

        %--- For debugging ---
        [r,c] = find(im_tmp1>0);
        py    = mean(r);
        px    = mean(c);
        %---------------------

        % Determination of neighbors
        d_coeff_min   = 2;
        d_coeff_max   = 10;
        d_coeff_sigma = 1;
        d_coeff       = (d_coeff_max-d_coeff_min)*exp(-(ifd1-1)/(2*d_coeff_sigma^2))+d_coeff_min;
        radius        = round(double(d_coeff*ifd1));
        im_tmp3       = (imdilate(im_tmp1, strel('disk', radius)) & im_tmp2);
        idx           = find(im_tmp3>0);
        neighbors     = unique(im_filled_frags(idx))';

        % Refinement of inter fragments distance
        for j=neighbors
            im_tmp4 = (im_filled_frags==j);
            idx     = find(im_tmp4>0);
            dists   = im_d(idx);
            ifd2     = [ifd2,min(dists)];

            %--- For debugging ---
            [r,c] = find(im_tmp4>0);
            qy    = mean(r);
            qx    = mean(c);
            plot([px,qx], [py,qy], 'g-', 'LineWidth', 2, 'Color', 'cyan');
            %---------------------
        end
    end

    % We save image containing estimated neighboring relationships
    saveas(gcf, neighbors_filename);
    system(sprintf('mogrify -trim %s', neighbors_filename));
    close(gcf);

    % Distribution
    figure('units', 'normalized', 'outerposition', [0 0 1 1], 'visible', 'off');
    hist(ifd2,50);
    grid;
    saveas(gcf, ifd2_dist_filename);
    system(sprintf('mogrify -trim %s', ifd2_dist_filename));
    close(gcf);

    % Second estimate is set as median of all resulting minimum distances
    ifd2 = median(ifd2);
end