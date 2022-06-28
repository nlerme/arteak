% Function registered a fragment image with respect to a fresco image (greedy approach).
% 
% Inputs:
%   * im_fresco:           multi-channels fresco image
%   * frags_infos:         informations about fragments
%   * frags:               collection of fragments to register (without alpha channel)
%   * translation_range:   range for displacement of fragments (for both tx and ty)
%   * angle_range:         range for angle of rotation of fragments
%   * interpolation_type:  type of interpolation (nearest, bilinear, bicubic, etc.)
%   * verbose:             enables/disables display of debugging messages (true or false)
% 
% Outputs:
%   * frags2:  collection of registered fragments (without alpha channel)
function frags2 = get_registered_fragment_greedy( im_fresco, frags_infos, frags, translation_range, angle_range, interpolation_type, verbose )
    % We loop over all fragments
    frags2 = frags;

    parfor i=1:length(frags)
        % We get current fragment
        frag = frags{i};

        % We get fragment images
        im_frag_color = frags_infos{frag.idx}.gray; % grayscale images are used to speedup
        im_frag_alpha = frags_infos{frag.idx}.alpha;

        % We apply grid search on transformation parameters
        [delta_tx,delta_ty,delta_angle] = meshgrid(translation_range, translation_range, angle_range);
        delta_tx                        = delta_tx(:);
        delta_ty                        = delta_ty(:);
        delta_angle                     = delta_angle(:);
        iterates                        = zeros(length(delta_tx), 4);

        for k=1:length(delta_tx)
            %disp(sprintf('k=%d | translation=(%f,%f), angle=%f', k, delta_ty(k), delta_tx(k), delta_angle(k)));
            translation   = frag.translation+[delta_ty(k),delta_tx(k)];
            angle         = frag.angle+delta_angle(k);
            fx            = eval_f(im_frag_alpha, im_frag_color, im_fresco, translation, angle, interpolation_type);
            %iterates(k,:) = [delta_ty(k),delta_tx(k),delta_angle(k),fx];
            iterates(k,:) = [translation,angle,fx];
        end

        % Best parameters are set as those minimizing the involved functional
        [~,idx]               = min(iterates(:,4));
        frags2{i}.translation = iterates(idx,1:2);
        frags2{i}.angle       = iterates(idx,3);

        % Message
        msg(sprintf('+ fragment %d | translation=[%f,%f], angle=%f', i, frags2{i}.translation(1), frags2{i}.translation(2), frags2{i}.angle), verbose);
    end
end

function fxk = eval_f( im_frag_alpha, im_frag_color, im_fresco, translation, angle, interpolation_type )
    fresco_size                 = size(im_fresco);
    [fresco_coords,frag_coords] = get_transformed_fragment(im_frag_alpha, translation, angle, fresco_size(1:2));
    fresco_int                  = get_intensities(im_fresco, fresco_coords, interpolation_type);
    frag_int                    = get_intensities(im_frag_color, frag_coords, interpolation_type);
    fxk                         = mean((frag_int(:)-fresco_int(:)).^2);
end