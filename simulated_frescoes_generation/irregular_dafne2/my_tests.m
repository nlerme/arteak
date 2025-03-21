clear all;
close all;
clc;

%-------------------

image_size = [512,512];
nb_points = 100;
m1=25.0;
m2=50.0;
weights = (m2-m1)*rand(1,nb_points)+m1;

p = randperm(prod(image_size));
offsets = p(1:nb_points);
[y,x] = ind2sub(image_size, offsets');
pts = [y,x];
%im_pts = zeros(image_size, 'logical');
%im_pts(pts) = 1;
[x,y] = meshgrid(1:image_size(2), 1:image_size(2));
x = x(:);
y = y(:);
tic;
D = pdist2([y,x], pts, 'euclidean');
[~,idx] = min(D+repmat(weights,[size(D,1),1]),[],2);
im_result = zeros(image_size);
offsets2 = sub2ind(image_size, y, x);
im_result(offsets2) = idx;
toc;
figure, imshow(imgradient(im_result)>0,[]);
% dists = realmax*ones(prod(image_size),1);
% nn = zeros(prod(image_size),1);
% for k=1:nb_points
%     d = sqrt(sum(([y,x]-coords(k,:)).^2,2));
%     cmp = (d<dists);
%     dists(cmp) = d(cmp);
%     nn(cmp) = k;
% end
% im_dmap = reshape(dists, image_size);
% im_nn = reshape(nn, image_size);

%figure, imshow(im_pts,[]);
%figure, imshow(im_dmap,[]);
%figure, imshow(im_nn,[]);

% ZI: 1xn matrix
% zj: m2xn matrix
% R:  m2x1 matrix
function result = custom_distance( zi, zj )
    result = sqrt(sum((zi-zj).^2,2));
    global weights;
end