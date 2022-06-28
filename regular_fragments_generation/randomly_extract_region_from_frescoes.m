% This function randomly extracts a region of a given image
function im_res = randomly_extract_region_from_frescoes( filenames, grayscale_conversion, fragment_size )
    extracted = false;

    while ~extracted
        ri       = randi([1,numel(filenames)]);
        im_src   = load_image(filenames{ri}, grayscale_conversion);
        img_size = size(im_src);

        if img_size(1)>=fragment_size(1) && img_size(2)>=fragment_size(2)
            p         = [randi([1,img_size(1)-fragment_size(1)+1]),randi([1,img_size(2)-fragment_size(2)+1])];
            q         = p+fragment_size-1;
            im_res    = im_src(p(1):q(1),p(2):q(2),:);
            extracted = true;
        end
    end
end