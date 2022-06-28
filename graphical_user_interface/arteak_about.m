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
    imshow(imread(g_mydata.banner_fn),[]);
    movegui(g_fh_about, 'center');

    %----------------------------------------------------------------------
    %----------------------------- Callbacks ------------------------------
    %----------------------------------------------------------------------

    function quit_callback( h_object, event_data )
        delete(g_fh_about);
    end
end