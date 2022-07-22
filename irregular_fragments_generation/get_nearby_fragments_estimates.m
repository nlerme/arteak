% Function returning an estimate of the inter fragments distance
% 
% Inputs:
%   * im_rec:        reconstructed fresco with filled numbered fragments (uint64 image).
%   * frags_sol_in:  input collection of fragments
% 
% Outputs:
%   * ifd:            distance estimate between nearby fragments
%   * out_frags_sol:  output collection of fragments
function [ifd2,frags_sol_out] = get_nearby_fragments_estimates( im_rec, frags_sol_in )
    % We get the number of fragments and allocate memory for storing neighboring relationships
    nb_frags      = numel(frags_sol_in);
    frags_sol_out = frags_sol_in;

    % We loop over fragments
    ifd1 = zeros(1, nb_frags);

    for k=1:nb_frags
        % We compute the minimum distance separating current fragment from the other ones
        im_tmp1 = (im_rec==k);
        im_tmp2 = (im_rec~=k & im_rec>0);
        im_d    = bwdist(im_tmp1);
        idx     = find(im_tmp2>0);
        dists   = im_d(idx);
        ifd1(k) = min(dists);
    end

    % First distance estimate is taken as the median of the minimum distance between any fragment and the other ones
    ifd1 = median(ifd1);

    %----------------------------------------------------------------------

    % We loop over fragments
    ifd2 = [];

    for i=1:nb_frags
        % We compute againt the distance map from current fragment
        im_tmp1 = (im_rec==i);
        im_tmp2 = (im_rec~=i & im_rec>0);
        im_d    = bwdist(im_tmp1);

        % We estimate nearby fragments from the current one by intersecting the union of 
        % the former and a dilated version of the latter with an appropriate dilation factor
        d_coeff_min   = 2;
        d_coeff_max   = 10;
        d_coeff_sigma = 1;
        d_coeff       = (d_coeff_max-d_coeff_min)*exp(-(ifd1-1)/(2*d_coeff_sigma^2))+d_coeff_min;
        radius        = round(double(d_coeff*ifd1));
        im_tmp3       = (imdilate(im_tmp1, strel('disk', radius)) & im_tmp2);
        idx           = find(im_tmp3>0);
        neighbors_idx = unique(im_rec(idx))';

        % Refinement of inter fragments distance
        for j=neighbors_idx
            frags_sol_out{i}.neighbors = [frags_sol_out{i}.neighbors,j];
            im_tmp4                    = (im_rec==j);
            idx                        = find(im_tmp4>0);
            dists                      = im_d(idx);
            ifd2                       = [ifd2,min(dists)];
        end
    end

    % Second distance estimate is taken as the median of all minimum distances between found couples of nearby fragments
    ifd2 = median(ifd2);
end