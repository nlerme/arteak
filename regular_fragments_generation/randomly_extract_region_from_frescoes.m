% This function extracts a rectangular region from a collection of fresco 
% images. The fresco image is chosen uniformly at random (modulo the fact 
% that it is large enough from which it is extracted).
% 
% Inputs:
%   * filenames:      full filename of fresco images (cell array)
%   * to_grayscale:   flag indicating if resulting image is converted to grayscale (boolean)
%   * fragment_size:  desired size of fragment (2D vector of integers)
% 
% Outputs:
%   * im_res:  resulting image
function im_res = randomly_extract_region_from_frescoes( filenames, to_grayscale, fragment_size )
    extracted = false;

    while ~extracted
        ri         = randi([1,numel(filenames)]);
        [im_src,~] = load_image(filenames{ri}, to_grayscale);
        img_size   = size(im_src);

        if img_size(1)>=fragment_size(1) && img_size(2)>=fragment_size(2)
            p         = [randi([1,img_size(1)-fragment_size(1)+1]),randi([1,img_size(2)-fragment_size(2)+1])];
            q         = p+fragment_size-1;
            im_res    = im_src(p(1):q(1),p(2):q(2),:);
            extracted = true;
        end
    end
end