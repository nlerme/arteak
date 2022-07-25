% Returns the circumscribed circle of a given set of points using a subgradient 
% algorithm (because of the non differentiability of the involved functional).
% 
% Inputs:
%   * im_src:         binary image
%   * nb_iterations:  number of iterations (in N_{>0})
%   * verbose:        enables/disables display of debugging messages (true or false)
% 
% Outputs:
%   * x_final:     center of the resulting circle (in R^2)
%   * r_final:     radius of the resulting circle (in R_{>0})
%   * iterations:  array containing iterations of size Nx3 (a row corresponds to [xk,f(x_k)])
function [x_final,r_final,iterations] = get_outer_circle( im_src, nb_iterations, verbose )
    % We only take into account pixels lying at the boundary of the fragment
    im_src_d      = imdilate(im_src, strel('square',3))-im_src;
    [rows,cols]   = find(im_src_d);
    x             = [rows,cols];

    % We apply subgradient algorithm (CAUTION: f(x_k) can increase during iterations)
    x0         = mean(x,1);
    fx0        = max(sqrt(sum((repmat(x0,[size(x,1),1])-x).^2,2)));
    xk_new     = x0;
    fxk_new    = fx0;
    iterations = [];

    for k=0:(nb_iterations-1)
        if verbose
            disp(sprintf('+ x%d=(%f,%f) | f(x%d)=%f', k, xk_new(1), xk_new(2), k, fxk_new));
        end

        iterations = [iterations;[xk_new,fxk_new]];

        d     = sqrt(sum((repmat(xk_new,[size(x,1),1])-x).^2,2));
        af    = find(d==max(d));
        idx   = 1;
        gradk = (xk_new-x(af(idx),:))/d(af(idx));
        tk    = (0.1*fx0)/sqrt(k+1);

        xk_old  = xk_new;
        fxk_old = fxk_new;
        xk_new  = xk_old - tk*gradk;
        fxk_new = max(sqrt(sum((repmat(xk_new,[size(x,1),1])-x).^2,2)));
    end

    % CAUTION: position and radius of the resulting inscribed circle is taken as the one for which f(x_k) is minimum along iterations
    [~,k]   = min(iterations(:,3));
    x_final = iterations(k,1:2);
    r_final = iterations(k,3);
end