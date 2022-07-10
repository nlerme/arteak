function varargout = arteak_about( fh_main )
    % We get GUI data
    g_mydata = guidata(fh_main);

    % We create the subwindow
    g_fh_about = figure('menubar', 'none', ...
                        'toolbar', 'none', ...
                        'color', [1,1,1], ...
                        'name', 'ARTEAK - About', ...
                        'units', 'normalized', ...
                        'closerequestfcn', @quit_callback);

    im_banner = load_image(g_mydata.banner_fn, false);

    if isempty(im_banner)
        uiwait(errordlg(sprintf('Unable to load banner image %s', g_mydata.banner_fn), 'ARTEAK ERROR', 'modal'));
        return;
    end
    
    imshow(im_banner,[]);
    movegui(g_fh_about, 'center');

    %----------------------------------------------------------------------
    %----------------------------- Callbacks ------------------------------
    %----------------------------------------------------------------------

    function quit_callback( h_object, event_data )
        delete(g_fh_about);
    end
end