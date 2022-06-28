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
%   * lambda:                     weighting parameter of the term E_no (>=0)
%   * beta:                       weighting parameter of the term E_sf(>=0)
%   * kappa:                      weighting parameter of the term E_c (>=0)
%   * verbose:                    enables/disables display of debugging messages (true or false)
% 
% Outputs:
%   * output_frags:  collection of registered fragments (without alpha channel)
function output_frags = get_registered_fragments( im_fresco, im_fresco_grad_x, im_fresco_grad_y, frags_infos, input_frags, ...
                                                  interpolation_type, mean_inter_frags_distance, max_inter_frags_distance, lambda, beta, kappa, verbose )
    % We set parameters
    max_nb_iterations = 200;
    epsilon           = 0.01;
    lambda            = 100.0;

    % We apply gradient descent on transformation parameters
    fresco_size  = size(im_fresco);
    output_frags = input_frags;
    x0           = zeros(length(output_frags), 3);

    for i=1:length(output_frags)
        frag        = output_frags{i};
        translation = frag.translation; % translation [ty,tx] in pixels
        angle       = frag.angle; % angle of rotation in degrees
        x0(i,:)     = [translation,angle];
    end

    iteration = 1;
    xk_old    = x0;
    iterates  = [];
    tic;
    [fxk_old,frag1_coords,frag2_coords,h1_diff,output_frags] = eval_f(im_fresco, frags_infos, output_frags, xk_old, interpolation_type, ...
                                                                      mean_inter_frags_distance, max_inter_frags_distance, lambda, beta, kappa);
    toc;

    %--- For debugging (neighborhood relationships) ---
    for i=1:length(output_frags)
        output_frags{i}.color_idx = 1;
    end
    %return;
    %--------------------------------------------------

    xk_new   = xk_old;
    fxk_new  = fxk_old;
    iterates = [iterates;fxk_new];
    msg(sprintf('  + f(x%d)=%f', iteration, fxk_new), verbose);
    %for i=1:size(xk_new,1)
    %    msg(sprintf('    + f%d=(%f,%f,%f)', i, xk_new(i,1), xk_new(i,2), xk_new(i,3)), verbose);
    %end

    while true
        % Computation of the gradient
        grad_fxk_old = eval_grad_f(im_fresco, im_fresco_grad_x, im_fresco_grad_y, frag1_coords, frag2_coords, h1_diff, ...
                                   frags_infos, output_frags, xk_old, interpolation_type, mean_inter_frags_distance, max_inter_frags_distance, lambda, beta, kappa);

        % We go along the next descent direction
        %--- fixed step size rule ---
        tmin    = 0.1;
        for i=1:size(grad_fxk_old,1)
          grad_fxk_old(i,:) = grad_fxk_old(i,:)/(eps+norm(grad_fxk_old(i,:)));
        end
        dk = -grad_fxk_old;
        xk_new  = (xk_old + tmin*dk);
        [fxk_new,frag1_coords,frag2_coords,h1_diff,output_frags] = eval_f(im_fresco, frags_infos, output_frags, xk_new, interpolation_type, mean_inter_frags_distance, max_inter_frags_distance, lambda, eta, kappa);
        %----------------------------
        %------- backtracking -------
