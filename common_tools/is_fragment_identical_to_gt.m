% Function comparing a fragment to ground truth (modulo some tolerance).
% 
% Inputs:
%   * frag:  resulting fragment (struct)
%   * gt:    ground truth fragment (struct)
%   * tt:    tolerance in translation in pixels (>=0)
%   * rt:    tolerance in rotation in degrees (in [0,360])
% 
% Outputs:
%   * decision:  true if fragment is identical to ground truth, false otherwise
function decision = is_fragment_identical_to_gt( frag, gt, tt, rt )
    frag_t   = frag.translation;
    frag_a   = frag.angle;
    gt_t     = gt.translation;
    gt_a     = gt.angle;
    decision = (norm(frag_t-gt_t)<=tt && min(abs(frag_a-gt_a),2*pi-abs(frag_a-gt_a))<=rt);
end