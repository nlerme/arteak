function cost = my_datacost_fn( s, l )
    if s==1
        if (l==1) cost = 10; else cost = 3; end
    elseif s==2
        if (l==1) cost = 1; else cost = 10; end
    else
        if (l==1) cost = 10; else cost = 2; end
    end
end