% This function try to place a fragment in a fresco satisfying the two following constraints:
%  (i) Each fragment must be mostly inside fresco (see parameter outside_fragment_tolerance)
%  (ii) Each couple of fragments must do not overlap too much (see parameter fragments_overlap_tolerance)
% 
% Inputs:
%   * frags_infos:                  information about fragment (cell array)
%   * idx:                          fragment image index (integer, >0)
%   * translation:                  translation of fragment (2D vector of real numbers)
%   * angle:                        angle of rotation of fragment in degrees (in [0,360])
%   * frags_sol:                    solution composed of fragments (cell array)
%   * im_fresco_color:              color image of fresco (non empty uint8 matrix)
%   * im_fresco_alpha:              alpha image of fresco (non empty uint8 matrix)
%   * interpolation_type:           type of interpolation (string, e.g. bilinear, bicubic, etc.)
%   * outside_fragment_tolerance:   tolerance threshold deciding if a fragment is outside the fresco model or not (in [0,1])
%   * fragments_overlap_tolerance:  tolerance threshold deciding if two fragments overlap or not (in [0,1])
% 
% Outputs:
%   * frag:  successfully (struct) or failed (empty array) placed fragment
function frag = place_fragment( frags_infos, idx, translation, angle, frags_sol, im_fresco_color, im_fresco_alpha, ...
                                interpolation_type, outside_fragment_tolerance, fragments_overlap_tolerance )
    % We initialize some variables
    ic_center     = frags_infos{idx}.inner_circle_center;
    ic_radius     = frags_infos{idx}.inner_circle_radius;
    oc_center     = frags_infos{idx}.outer_circle_center;
    oc_radius     = frags_infos{idx}.outer_circle_radius;
    im_frag_color = frags_infos{idx}.color;
    im_frag_alpha = frags_infos{idx}.alpha;
    frag_area     = frags_infos{idx}.area;
    fresco_size   = size(im_fresco_alpha);

    % We move the fragment to the desired place
    [fresco_coords_t,frag_coords_t] = get_transformed_fragment(im_frag_alpha, translation, angle, fresco_size);
    frag_area_t                     = size(fresco_coords_t,1);
    ic_center_t                     = round(apply_forward_transform(ic_center, translation, angle, ic_center));
    oc_center_t                     = round(apply_forward_transform(oc_center, translation, angle, ic_center));
    ic_radius_t                     = ic_radius;
    oc_radius_t                     = oc_radius;

    % We check if the fragment lies inside the fresco
    if ~is_fragment_inside_fresco(oc_center_t, frag_area_t, fresco_size, frag_area, outside_fragment_tolerance)
        frag = [];
        return;
    end

    % We check if the generated fragment does not intersect with already placed ones
    intersections = 0;

    for k=1:length(frags_sol)
        fresco_coords_t2 = frags_sol{k}.fresco_coords;
        oc_center_t2     = frags_sol{k}.outer_circle_center;
        oc_radius_t2     = frags_sol{k}.outer_circle_radius;

        if are_fragments_intersected(fresco_coords_t, oc_center_t, oc_radius_t, fresco_coords_t2, oc_center_t2, oc_radius_t2, fragments_overlap_tolerance)
            intersections = 1;
            break;
        end
    end

    if intersections
        frag = [];
        return;
    end

    % We add the generated fragment to the list
    frag_intensities_t     = double(get_intensities(im_frag_color, frag_coords_t, interpolation_type));
    fresco_intensities_t   = double(get_intensities(im_fresco_color, fresco_coords_t, interpolation_type));
    %-----------------------
    % Intensities taken into account only in the non masked areas of the fresco model (TODO ?)
    offsets                 = sub2ind(fresco_size, fresco_coords_t(:,1), fresco_coords_t(:,2));
    idx_offsets             = find(im_fresco_alpha(offsets)>0);
    nm_frag_intensities_t   = frag_intensities_t(idx_offsets,:);
    nm_fresco_intensities_t = fresco_intensities_t(idx_offsets,:);
    %-----------------------
    frag                   = struct('idx', idx, 'translation', translation, 'angle', angle, 'area', frag_area_t, 'inner_circle_center', ic_center_t, ...
                                    'inner_circle_radius', ic_radius_t, 'outer_circle_center', oc_center_t, 'outer_circle_radius', oc_radius_t, ...
                                    'fresco_coords', fresco_coords_t, 'frag_coords', frag_coords_t, 'frag_intensities', frag_intensities_t, ...
                                    'nm_frag_intensities', nm_frag_intensities_t, 'fresco_intensities', fresco_intensities_t, ...
                                    'nm_fresco_intensities', nm_fresco_intensities_t, 'neighbors', [], 'color_idx', []);
end