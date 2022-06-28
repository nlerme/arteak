% Function returning the inscribed circle of a binary image. In case of ties, 
% the circle whose center is the nearest from p is chosen.
%
% Inputs:
%   * im_src:  binary image
%   * p:       coordinates of pixel helping to break ties (in R^2)
%
% Outputs:
%   * c:  center estimate of the inscribed circle (in N^2)
%   * r:  radius estimate of the inscribed circle (in R_{>0})
function [c,r] = get_inner_circle( im_src, p )
    im_dist = bwdist(im_src==0, 'euclidean');
    r = max(im_dist(:));
    [rows,cols] = find(im_dist==r);
    d = sqrt((rows-p(1)).^2+(cols-p(2)).^2);
    [~,idx] = min(d(:));
    c = [rows(idx),cols(idx)];
end