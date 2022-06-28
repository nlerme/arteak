% This function saves the available translations and angles for positioning fragments
function save_constraints( frag_translations, frag_angles, filename )
    % We check if input arguments are valid
    if numel(frag_translations)~=numel(frag_angles)
        error('translations and angles arrays must be of the same size');
    end

    % We open the file in writing mode
    fp = fopen(filename, 'w');

    if fp<0
        error('unable to write the text file %s', filename);
    end

    % We write values into the text file
    for i=1:numel(frag_translations)
        translation = frag_translations(i);
        translation = translation{1};
        str         = sprintf('%f %f ', translation(2), translation(1));

        angles_i = frag_angles(i);
        angles_i = angles_i{1};

        for j=1:numel(angles_i)
            angle = -angles_i(j); % CAUTION: opposite angle is taken
            str   = [str,sprintf('%f ', angle)];
        end

        fprintf(fp, '%s\n', str);
    end

    % We close the file handler
    fclose(fp);
end