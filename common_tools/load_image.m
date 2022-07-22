% This function loads an image and eventually convert it to grayscale.
% 
% Inputs:
%   * filename:      name of the image to load
%   * to_grayscale:  flag indicating if the resulting image is converted to grayscale
% 
% Outputs:
%   * im_src:    RGB/grayscale image
%   * im_alpha:  alpha channel (can be empty)
function [im_src,im_alpha] = load_image( filename, to_grayscale )
    % We check if the image exists
    if ~isfile(filename)
        im_src   = [];
        im_alpha = [];
        return;
    end

    % We load the image
    [im_src,~,im_alpha] = imread(filename);

    % We eventually convert it into grayscale levels
    if to_grayscale && size(im_src,3)>1
        im_src = rgb2gray(im_src);
    end
end