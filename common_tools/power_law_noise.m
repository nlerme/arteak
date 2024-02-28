% This function generates a power law noise.
% 
% Inputs:
%   * image_size:  output image size (2D vector of integers)
%   * exponent:    exponent of the decreasing function (>0)
% 
% Outputs:
%   * im_noise:  MxN noise image with normalized intensities (in [0,1])
function im_noise = power_law_noise( image_size, exponent )
    m = randn(image_size);
    mf = fft2(m);
    di = ((1:image_size(1))-round(0.5*image_size(1))).^2;
    dj = ((1:image_size(2))-round(0.5*image_size(2))).^2;
    dd = sqrt(di'+dj);
    f = fftshift(dd.^-exponent);
    f(isinf(f)) = 1;
    ff = mf.*f;
    b = real(ifft2(ff));
    im_noise = rescale(b, 0.0, 1.0);
end