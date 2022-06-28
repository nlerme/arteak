% Function registered a fragment image with respect to a fresco image.
% 
% Inputs:
%   * im_fresco:                  multi-channels fresco image
%   * im_fresco_grad_x:           gradients of fresco image in x direction
%   * im_fresco_grad_y:           gradients of fresco image in y direction
%   * frags_infos:                informations about fragments
%   * input_frags:                collection of fragments to register (without alpha channel)
%   * interpolation_type:         type of interpolation (nearest, bilinear, bicubic, etc.)
%   * mean_inter_frags_distance:  mean Euclidean distance between adjacent fragments (>=0)
%   * max_inter_frags_distance:   maximum Euclidean distance between adjacent fragments (>=0)
%   * alpha:                      weighting parameter of the term E_a (>=0)
%   * eta:                        weighting parameter of the term E_inc(>=0)
%   * verbose:                    enables/disables display of debugging messages (true or false)
% 
% Outputs:
%   * output_frags:  collection of registered fragments (without alpha channel)
function output_frags = get_registered_fragment( im_fresco, im_fresco_grad_x, im_fresco_grad_y, frags_infos, input_frags, ...
                                                 interpolation_type, mean_inter_frags_distance, max_inter_frags_distance, alpha, eta, verbose )
    % We set parameters
    max_nb_iterations = 500;
    epsilon           = 0.1;

    % We loop over all fragments
    output_frags = input_frags;

    parfor i=1:length(output_frags)
    %for i=1:length(output_frags)
        % Message
        msg(sprintf('+ fragment %d', i), verbose);

        % We get current fragment
        frag = output_frags{i};

        % We get fragment images (grayscale images are used to speedup)
        im_frag_color = frags_infos{frag.idx}.gray;
        im_frag_alpha = frags_infos{frag.idx}.alpha;

        % We apply gradient descent on transformation parameters
        translation = frag.translation; % t=[ty,tx] in pixels
        angle       = frag.angle; % in degrees
        x0          = [translation,angle];
        iteration   = 0;
        xk_old      = x0;
        iterates    = [];
        [fxk_old,fresco_coords,frag_coords,fresco_int,frag_int] = eval_f(im_frag_alpha, im_frag_color, im_fresco, xk_old, interpolation_type, ...
                                                                         mean_inter_frags_distance, max_inter_frags_distance, alpha, eta);

        xk_new   = xk_old;
        fxk_new  = fxk_old;
        iterates = [iterates;[xk_new,fxk_new]];
        msg(sprintf('  + x%d=(x=%f,y=%f,theta=%f), f(x%d)=%f', iteration, xk_new(2), xk_new(1), xk_new(3), iteration, fxk_new), verbose);

        while true
            % Computation of the gradient
            grad_fxk_old = eval_grad_f(im_frag_alpha, im_frag_color, im_fresco, im_fresco_grad_x, im_fresco_grad_y, fresco_coords, frag_coords, ...
                                       fresco_int, frag_int, xk_old, interpolation_type, mean_inter_frags_distance, max_inter_frags_distance, alpha, eta);

            % We go along the next descent direction
            %-- fixed step size rule ---
%             tmin    = 0.1;
%             dk      = -grad_fxk_old/(eps+norm(grad_fxk_old));
%             xk_new  = (xk_old + tmin*dk);
%             [fxk_new,fresco_coords,frag_coords,fresco_int,frag_int] = eval_f(im_frag_alpha, im_frag_color, im_fresco, xk_new, interpolation_type, ...
%                                                                              mean_inter_frags_distance, max_inter_frags_distancen, alpha, eta);
            %---------------------------
            %------- backtracking ------
            tmax    = 10;
            alpha2  = 0.5;
            k       = 0;
            kmax    = 10;
            dk      = -grad_fxk_old/(eps+norm(grad_fxk_old));
            xk_new  = (xk_old + tmax*dk);
            [fxk_new,fresco_coords,frag_coords,fresco_int,frag_int] = eval_f(im_frag_alpha, im_frag_color, im_fresco, xk_new, interpolation_type, ...
                                                                             mean_inter_frags_distance, max_inter_frags_distance, alpha, eta);
            while fxk_new>fxk_old && k<kmax
                t       = (alpha2^k)*tmax;
                xk_new  = (xk_old + t*dk);
                [fxk_new,fresco_coords,frag_coords,fresco_int,frag_int] = eval_f(im_frag_alpha, im_frag_color, im_fresco, xk_new, interpolation_type, ...
                                                                                 mean_inter_frags_distance, max_inter_frags_distance, alpha, eta);
                k       = k+1;
            end
            %---------------------------

            % We decide if the descent stops or not
            if norm(xk_old-xk_new)<epsilon | iteration>=max_nb_iterations
                break;
            end

            msg(sprintf('  + x%d=(x=%f,y=%f,theta=%f), f(x%d)=%f', iteration, xk_new(2), xk_new(1), xk_new(3), iteration, fxk_new), verbose);

            iterates  = [iterates;[xk_new,fxk_new]];
            xk_old    = xk_new;
            fxk_old   = fxk_new;
            iteration = iteration+1;
        end

        output_frags{i}.translation = xk_new(1:2);
        output_frags{i}.angle       = xk_new(3);

