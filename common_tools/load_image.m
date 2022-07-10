% This function loads an image and eventually convert it to grayscale levels
function [im_src,im_alpha] = load_image( filename, grayscale_conversion )
    % We check if the image exists
    if ~isfile(filename)
        im_src   = [];
        im_alpha = [];
        return;
    end

    % We load the image
    [im_src,~,im_alpha] = imread(filename);

    % We eventually convert it into grayscale levels
    if grayscale_conversion && size(im_src,3)>1
        im_src = rgb2gray(im_src);
    end
end