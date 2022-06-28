% Function returning a thresholded confidence map.
% 
% Inputs:
%   * im_map   :  grayscale confidence map with normalized intensities in [0,1]
%   * threshold:  threshold (in [0,1])
%   * radius   :  radius of the morphological dilation with square as structuring element (in N_{>0})
% 
% Outputs:
%   * im_res:  binarized image (in {0,1})
function im_res = binarize_confidence_map( im_map, threshold, radius )
    im_res = im_map;

    % We threshold the confidence map
    if threshold>=0 && threshold<=1
%         [h,~] = imhist(im_res, 256);
%         ch = cumsum(h./sum(h));
%         t = 0;
%         alpha = 0.92;
%         while ch(t+1)<alpha
%             t = t+1;
%         end
%         im_res = (im_res>=t);
        im_res = (im_res>=threshold);
    end

    % We apply morphological dilation to the thresholded map
    if radius>0
        im_res = imdilate(im_res, strel('square',2*round(double(radius))+1));
    end
end