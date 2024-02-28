% This function saves the transformation parameters of true fragments.
% 
% Inputs:
%   * frag_translations:  2D translations of fragments (cell array)
%   * frag_angles:        angle of rotation of fragments (cell array)
%   * true_idx:           indexes of fragments belonging to the solution (array)
%   * filename:           name of the save file (string)
% 
% Outputs:
%   None
function save_true_fragments_parameters( frag_translations, frag_angles, true_idx, filename )
    % We check if input arguments are valid
    if numel(frag_translations)~=numel(frag_angles)
        error('Translations and angles arrays must be of the same size');
    end

    % We open the file in writing mode
    fp = fopen(filename, 'w');

    if fp<0
        error('Unable to write the text file %s', filename);
    end

    % We write values into the text file
    for n=true_idx
        translation = frag_translations(n);
        translation = translation{1};
        angle       = frag_angles(n);
        angle       = -angle{1}; % CAUTION: opposite angle is taken
        fprintf(fp, '%d %f %f %f\n', n-1, translation(2), translation(1), angle);
    end

    % We close the file handler
    fclose(fp);
end