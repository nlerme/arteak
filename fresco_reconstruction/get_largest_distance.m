% Function returning the largest distance of a point to a given mask.
% 
% Inputs:
%   * p      :  coordinates of pixel (p in assumed to lie in any region where im_mask>0)
%   * im_mask:  binary image
% 
% Outputs:
%   * d:  largest distance (in R_{>0})
function d = get_largest_distance( p, im_mask )
    im_tmp1 = zeros(size(im_mask));
    im_tmp1(p(1),p(2)) = 1;
    im_tmp2 = (bwdist(im_tmp1, 'euclidean').*im_mask);
    d = max(im_tmp2(:));
end