%fn = '../../data/regular/PierodellaFrancesca_Resurrezione_730x826/PierodellaFrancesca_Resurrezione_730x826_109_0_0_0/frag_eroded/frag_eroded_10.png';
%[im_src_color,~,im_src_alpha] = imread(fn);
%im_src_color = im2double(im_src_color);
%im_src_alpha = (im_src_alpha>0);
%im_src_color = padarray(im_src_color, double([70,70]), 'both');
%im_src_alpha = padarray(im_src_alpha, double([70,70]), 'both');
%im_src_gray  = rgb2gray(im_src_color);

%figure, imshow(im_src_color,[]);
%figure, imshow(im_src_alpha,[]);

%figure, imshow(inpaintExemplar(im_src_color, ~im_src_alpha, 'FillOrder', 'tensor', 'PatchSize', [3,3]), []);
%figure, imshow(inpaintExemplar(im_src_color, ~im_src_alpha, 'FillOrder', 'tensor', 'PatchSize', [5,5]), []);
%figure, imshow(inpaintExemplar(im_src_color, ~im_src_alpha, 'FillOrder', 'gradient', 'PatchSize', [3,3]), []);
%figure, imshow(inpaintExemplar(im_src_color, ~im_src_alpha, 'FillOrder', 'gradient', 'PatchSize', [5,5]), []);