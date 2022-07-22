% This function returns a first guess of fresco reconstruction, whatever
% the availability of the fresco image and the shape of fragments.
% 
% Inputs:
%   * im_fresco:              fresco image (RGBA image)
%   * frags_infos:            collection of fragments (cell array with RGBA images)
%   * general_parameters:     value of general parameters (non empty cell array)
%   * init_parameters:        value of init parameters (non empty cell array)
%   * gen_parameters:         value of parameters used for generating the fragmented fresco (non empty struct)
%   * geometric_constraints:  geometric constraints (non empty struct)
%   * frags_gt:               ground truth ([non empty] cell array)
% 
% Outputs:
%   * frags_sol:  solution composed of fragments ([non empty] cell array)
function frags_sol = run_init_reconstruction( im_fresco, frags_infos, general_parameters, init_parameters, gen_parameters, geometric_constraints, frags_gt )
    if sum(sum(im_fresco(:,:,4)>0))==0
        % We deal with the case where the fresco image is unavailable
        frags_sol = run_init_blind_reconstruction(im_fresco, frags_infos, general_parameters, init_parameters, gen_parameters, geometric_constraints, frags_gt);
    else
        % We deal with the case where the fresco image is at least partially available
        frags_sol = init_non_blind_reconstruction(im_fresco, frags_infos, general_parameters, init_parameters, gen_parameters, geometric_constraints, frags_gt);
    end
end