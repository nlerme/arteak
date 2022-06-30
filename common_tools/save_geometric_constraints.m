% This function saves the available translations and angles constraining the placement of fragments
function save_geometric_constraints( frag_translations, frag_angles, filename )
    % We open the file in writing mode
    fp = fopen(filename, 'w');

    if fp<0
        error('unable to write the text file %s', filename);
    end

    % We write values into the text file
    fprintf(fp, '%d\n', numel(frag_translations));

    if numel(frag_translations)>0
        for i=1:numel(frag_translations)
            translation = frag_translations(i);
            translation = translation{1};
            fprintf(fp, '%f %f\n', translation(2), translation(1));
        end
    end

    frag_angles = frag_angles{1};
    fprintf(fp, '%d\n', numel(frag_angles));

    if numel(frag_angles)>0
        for i=1:numel(frag_angles)
            angle = -frag_angles(i); % CAUTION: opposite angle is taken
            fprintf(fp, sprintf('%f\n', angle));
        end
    end

    % We close the file handler
    fclose(fp);
end