%         if verbose
%             figure;
%             plot(1:size(iterates,1), iterates(:,4));
%             xlabel('Iteration');
%             ylabel('Error');
%             xlim([1,size(iterates,1)]);
%             grid;
%             [output_frags{i}.translation,output_frags{i}.angle]'
%         end
    end
end

function [fresco_coords,frag_coords] = get_transformed_fragment2( im_frag, xk, fresco_size )
    % We get some information
    center      = (0.5*size(im_frag));
    translation = xk(1:2);
	angle       = xk(3);

    % We project pixel coordinates of the fragment image and keep only those belonging to the domain of the fresco image
    [rows,cols]   = find(im_frag>0);
    fresco_coords = apply_forward_transform([rows,cols], translation, angle, center);
    keep          = find(fresco_coords(:,1)>=1 & fresco_coords(:,1)<=fresco_size(1) & fresco_coords(:,2)>=1 & fresco_coords(:,2)<=fresco_size(2));
    fresco_coords = fresco_coords(keep,:);
    frag_coords   = [rows(keep),cols(keep)];
end

function [fxk,fresco_coords,frag_coords,fresco_int,frag_int] = eval_f( im_frag_alpha, im_frag_color, im_fresco, xk, interpolation_type, ...
                                                                       mean_inter_frags_distance, max_inter_frags_distance, alpha, eta )
    % We get size of the fresco
    fresco_size = size(im_fresco);

    % We compute the domain of the transformed fragment
    [fresco_coords,frag_coords] = get_transformed_fragment2(im_frag_alpha, xk, fresco_size(1:2));

    % We check if fragment lies outside or not
    if isempty(fresco_coords) || isempty(frag_coords)
        fxk        = realmax;
        fresco_int = [];
        frag_int   = [];
        return;
    end

    % If not, we evaluate f
    fresco_int  = get_intensities(im_fresco, fresco_coords, interpolation_type);
    frag_int    = get_intensities(im_frag_color, frag_coords, interpolation_type);
    nb_pixels   = size(fresco_coords,1);
    nb_channels = size(im_frag_color,3);
    fxk         = alpha*eval_Ea(fresco_int, frag_int);
end

function result = eval_Ea( fresco_intensities, frag_intensities )
    result = sum((frag_intensities(:)-fresco_intensities(:)).^2);
end

function grad_fxk = eval_grad_f( im_frag_alpha, im_frag_color, im_fresco, im_fresco_grad_x, im_fresco_grad_y, fresco_coords, frag_coords, ...
                                 fresco_int, frag_int, xk, interpolation_type, mean_inter_frags_distance, max_inter_frags_distance, alpha, eta )
    if isempty(fresco_coords) || isempty(frag_coords) || isempty(fresco_int) || isempty(frag_int)
        grad_fxk = 0.0;
        return;
    end

    nb_pixels   = size(fresco_coords,1);
    center      = 0.5*size(im_frag_alpha);
    nb_channels = size(im_frag_color,3);
    angle       = deg2rad(xk(3));

    % Computation of the gradient
    fresco_grad_x = get_intensities(im_fresco_grad_x, fresco_coords, interpolation_type);
    fresco_grad_y = get_intensities(im_fresco_grad_y, fresco_coords, interpolation_type);
    grad_fxk      = zeros(1,3);

    for k=1:nb_pixels
        i = frag_coords(k,1);
        j = frag_coords(k,2);
        RR = [-sin(angle),-cos(angle);cos(angle),-sin(angle)]*[j-center(2);i-center(1)];
        grad_fxk(1) = grad_fxk(1) + (2*(frag_int(k)-fresco_int(k))*fresco_grad_y(k));
        grad_fxk(2) = grad_fxk(2) + (2*(frag_int(k)-fresco_int(k))*fresco_grad_x(k));
        grad_fxk(3) = grad_fxk(3) + (2*(frag_int(k)-fresco_int(k))*[fresco_grad_x(k),fresco_grad_y(k)]*RR);
    end
    
    grad_fxk = -grad_fxk;
end