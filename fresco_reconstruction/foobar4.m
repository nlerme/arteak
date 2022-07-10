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

if ~isdir(results_dir2)
    mkdir(results_dir2);
end

frag_idx = 2;
[im_frag_color,~,im_frag_alpha] = imread(frag_fns{frag_idx});
im_frag_alpha = (im_frag_alpha>0);

im_d1 = bwdist(im_frag_alpha, 'euclidean');
im_d2 = bwdist(~im_frag_alpha, 'euclidean');
im_d3 = im_d1+im_d2;
figure, imshow((im_d2-10).^2,[]);
