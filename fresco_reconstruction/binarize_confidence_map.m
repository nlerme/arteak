% Function returning a thresholded confidence map.
% 
% Inputs:
%   * im_map   :  grayscale confidence map (intensities must be in [0,1])
%   * threshold:  decision threshold (in [0,1])
%   * radius   :  radius of the morphological dilation (in N_{>=0})
% 
% Outputs:
%   * im_result:  binarized image (in {0,1})
function im_result = binarize_confidence_map( im_map, threshold, radius )
    im_result = im_map;

    % We threshold the confidence map
    if threshold>=0 && threshold<=1
%         [h,~] = imhist(im_result, 256);
%         ch = cumsum(h./sum(h));
%         t = 0;
%         alpha = 0.92;
%         while ch(t+1)<alpha
%             t = t+1;
%         end
%         im_result = (im_result>=t);
        im_result = (im_result>=threshold);
    end

    % We apply morphological dilation to the thresholded map
    if radius>0
        im_result = imdilate(im_result, strel('square',2*round(double(radius))+1));
    end
end