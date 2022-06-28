% Function registered a fragment image with respect to a fresco image (Matlab approach).
% 
% Inputs:
%   * im_fresco:           multi-channels fresco image
%   * frags_infos:         informations about fragments
%   * frags:               collection of fragments to register (without alpha channel)
%   * interpolation_type:  type of interpolation (nearest, bilinear, bicubic, etc.)
%   * verbose:             enables/disables display of debugging messages (true or false)
% 
% Outputs:
%   * frags2:  collection of registered fragments (without alpha channel)
function frags2 = get_registered_fragment_matlab( im_fresco, frags_infos, frags, interpolation_type, verbose )
    % We loop over all fragments
    frags2 = frags;

    for i=1:length(frags)
        % We get current fragment
        frag = frags{i};

        % We get fragment information
        im_frag_color  = frags_infos{frag.idx}.gray; % grayscale images are used to speedup
        half_frag_size = 0.5*frags_infos{frag.idx}.size;

        % We apply intensity-based registration algorithm
        angle       = deg2rad(frag.angle);
        sc          = cos(angle);
        ss          = sin(angle);
        translation = [frag.translation(1)-half_frag_size(1)*(sc-ss),frag.translation(2)-half_frag_size(2)*(sc+ss)];
        T1          = affine2d([sc,-ss,0; ss,sc,0; translation(2),translation(1),1]);
        optimizer   = registration.optimizer.RegularStepGradientDescent;
        metric      = registration.metric.MeanSquares;
        T2          = imregtform(im_frag_color, im_fresco, 'rigid', optimizer, metric, 'DisplayOptimization', 1, 'InitialTransformation', T1, 'PyramidLevels', 1);
        %[translation,angle,~] = get_transform_parameters(T2.T, size(im_fresco));
        %im_result = imwarp(im_frag_color, T2, 'OutputView', imref2d(size(im_fresco)));
        %figure, imshow(im_result,[]);

        % Message
        msg(sprintf('+ fragment %d | translation=[%f,%f], angle=%f', i, frags2{i}.translation(1), frags2{i}.translation(2), frags2{i}.angle), verbose);
    end
end