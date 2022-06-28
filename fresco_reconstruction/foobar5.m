im_src = zeros(768,1024);
margin = 0.2; % in percents
y_range = round(margin*size(im_src,1)):round((1-margin)*size(im_src,1));
x_range = round(margin*size(im_src,2)):round((1-margin)*size(im_src,2));
im_src(y_range, x_range) = 1;

im_dist1 = bwdist(im_src, 'euclidean');

[rows,cols] = find(im_src==0);
left = x_range(1);
right = x_range(end);
top = y_range(1);
bottom = y_range(end);
a = left-cols;
b = cols-right;
c = top-rows;
d = rows-bottom;

dist = sqrt(a.^2.*(a>0)+b.^2.*(b>0)+c.^2.*(c>0)+d.^2.*(d>0));
im_dist2 = zeros(size(im_src));
idx = sub2ind(size(im_dist2), rows, cols);
im_dist2(idx) = dist;

%figure, imshow(im_dist1,[]);
figure, imshow(im_dist2,[]);
