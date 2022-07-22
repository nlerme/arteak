% This function returns the fragment images superimposed on the fresco model.
% Notice that this function is simular to `get_reconstructed_fresco' but 
% probably faster since fragment images are assumed to be rectangular regions.
% 
% Inputs:
%   * im_fresco_color:   RGB fresco image (uint8)
%   * im_frags:          collection of fragment images (cell array)
%   * frags_sol:         solution composed of fragments (cell array)
%   * background_color:  background color of the reconstructed fresco image ([0,1]^3)
%   * im_fresco_gray:    grayscale conversion of the fresco color image (can be empty)
% 
% Outputs:
%   * im_rec:  reconstructed fresco image (uint8)
function im_rec = reconstruct_fresco( im_fresco_color, im_frags, frags_sol, background_color, im_fresco_gray )
    % We create an empty color image
    fresco_size = size(im_fresco_color);

    if isempty(im_fresco_gray)
        im_rec = ones(fresco_size,'uint8');

        for k=1:fresco_size(3)
            im_rec(:,:,k) = uint8(255.0*background_color(k));
        end
    else
        if fresco_size(3)>1
            im_rec = repmat(im_fresco_gray, [1,1,fresco_size(3)]);
        else
            im_rec = im_fresco_gray;
        end
    end

    % We loop over fragments
    for k=1:numel(frags_sol)
        % We get translation and angle of rotation
        translation = frags_sol{k}.translation;
        angle       = frags_sol{k}.angle;
        idx         = frags_sol{k}.idx;

        % We get fragment image (rgb + alpha channels)
        im_frag     = im_frags(idx);
        im_frag     = im_frag{1};
        im_color    = im_frag(:,:,1:3);
        im_alpha    = im_frag(:,:,4);

        % We add transformed fragment to the result
        im_color                      = imrotate(im_color, angle);
        [r,c]                         = find(im_alpha>0);
        frag_size                     = [max(r)-min(r),max(c)-min(c)]+1;
        p                             = translation-floor(frag_size*0.5);
        q                             = p+frag_size-1;
        im_rec(p(1):q(1),p(2):q(2),:) = uint8(im_color(min(r):max(r),min(c):max(c),:));
    end
end