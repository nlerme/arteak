% Function returning pixel coordinates randomly sampled from a given 
% confidence map (rejection sampling or slice sampling).
% 
% Inputs:
%   * im_map:     sampling map with normalized intensities in [0,1] (2D matrix of reals)
%   * threshold:  threshold above which pixels are considered for sampling (in [0,1])
%   * N:          number of pixels to sample (positive integer)
% 
% Outputs:
%   * coords:  pixel coordinates (Nx2 matrix of integers [py_1,px_1;...;py_1,px_n])
function coords = sample_points( im_map, threshold, N )

    %---------- Rejection sampling ----------
    coords      = zeros(N, 2);
    [rows,cols] = find(im_map>threshold);

    if isempty(rows)
        coords = [];
        return;
    end
    
    for k=1:N
        ok          = false;
        nb_attempts = 0;

        while ~ok
            i = randi([1,length(cols)]);
            x = cols(i);
            y = rows(i);
            u = rand(1,1);

            if u<=im_map(y,x)
                ok = true;
                coords(k,:) = [y,x];
            end
            
            nb_attempts = nb_attempts+1;
        end
        
        %disp(sprintf('+ sample k=%d/N=%d | nb attempts=%d', k, N, nb_attempts));
    end

%     %---------- Slice sampling ----------
%     coords      = zeros(N, 2);
%     [rows,cols] = find(im_map>threshold);
% 
%     if isempty(rows)
%             coords = [];
%             return;
%     end
% 
%     i = randi([1,length(cols)]);
%     x = cols(i);
%     y = rows(i);
% 
%     for k=1:N
%         fx = rand(1,1)*(im_map(y,x)-threshold)+threshold;
%         [rows,cols] = find(im_map>=fx);
%         i = randi([1,length(cols)]);
%         x = cols(i);
%         y = rows(i);
%         coords(k,:) = [y,x];
%         %disp(sprintf('+ sample k=%d/N=%d', k, N));
%     end
end