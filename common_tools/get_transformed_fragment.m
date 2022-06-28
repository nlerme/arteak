% Function applying transformation to some fragment.
% 
% Inputs:
%   * im_frag:      binary fragment image
%   * translation:  displacement of fragment (column vector [ty,tx] in R^2)
%   * angle:        angle of rotation of fragment (in degrees)
%   * fresco_size:  2D size of the fresco image
% 
% Outputs:
%   * fresco_coords:  pixel coordinates in fresco domain (real numbers)
%   * frag_coords:    pixel coordinates in fragment domain (real numbers)
function [fresco_coords,frag_coords] = get_transformed_fragment( im_frag, translation, angle, fresco_size )
    % We get size and center of square fragment image
    fs      = size(im_frag);
    center  = round(0.5*fs);

    % We compute pixel coordinates of a square region centered around the center of the fragment image projected in the fresco image (i.e. translation)
    lb      = round(translation-center);
    ub      = round(translation+center);
    y_range = max(lb(1),1):min(ub(1),fresco_size(1));
    x_range = max(lb(2),1):min(ub(2),fresco_size(2));

    if isempty(y_range) || isempty(x_range)
        fresco_coords = [];
        frag_coords   = [];
        return;
    end

    [rows,cols] = ndgrid(y_range, x_range);
    rows        = rows(:);
    cols        = cols(:);

    % We back project pixel coordinates of this square region in the fragment image and keep only those belonging to its domain
    frag_coords   = apply_backward_transform([rows,cols], translation, angle, center);
    keep          = find(frag_coords(:,1)>=1 & frag_coords(:,1)<=fs(1) & frag_coords(:,2)>=1 & frag_coords(:,2)<=fs(2));
    frag_coords   = frag_coords(keep,:);
    fresco_coords = [rows(keep),cols(keep)];
    %---------------
    frag_coords2  = round(frag_coords);
    idx           = sub2ind(fs, frag_coords2(:,1), frag_coords2(:,2));
    keep          = im_frag(idx)>0;
    frag_coords   = frag_coords(keep,:);
    fresco_coords = fresco_coords(keep,:);
end