%         alpha   = 0.5;
%         k       = 0;
%         kmax    = 10;
%         tmax    = 0.1;
%         for i=1:size(grad_fxk_old,1)
%            grad_fxk_old(i,:) = grad_fxk_old(i,:)/(eps+norm(grad_fxk_old(i,:)));
%         end
%         dk = -grad_fxk_old;
%         xk_new  = (xk_old + tmax*dk);
%         [fxk_new,frag1_coords,frag2_coords,h1_diff,output_frags] = eval_f(im_fresco, frags_infos, output_frags, xk_new, interpolation_type, mean_inter_frags_distance, max_inter_frags_distance, lambda, beta, kappa);
%         while fxk_new>fxk_old && k<kmax
%             t       = (alpha^k)*tmax;
%             xk_new  = (xk_old + t*dk);
%             [fxk_new,frag1_coords,frag2_coords,h1_diff,output_frags] = eval_f(im_fresco, frags_infos, output_frags, xk_new, interpolation_type, mean_inter_frags_distance, max_inter_frags_distance, lambda, beta, kappa);
%             k       = k+1;
%         end
        %---------------------------

        % We decide if the descent stops or not
        %if norm(xk_old-xk_new)^2/numel(xk_new)<epsilon | iteration>=max_nb_iterations
        %    break;
        %end
        if iteration>=max_nb_iterations
            break;
        end

        msg(sprintf('  + f(x%d)=%f | n=%f', iteration, fxk_new, norm(xk_old-xk_new)^2/numel(xk_new)), verbose);
        %for i=1:size(xk_new,1)
        %    msg(sprintf('    + f%d=(%f,%f,%f)', i, xk_new(i,1), xk_new(i,2), xk_new(i,3)), verbose);
        %end

        %------------------------------------
        tmp = output_frags;
        for i=1:length(tmp)
            tmp{i}.translation = xk_new(i,1:2);
            tmp{i}.angle       = xk_new(i,3);
        end
        [~,~,im_result] = get_reconstructed_fresco(im_fresco, frags_infos, tmp, interpolation_type, [0]);
        imwrite(im_result, sprintf('fresque_recalee_%04d.png', iteration));
        %------------------------------------

        iterates  = [iterates;fxk_new];
        xk_old    = xk_new;
        fxk_old   = fxk_new;
        iteration = iteration+1;
    end

    for i=1:length(output_frags)
        output_frags{i}.translation = xk_new(i,1:2);
        output_frags{i}.angle       = xk_new(i,3);
    end

    if verbose
        figure;
        plot(1:length(iterates), iterates);
        xlabel('Iteration');
        ylabel('Error');
        xlim([1,length(iterates)]);
        grid;
    end
end

