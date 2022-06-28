% Function returning true if fragment lies inside fresco (modulo some tolerance).
% 
% Inputs:
%   * resulting_oc_center:  outer circle center of the registered fragment (in R^2)
%   * resulting_frag_area:  area of the registered fragment (in in R_{>0})
%   * fresco_size:          2D size of the fresco image (in N_{>0}^2)
%   * true_frag_area:       true area of the corresponding fragment (in R_{>0})
%   * tolerance:            thresholding for accepting/rejecting registered fragment (in [0,1])
% 
% Outputs:
%   * decision:  true if fragment lies inside fresco, false otherwise
function decision = is_fragment_inside_fresco( resulting_oc_center, resulting_frag_area, fresco_size, true_frag_area, tolerance )
    a        = (resulting_oc_center(1)>=1 && resulting_oc_center(1)<=fresco_size(1));
    b        = (resulting_oc_center(2)>=1 && resulting_oc_center(2)<=fresco_size(2));
    decision = (a && b && (min(resulting_frag_area/true_frag_area,1.0)>=(1-tolerance)));
end