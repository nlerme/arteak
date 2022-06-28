% Function returning true if two fragments intersect (modulo some tolerance).
% 
% Inputs:
%   * idx1:       pixel coordinates of first fragment (n x 2 matrix of integers [py_1,px_1;...;py_1,px_n])
%   * c1:         outer circle coordinates of first fragment (in R^2)
%   * r1:         outer circle radius of first fragment (in R_{>0})
%   * idx2:       pixel coordinates of second fragment (n x 2 matrix integers [py_1,px_1;...;py_1,px_n])
%   * c2:         outer circle coordinates of second fragment (in R^2)
%   * r2:         outer circle radius of second fragment (in R_{>0})
%   * tolerance:  threshold for accepting decision (in [0,1])
% 
% Outputs:
%   * decision:  true if fragments intersect with each other, false otherwise (boolean)
%   * inter:     intersection between fragments (n x 2 matrix of integers [py_1,px_1;...;py_1,px_m])
%   * subidx1:   indexes of pixel coordinates in idx1 intersecting those in idx2 (array of integers)
%   * subidx2:   indexes of pixel coordinates in idx2 intersecting those in idx1 (array of integers)
function [decision,inter,subidx1,subidx2] = are_fragments_intersected( idx1, c1, r1, idx2, c2, r2, tolerance )
    if norm(c1-c2)>(r1+r2)
        decision = false;
        inter    = [];
        subidx1  = [];
        subidx2  = [];
        return;
    end

    area1                   = size(idx1,1);
    area2                   = size(idx2,1);
    [inter,subidx1,subidx2] = intersect(idx1, idx2, 'rows');
    area3                   = size(inter,1);
    decision                = ((area3 / min(area1,area2)) > tolerance);
end