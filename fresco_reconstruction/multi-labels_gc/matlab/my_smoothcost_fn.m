function cost = my_smoothcost_fn( s1, s2, l1, l2 )
    if s1>s2
        [s1,s2] = my_swap_vars(s1, s2);
        [l1,l2] = my_swap_vars(l1, l2);
    end

    if (l1==2 && l2==1)
        cost = 100;
    else
        cost = 0;
    end

%     if s1==1 && s2==2
%         if (l1==2 && l2==1) cost = 100; else cost = 0; end
%     end
% 
%     if s1==2 && s2==1
%         if (l1==1 && l2==2) cost = 100; else cost = 0; end
%     end
% 
%     if s1==2 && s2==3
%         if (l1==2 && l2==1) cost = 100; else cost = 0; end
%     end
% 
%     if s1==3 && s2==2
%         if (l1==1 && l2==2) cost = 100; else cost = 0; end
%     end
end
