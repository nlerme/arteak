% Function returning filtered keypoints and features given a binary image.
% 
% Inputs:
%   * im_map:        binary image indicating areas to keep keypoints and features
%   * old_points:    keypoints to be filtered (cornerPoints object)
%   * old_features:  features to be filtered (binaryFeatures object)
% 
% Outputs:
%   * new_points:    filtered keypoints (cornerPoints object)
%   * new_features:  filtered features (binaryFeatures object)
function [new_points,new_features] = filter_keypoints_and_features( im_map, old_points, old_features )
    % If the map is empty, we assign empty sets to output variables
    if sum(im_map(:))==0
        new_points   = [];
        new_features = [];
        return;
    end

    % We return filtered keypoints and features
    old_locations_r = round(old_points.Location);
    idx1 = sub2ind(size(im_map), old_locations_r(:,2), old_locations_r(:,1));
    idx2 = find(im_map(idx1));

    if length(idx2)<2
        new_points   = [];
        new_features = [];
        return;
    end
        
    new_points = cornerPoints(old_points.Location(idx2,:), 'Metric', old_points.Metric(idx2));
    new_features = binaryFeatures(old_features.Features(idx2,:));
end