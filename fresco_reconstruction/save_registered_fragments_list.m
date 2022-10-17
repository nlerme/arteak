% Function saving list of registered fragments in a text file.
% 
% Inputs:
%   * frags_sol:    solution composed of fragments
%   * frags_infos:  informations about fragments
%   * fn:           output filename (string)
% 
% Outputs:
%   * decision:  true if file has been successfully written on the disk, false otherwise
function decision = save_registered_fragments_list( frags_sol, frags_infos, fn )
    fp = fopen(fn, 'w');

    if fp<0
        decision = false;
        return;
    end

    %fprintf(fp, '# fragment_number tx ty theta\n');

    for k=1:length(frags_sol)
        idx = frags_sol{k}.idx;
        a   = frags_sol{k}.angle;
        q   = apply_forward_transform(frags_infos{idx}.offset, [0,0], a, [0,0]);
        t   = frags_sol{k}.translation+q;
        fprintf(fp, '%d %f %f %f\n', idx-1, t(2), t(1), -a);
    end

    decision = true;
end