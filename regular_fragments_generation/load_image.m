% This function loads an image and eventually convert it to grayscale levels
function im_src = load_image( filename, grayscale_conversion )
    % We check if the image exists
    if ~isfile(filename)
        error('the image %s cannot be found', filename);
    end

    % We load the image
    im_src = imread(filename);

    % We eventually convert it into grayscale levels
    if grayscale_conversion && size(im_src,3)>1
        im_src = rgb2gray(im_src);
    end
end