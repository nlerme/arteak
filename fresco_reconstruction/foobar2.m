clear all;
close all;
clc;

results_dir = ['..' filesep 'results' filesep 'tests'];
data_dir    = ['..' filesep 'data' filesep 'DB1'];
fresco_name = 'Michelangelo_ThecreationofAdam_1707x775';
config_name = [fresco_name '_2019-2-15_18.46.1'];

fresco_dir   = [data_dir filesep fresco_name];
config_dir   = [fresco_dir filesep config_name];
frags_dir    = [config_dir filesep 'frag_eroded'];
results_dir2 = [results_dir filesep fresco_name filesep config_name];
frag_fns     = get_matching_files(frags_dir, '.*\.png');

if ~exist(results_dir2)
    mkdir(results_dir2);
end

for k=2
%for k=1:numel(frag_fns)
%parfor k=1:numel(frag_fns)
    disp(sprintf('+ fragment %d', k));

    % Reading and thresholding
    [im_frag_color,~,im_frag_alpha] = imread(frag_fns{k});
    im_frag_alpha = (im_frag_alpha>0);
    im_frag_color = padarray(im_frag_color, [30,30]);
    im_frag_alpha = padarray(im_frag_alpha, [30,30]);

    % Slight erosion
    im_frag_alpha = imerode(im_frag_alpha, strel('disk', 2));
    idx = find(im_frag_alpha==0);
    for c=1:size(im_frag_color,3)
        im_tmp = im_frag_color(:,:,c);
        im_tmp(idx) = 0;
        im_frag_color(:,:,c) = im_tmp;
    end

    % Construction of the mask and its border
    im_frag_mask = logical(1-im_frag_alpha);
    im_border = imgradient(im_frag_mask)>0;

    % Inpainting
    im_result = inpaintExemplar(im_frag_color, im_frag_mask, 'FillOrder', 'tensor', 'PatchSize', 5);

    % Construction of the inpainted image
    im_frag_mask2 = imdilate(im_frag_alpha, strel('disk', 60));
    idx = find(im_frag_mask2==0);
    for c=1:size(im_frag_color,3)
        im_tmp = im_result(:,:,c);
        im_tmp(idx) = 0;
        im_result(:,:,c) = im_tmp;
    end

    % Saving of the resulting image
    im_result2 = blend_images(im_result, im_border, 0.5);
    %imwrite(im_result2, sprintf('%s%smichelangelo_%03d.png', results_dir2, filesep, k));
    figure('units', 'normalized', 'outerposition', [0 0 1 1], 'visible', 'on'), imshow(im_result2,[]);
end