% Function comparing a solution w.r.t. ground truth and returning some statistics.
% 
% Inputs:
%   * frags:     resulting fragments list (cell array)
%   * gt:        fragments from ground truth (cell array)
%   * nb_frags:  total number of fragments (integer, >=0)
%   * tt:        tolerance in translation in pixels (>=0)
%   * at:        tolerance in angle in degrees (in [0,360])
% 
% Outputs:
%   * tp:       true positives (indexes)
%   * fp:       false positives (indexes)
%   * tn:       true negatives (indexes)
%   * fn:       false negatives (indexes)
%   * acc:      accuracy (in [0,100])
%   * fm:       f-measure (in [0,100])
%   * tr_err:   translation error matrix (top row=indexes, bottom row=error)
%   * rot_err:  rotation error matrix (top row=indexes, bottom row=error)
%   * ina:      inaccurately placed fragments (indexes)
function [tp,fp,tn,fn,acc,fm,tr_err,rot_err,ina] = compare_solution_to_gt( frags, gt, nb_frags, tt, at )
    tp      = [];
    fp      = [];
    tn      = [];
    fn      = [];
    frags2  = cell(1, nb_frags);
    gt2     = cell(1, nb_frags);
    tr_err  = [];
    rot_err = [];
    ina     = [];

    for k=1:length(frags)
        frags2{frags{k}.idx} = frags{k};
    end

    for k=1:length(gt)
        gt2{gt{k}.idx} = gt{k};
    end

    for k=1:nb_frags
        if ~isempty(frags2{k})
            if ~isempty(gt2{k})
                if is_fragment_identical_to_gt(frags2{k}, gt2{k}, tt, at)
                    tp = [tp,k];
                else
                    fp  = [fp,k];
                    ina = [ina,k];
                end
                tr_err  = [tr_err,[k;norm(frags2{k}.translation-gt2{k}.translation)]];
                rot_err = [rot_err,[k;get_angular_difference(frags2{k}.angle,gt2{k}.angle)]];
            else
                fp = [fp,k];
            end
        else
            if ~isempty(gt2{k})
                fn = [fn,k];
            else
                tn = [tn,k];
            end
        end
    end

    acc = (length(tp)+length(tn))/(length(tp)+length(fp)+length(tn)+length(fn))*100.0;
    fm  = (2*length(tp)/(2*length(tp)+length(fp)+length(fn)))*100.0;
end