function grad_fxk = eval_grad_f( im_fresco, im_fresco_grad_x, im_fresco_grad_y, frag1_coords, frag2_coords, h1_diff, frags_infos, ...
                                 output_frags, xk, interpolation_type, mean_inter_frags_distance, max_inter_frags_distance, lambda, beta, kappa )
    % We loop over all couples of fragments
    grad_fxk                          = zeros(size(xk));
    mean_inter_frags_squared_distance = mean_inter_frags_distance^2;

    for i=1:size(xk,1)
        for j=1:size(xk,1)
            % We discard the case where both fragments are the same
            if i==j
                continue;
            end

            % We get current couple of fragments
            frag1 = output_frags{i};
            frag2 = output_frags{j};

            % We get fragment images (grayscale images are used to speedup)
            im_frag1_alpha = frags_infos{frag1.idx}.alpha;
            im_frag2_alpha = frags_infos{frag2.idx}.alpha;

            % We get transformation parameters of both fragments
            center1      = flip(0.5*size(im_frag1_alpha)');
            translation1 = flip(xk(i,1:2)');
            angle1       = deg2rad(xk(i,3));
            center2      = flip(0.5*size(im_frag2_alpha)');
            translation2 = flip(xk(j,1:2)');
            angle2       = deg2rad(xk(j,3));

            % Rotation matrices
            R1  = [cos(angle1),-sin(angle1);sin(angle1),cos(angle1)];
            R2  = [cos(angle2),-sin(angle2);sin(angle2),cos(angle2)];
            R1p = [-sin(angle1),-cos(angle1);cos(angle1),-sin(angle1)];
            R2p = [-sin(angle2),-cos(angle2);cos(angle2),-sin(angle2)];

            % We loop over pixels coordinates of first fragment projected into the frame of the second one
            for k=1:size(frag2_coords{i}{j},1)
                % Gradient of h_1
                d       = h1_diff{i}{j}(k,:);
                snd     = norm(d)^2;
                grad_h1 = flip(-(lambda*pi*d)/mean_inter_frags_squared_distance*sin((pi*snd)/mean_inter_frags_squared_distance)*(snd<=mean_inter_frags_squared_distance));

                % Partial derivative of t_y^1
                grad_fxk(i,1) = grad_fxk(i,1) + grad_h1*[sin(angle2);cos(angle2)];

                % Partial derivative of t_x^1
                grad_fxk(i,2) = grad_fxk(i,2) + grad_h1*[cos(angle2);-sin(angle2)];

                % Partial derivative of alpha_1
                grad_fxk(i,3) = grad_fxk(i,3) + grad_h1*(R2')*R1p*(flip(frag1_coords{i}{j}(k,:)')-center1);

                % Partial derivative of t_y^2
                grad_fxk(j,1) = grad_fxk(j,1) + grad_h1*[-sin(angle2);-cos(angle2)];

                % Partial derivative of t_x^2
                grad_fxk(j,2) = grad_fxk(j,2) + grad_h1*[-cos(angle2);sin(angle2)];

                % Partial derivative of alpha_2
                grad_fxk(j,3) = grad_fxk(j,3) + grad_h1*(R2p')*(R1*(flip(frag1_coords{i}{j}(k,:)')-center1)+translation1-translation2);
            end
        end
    end
end

function [fxk,frag1_coords,frag2_coords,h1_diff,output_frags] = eval_f( im_fresco, frags_infos, input_frags, xk, interpolation_type, ...
                                                                        mean_inter_frags_distance, max_inter_frags_distance, lambda, beta, kappa )
    % We set squared fragments distance and output fragments
    mean_inter_frags_squared_distance = mean_inter_frags_distance^2;
    output_frags                      = input_frags;

    % We get size of the fresco
    fresco_size = size(im_fresco);

    % We loop over all couples of fragments
    nb_frags     = length(output_frags);
    neighbors    = zeros(nb_frags,nb_frags,'logical');
    frag1_coords = cell(nb_frags,nb_frags);
    frag2_coords = cell(nb_frags,nb_frags);
    h1_diff      = cell(nb_frags,nb_frags);
    h1           = cell(nb_frags,nb_frags);
    fxk          = 0.0;

    for i=1:size(xk,1)
        output_frags{i}.neighbors = [];

        for j=1:size(xk,1)
            % We discard the case where both fragments are the same
            if i==j
                continue;
            end

            % We get current couple of fragments
            frag1 = output_frags{i};
            frag2 = output_frags{j};

            % We get fragment images (grayscale images are used to speedup)
            im_frag1_alpha = frags_infos{frag1.idx}.alpha;
            im_frag2_alpha = frags_infos{frag2.idx}.alpha;
            im_frag2_nny   = frags_infos{frag2.idx}.nny;
            im_frag2_nnx   = frags_infos{frag2.idx}.nnx;

            % We compute coordinates of fragment 1 registered with respect to fragment 2
            [frag1_coords{i}{j},frag2_coords{i}{j}] = get_transformed_fragment2(im_frag1_alpha, im_frag2_alpha, xk(i,:), xk(j,:), fresco_size(1:2));

            % We compute f
            ps_y          = get_intensities(im_frag2_nny, frag2_coords{i}{j}, 'nearest');
            ps_x          = get_intensities(im_frag2_nnx, frag2_coords{i}{j}, 'nearest');
            h1_diff{i}{j} = (frag2_coords{i}{j}-[ps_y,ps_x]);
            snd           = sum(h1_diff{i}{j}.^2,2);
            h1            = lambda*0.5*(1+cos((pi*snd)/mean_inter_frags_squared_distance)).*(snd<=mean_inter_frags_squared_distance);
            fxk           = fxk + sum(h1);

            % We check if that couple of fragments are neighbors or not
            if min(sqrt(snd))<=max_inter_frags_distance
                output_frags{i}.neighbors = [output_frags{i}.neighbors,j];
            end
        end
    end
end

function [frag1_coords,frag2_coords] = get_transformed_fragment2( im_frag1, im_frag2, xk1, xk2, fresco_size )
    % We get some information
    center1      = 0.5*size(im_frag1);
    translation1 = xk1(1:2);
	angle1       = xk1(3);
    center2      = 0.5*size(im_frag2);
    translation2 = xk2(1:2);
	angle2       = xk2(3);

    % We project pixel coordinates of the first fragment in the frame of the second one
    [rows,cols]   = find(im_frag1>0);
    frag1_coords  = [rows,cols];
    frag2_coords  = apply_forward_backward_transforms(frag1_coords, translation1, angle1, center1, translation2, angle2, center2);
    keep          = find(frag2_coords(:,1)>=1 & frag2_coords(:,1)<=size(im_frag2,1) & frag2_coords(:,2)>=1 & frag2_coords(:,2)<=size(im_frag2,2));
    frag1_coords  = frag1_coords(keep,:);
    frag2_coords  = frag2_coords(keep,:);
end