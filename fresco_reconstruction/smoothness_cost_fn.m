% Function assigning smoothness cost between two neighboring fragments. 
% Please note that the global variable `nodes_idx' is the graph coloring.
% 
% Inputs:
%   * s1:  index of first fragment (in N_{>0})
%   * s2:  index of second fragment (in N_{>0})
%   * l1:  label of first fragment (in N_{>0})
%   * l2:  label of second fragment (in N_{>0})
function cost = smoothness_cost_fn( s1, s2, l1, l2 )
    global nodes_idx;

    if s1>s2
        [s1,s2] = swap_vars(s1, s2);
        [l1,l2] = swap_vars(l1, l2);
    end

    if (l1==nodes_idx(s1) && l2==nodes_idx(s2))
        cost = 1.0;
    else
        cost = 0;
    end
end