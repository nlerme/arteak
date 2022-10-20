% Function returning the error between the transformation parameters of two 
% fragments, modulo some tolerance on translation and rotation.
% 
% Inputs:
%   * frag1:  first fragment (non empty struct)
%   * frag2:  second fragment (non empty struct)
%   * tt:     tolerance on translation in pixels (>=0)
%   * rt:     tolerance on rotation in degrees (in [0,360])
% 
% Outputs:
%   * t_err:     error in translation expressed in pixels (>=0; L2 norm of the difference of translation vectors)
%   * a_err:     error in rotation expressed in degrees (in [0,360]; absolute angular difference)
%   * decision:  true if both t_err<=tt and a_err<=rt, false otherwise
function [t_err,a_err,decision] = compare_fragments_parameters( frag1, frag2, tt, rt )
    frag1_t  = frag1.translation;
    frag1_a  = frag1.angle;
    frag2_t  = frag2.translation;
    frag2_a  = frag2.angle;
    t_err    = norm(frag1_t-frag2_t);
    a_err    = get_angular_difference(frag1_a, frag2_a);
    decision = (t_err<=tt && a_err<=rt);
end