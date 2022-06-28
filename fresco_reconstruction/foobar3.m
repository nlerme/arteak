close all;
gt_angle = 0.0;
gt_translation = [0;30];
im_v1 = im2double(imread('brain.png'));
im_v2 = (im_v1>0.1);
[coords,~] = get_transformed_fragment(im_u1, flip(gt_translation'), angle, size(im_v1));

%im_u2 = get_transformed_fragment(im_u2, flip(gt_translation'), angle, size(im_v2));
%figure, imshow(im_u1,[]);
figure, imshow(im_u2,[]);
return;

[im_u1_grad_x,im_u1_grad_y] = imgradientxy(im_u1, 'sobel');

% We set parameters
max_nb_iterations = 30;
epsilon           = 0.0001;

% We apply gradient descent on transformation parameters
translation = round(0.5*size(im_v1))'-gt_translation; % t=(tx,ty)
angle       = 0.0; % in degrees
x0          = [translation;angle];
iteration   = 0;
ok          = true;
xk_new      = x0;
[fc1,fc2]   = get_transformed_fragment(im_u2, flip(translation'), angle, size(im_v1));
fc1
idx = sub2ind(size(im_v1), fc1(:,1), fc1(:,2));
im_tmp = zeros(size(im_v1));
im_tmp(idx) = 1;
figure, imshow(im_tmp,[]);
figure, imshow(im_u2,[]);
return;
fc1_int     = get_intensities(im_fresco, fc1, interpolation_type);
fc2_int     = get_intensities(im_frag_color, fc2, interpolation_type);
fxk_new     = mean((fc2_int-fc1_int).^2);
iterates    = [];

disp('--------------------------------------------------');
while ok
    disp(sprintf('+ x%d=(x=%f,y=%f,theta=%f), f(x%d)=%f', iteration, xk_new(1), xk_new(2), xk_new(3), iteration, fxk_new));
    iterates = [iterates,[xk_new',fxk_new]];

    grad_fxk = zeros(size(xk_new));
    for kk=1:size(fc1,1)
        i           = fc1(kk,1);
        j           = fc1(kk,2);
        translation = flip(xk_new(1:2)');
        angle       = xk_new(3);
        q           = apply_backward_transform([i,j], translation, angle, frag_center);

        if q(1)<1 || q(1)>frag_size(1) || q(2)<1 || q(2)>frag_size(2)
            continue;
        end

        if im_frag_alpha(round(q(1)), round(q(2)))==0
            continue;
        end

        theta          = deg2rad(angle);
        influence      = 2*(interp2(im_frag_color, q(2), q(1), interpolation_type)-im_fresco(i,j));
        %matrix_model   = [0,0;0,0;-q(2)*sin(theta)+q(1)*cos(theta),-q(2)*cos(theta)-q(1)*sin(theta)];
        matrix_model   = [0,0;0,1;0,0];
        grad_x         = interp2(im_u1_grad_x, q(2), q(1), interpolation_type);
        grad_y         = interp2(im_u1_grad_y, q(2), q(1), interpolation_type);
        image_gradient = [grad_x;grad_y];
        grad_fxk       = grad_fxk + influence*matrix_model*image_gradient;
    end
    %grad_fxk

    % Search of minimum of univariate function
    tmin = 0.1;

    % We push along the next descent direction
    xk_old  = xk_new;
    fxk_old = fxk_new;
    dk      = grad_fxk;
    xk_new  = (xk_old + tmin*dk);

    [fc1,fc2] = get_transformed_fragment(im_frag_alpha, flip(xk_new(1:2)'), xk_new(3), fresco_size);
    fc1_int   = get_intensities(im_fresco, fc1, interpolation_type);
    fc2_int   = get_intensities(im_frag_color, fc2, interpolation_type);
    fxk_new   = mean((fc2_int-fc1_int).^2);

    % We decide if the descent stops or not
    %if norm(xk_new-xk_old)/max(1,norm(xk_old))<epsilon | abs(fxk_new-fxk_old)/max(1,fxk_old)<epsilon | iteration>=max_nb_iterations
    %    ok = false;
    %end

    if iteration>=max_nb_iterations
        ok = false;
    end

    iteration = iteration+1;
end