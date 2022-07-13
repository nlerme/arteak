% This function returns a first guess of fresco reconstruction, whatever
% the availability of the fresco image and the shape of fragments.
% 
% Inputs:
%   * im_fresco:              fresco image (RGBA image)
%   * frags_infos:            collection of fragments (struct with RGBA images)
%   * general_parameters:     value of general parameters (non empty struct)
%   * init_parameters:        value of init parameters (non empty struct)
%   * gen_parameters:         value of parameters used for generating the fragmented fresco ([non empty] struct)
%   * geometric_constraints:  geometric constraints (non empty struct)
%   * results_dir:            directory where results are stored (non empty string)
%   * gt_fn:                  full filename of ground truth ([non empty] string)
% 
% Outputs:
%   * final_frags_sol
function final_frags_sol = run_reconstruction_from_loaded_data( im_fresco, frags_infos, general_parameters, init_parameters, gen_parameters, geometric_constraints, results_dir, gt_fn )
    if sum(sum(im_fresco(:,:,4)>0))==0
        % We deal with the case where the fresco image is unavailable
        frags_sol = init_blind_reconstruction(im_fresco, frags_infos, general_parameters, init_parameters, gen_parameters, geometric_constraints, results_dir, gt_fn);
    else
        % We deal with the case where the fresco image is available
        frags_sol = init_non_blind_reconstruction(im_fresco, frags_infos, general_parameters, init_parameters, gen_parameters, geometric_constraints, results_dir, gt_fn);
    end
end