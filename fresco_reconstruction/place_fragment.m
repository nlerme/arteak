% This function try to place a fragment in a fresco.
% 
% Inputs:
%   * frags_infos:  information about fragment (cell array)
%   * idx:          fragment image index (integer, >0)
%   * translation:  translation of fragment (2D vector of real numbers)
%   * angle:        angle of rotation of fragment in degrees (in [0,360])
%   * frags_sol:    solution composed of fragments (cell array)
%   * im_fresco:  2D size of the fresco (2D vector of positive integers)
%   * interpolation_type:  type of interpolation (string, e.g. bilinear, bicubic, etc.)
% 
% Outputs:
%   * frag:  successfully (struct) or failed (empty array) placed fragment
function frag = place_fragment( frags_infos, idx, translation, angle, frags_sol, im_fresco, interpolation_type )
    % We set tolerance thresholds
    outside_frag_tolerance  = 0.0;
    frags_overlap_tolerance = 0.0;

    % We set some variables for convenience
    ic_center       = frags_infos{idx}.inner_circle_center;
    ic_radius       = frags_infos{idx}.inner_circle_radius;
    oc_center       = frags_infos{idx}.outer_circle_center;
    oc_radius       = frags_infos{idx}.outer_circle_radius;
    im_frag_color   = frags_infos{idx}.color;
    im_frag_alpha   = frags_infos{idx}.alpha;
    frag_area       = frags_infos{idx}.area;
    fresco_size     = size(im_fresco);
    im_fresco_color = im_fresco(:,:,1:3);

    % We move the fragment to the desired place
    [fresco_coords_t,frag_coords_t] = get_transformed_fragment(im_frag_alpha, translation, angle, fresco_size(1:2));
    frag_area_t                     = size(fresco_coords_t,1);
    ic_center_t                     = round(apply_forward_transform(ic_center, translation, angle, ic_center));
    oc_center_t                     = round(apply_forward_transform(oc_center, translation, angle, ic_center));
    ic_radius_t                     = ic_radius;
    oc_radius_t                     = oc_radius;

    % We check if the fragment lies inside the fresco
    if ~is_fragment_inside_fresco(oc_center_t, frag_area_t, fresco_size(1:2), frag_area, outside_frag_tolerance)
        frag = [];
        return;
    end

    % We check if the generated fragment does not intersect with already placed ones
    intersections = 0;

    for k=1:length(frags_sol)
        fresco_coords_t2 = frags_sol{k}.fresco_coords;
        oc_center_t2     = frags_sol{k}.outer_circle_center;
        oc_radius_t2     = frags_sol{k}.outer_circle_radius;

        if are_fragments_intersected(fresco_coords_t, oc_center_t, oc_radius_t, fresco_coords_t2, oc_center_t2, oc_radius_t2, frags_overlap_tolerance)
            intersections = 1;
            break;
        end
    end

    if intersections
        frag = [];
        return;
    end

    % We add the generated fragment to the list
    frag_intensities_t   = get_intensities(im_frag_color, frag_coords_t, interpolation_type)/255.0;
    fresco_intensities_t = get_intensities(im_fresco_color, fresco_coords_t, interpolation_type)/255.0;
    frag                 = struct('idx', idx, 'translation', translation, 'angle', angle, 'area', frag_area_t, 'inner_circle_center', ic_center_t, ...
                                  'inner_circle_radius', ic_radius_t, 'outer_circle_center', oc_center_t, 'outer_circle_radius', oc_radius_t, ...
                                  'fresco_coords', fresco_coords_t, 'frag_coords', frag_coords_t, 'frag_intensities', frag_intensities_t, ...
                                  'fresco_intensities', fresco_intensities_t, 'neighbors', [], 'color_idx', []);
end