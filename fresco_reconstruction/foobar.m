% Cleanup
clc;
clear all;
close all;

% We either generate distribution of 2D gaussians or load desired confidence map
% N = 2000;
% n = 30;
% im_map = zeros(512,'double');
% for k=1:n
%     x = randi([1,size(im_map,2)]);
%     y = randi([1,size(im_map,1)]);
%     im_tmp = zeros(size(im_map),'double');
%     im_tmp(x,y) = 1;
%     sigma = randi([10,40]);
%     im_tmp = imgaussfilt(im_tmp,sigma);
%     im_tmp = im_tmp ./ max(im_tmp(:));
%     im_map = max(im_map,im_tmp);
% end
%--------------
frag_idx = 1;
fn = sprintf('../results/tests/Michelangelo_ThecreationofAdam_1707x775/Michelangelo_ThecreationofAdam_1707x775_2019-2-15_18.46.1/confidence_map_%04d.jpg', frag_idx);
im_map = im2double(imread(fn));

% We pick some random pixels and display them
threshold = 0.1*max(im_map(:));
N = 10000;
tic;
coords = get_random_pixel(im_map, threshold, N);
toc;
figure('units','normalized','outerposition',[0 0 1 1],'visible','on');
imshow(im_map,[]);
hold on;
plot(coords(:,2), coords(:,1), 'r+', 'MarkerSize', 5);