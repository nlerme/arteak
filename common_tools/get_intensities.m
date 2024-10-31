% Function returning interpolated image intensities. 
% Pixel coordinates are assumed to lie into the image domain.
% 
% Inputs:
%   * im_src:              multi-channels image
%   * coords:              pixel coordinates (nx2 matrix of reals [py_1,px_1;...;py_1,px_n])
%   * interpolation_type:  type of interpolation (e.g. nearest, linear, bicubic, etc.)
% 
% Outputs:
%   * intensities:  image intensities with MxN matrix (where M is the number of pixels and N is the number of channels)
function intensities = get_intensities( im_src, coords, interpolation_type )
    intensities = zeros(size(coords,1),size(im_src,3));
    nb_channels = size(im_src,3);
    im_src      = double(im_src);

    for k=1:nb_channels
        im_tmp           = im_src(:,:,k);
        intensities(:,k) = interp2(im_tmp, coords(:,2), coords(:,1), interpolation_type);
    end
end
