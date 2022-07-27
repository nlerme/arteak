function varargout = arteak_gui( varargin )
    % We delete variables and close windows
    close all;
    clear all;
    clc;

    % We add required paths recursively
    addpath_recurse(['..' filesep 'common_tools']);
    addpath_recurse(['..' filesep 'fresco_reconstruction']);

    % We define global variables
    g_mydata.arteak_version           = 'v0.0.1 - 20/06/2022';
    g_mydata.software_url             = 'https://nicolaslerme.fr/';
    g_mydata.datasets_url             = 'https://vision.unipv.it/DAFchallenge/DAFNE_dataset/dataset_download.html';
    %g_mydata.data_root_dir           = ['..' filesep '..' filesep 'data' filesep 'regular_db1'];
    g_mydata.data_root_dir            = '.';
    g_mydata.pics_dir                 = ['pics'];
    g_mydata.banner_fn                = [g_mydata.pics_dir filesep 'banner.png'];
    g_mydata.frags_dir                = 'frag_eroded';
    g_mydata.true_frags_fn            = 'fragments.txt';
    g_mydata.spurious_frags_fn        = 'fragments_s.txt';
    g_mydata.neighbors_frags_fn       = 'neighbors.txt';
    g_mydata.gen_parameters_fn        = 'gen_parameters.txt';
    g_mydata.geometric_constraints_fn = 'geometric_constraints.txt';
    g_mydata.results_root_dir         = ['..' filesep 'results'];
    g_mydata.colormap                 = get_colormap();
    g_mydata.current_fresco_dir       = [];
    g_mydata.current_frags_dir        = [];
    g_mydata.image_view               = [0.21 0.02 0.78 0.96];
    g_mydata.im_current               = [];
    g_mydata.contrast                 = 1.0;
    g_mydata.luminosity               = 0.0;
    g_mydata.im_fresco                = [];
    g_mydata.frags_infos              = {};
    g_mydata.im_recs_color            = {};
    g_mydata.im_recs_filled           = {};
    g_mydata.frags_sols               = {};
    g_mydata.gen_parameters           = [];
    g_mydata.geometric_constraints    = [];
    g_mydata.current_frags_idx        = -1;
    g_mydata.current_recs_idx         = -1;
    g_mydata.current_alpha            = [];
    g_mydata.use_fresco_alpha         = true;
    g_mydata.use_frags_alpha          = true;
    g_mydata.use_recs_alpha           = true;
    g_mydata.show_frags_inner_circle  = false;
    g_mydata.show_frags_outer_circle  = false;
    g_mydata.show_recs_idx            = false;
    g_mydata.show_recs_inner_circle   = false;
    g_mydata.show_recs_outer_circle   = false;
    g_mydata.show_recs_neighbors      = false;
    g_mydata.frags_inner_circle_color = g_mydata.colormap(8,:);
    g_mydata.frags_outer_circle_color = g_mydata.colormap(7,:);
    g_mydata.recs_neighbors_color     = g_mydata.colormap(8,:);
    g_mydata.recs_idx_color           = g_mydata.colormap(4,:);
    g_mydata.recs_inner_circle_color  = g_mydata.colormap(8,:);
    g_mydata.recs_outer_circle_color  = g_mydata.colormap(7,:);
    g_mydata.recs_background_color    = g_mydata.colormap(2,:);
    g_mydata.interpolation_type       = 'bilinear';

    % We display the banner for a small fraction of time
    fh_banner = figure('menubar', 'none', ...
                       'toolbar', 'none', ...
                       'name', ['About ARTEAK - ' g_mydata.arteak_version], ...
                       'color', [1,1,1]);

    im_banner = load_image(g_mydata.banner_fn, false);

    if isempty(im_banner)
        uiwait(errordlg(sprintf('Unable to load banner image %s', g_mydata.banner_fn), 'ARTEAK ERROR', 'modal'));
        return;
    end
        
    imshow(im_banner,[]);
    movegui(fh_banner, 'center');
    pause(2.0);
    delete(fh_banner);

    % We create the main window
    g_fh_main = figure('menubar', 'none', ...
                       'toolbar', 'none', ...
                       'color', get(0, 'defaultuicontrolbackgroundcolor'), ...
                       'name', ['ARTEAK - ' g_mydata.arteak_version], ...
                       'units', 'normalized', ...
                       'position', [0 0 1 1]);

    g_h_file_menu = uimenu('parent', g_fh_main, ...
                           'handlevisibility', 'callback', ...
                           'label', 'File');

    g_h_load_fresco_item = uimenu('parent', g_h_file_menu, ...
                                  'handlevisibility', 'callback', ...
                                  'Accelerator', 'O', ...
                                  'label', 'Load fresco image', ...
                                  'callback', @load_fresco_callback);

    g_h_add_fragments_item = uimenu('parent', g_h_file_menu, ...
                                    'handlevisibility', 'callback', ...
                                    'Accelerator', 'P', ...
                                    'label', 'Load fragment images', ...
                                    'callback', @add_fragments_callback);

    g_h_add_reconstructions_item = uimenu('parent', g_h_file_menu, ...
                                          'handlevisibility', 'callback', ...
                                          'Accelerator', 'M', ...
                                          'label', 'Load reconstructions', ...
                                          'callback', @add_reconstructions_callback);

    g_h_unload_all_data_item = uimenu('parent', g_h_file_menu, ...
                                      'handlevisibility', 'callback', ...
                                      'Accelerator', 'W', ...
                                      'label', 'Unload all data', ...
                                      'callback', @unload_all_data_callback);

    g_h_quit_item = uimenu('parent', g_h_file_menu, ...
                           'handlevisibility', 'callback', ...
                           'Accelerator', 'Q', ...
                           'label', 'Quit', ...
                           'callback', @quit_callback);

    g_h_help_menu = uimenu('parent', g_fh_main, ...
                           'handlevisibility', 'callback', ...
                           'label', 'Help');

    g_h_help_software_item = uimenu('parent', g_h_help_menu, ...
                                    'handlevisibility', 'callback', ...
                                    'label', 'Help on software', ...
                                    'callback', @help_software_callback);

    g_h_help_datasets_item = uimenu('parent', g_h_help_menu, ...
                                    'handlevisibility', 'callback', ...
                                    'label', 'Help on datasets', ...
                                    'callback', @help_datasets_callback);

    g_h_about_menu = uimenu('parent', g_fh_main, ...
                            'handlevisibility', 'callback', ...
                            'label', 'About', ...
                            'callback', @about_callback);

    %---------------------------

    g_h_fresco_panel = uipanel('parent', g_fh_main, ...
                               'title', 'Fresco', ...
                               'fontsize', 11, ...
                               'fontweight', 'bold', ...
                               'units', 'normalized', ...
                               'position', [0.01 0.84 0.19 0.15]);

    g_h_fresco_filename_label = uicontrol('parent', g_h_fresco_panel, ...
                                          'style', 'text', ...
                                          'units', 'normalized', ...
                                          'position', [0.05 0.8 0.9 0.2], ...
                                          'fontsize', 11, ...
                                          'string', 'Filename:');

    g_h_fresco_filename_edit = uicontrol('parent', g_h_fresco_panel, ...
                                          'style', 'edit', ...
                                          'units', 'normalized', ...
                                          'position', [0.05 0.6 0.9 0.2], ...
                                          'fontsize', 11, ...
                                          'string', '', ...
                                          'handlevisibility', 'callback', ...
                                          'callback', @fresco_filename_changed_callback);

    g_h_fresco_load_button = uicontrol('parent', g_h_fresco_panel, ...
                                       'units', 'normalized', ...
                                       'position', [0.05 0.34 0.45 0.2], ...
                                       'style', 'pushbutton', ...
                                       'fontsize', 11, ...
                                       'string', '+', ...
                                       'handlevisibility', 'callback', ...
                                       'callback', @load_fresco_callback);

    g_h_fresco_remove_button = uicontrol('parent', g_h_fresco_panel, ...
                                         'units', 'normalized', ...
                                         'position', [0.5 0.34 0.45 0.2], ...
                                         'style', 'pushbutton', ...
                                         'fontsize', 15, ...
                                         'string', '-', ...
                                         'handlevisibility', 'callback', ...
                                         'callback', @remove_fresco_callback);

    g_h_fresco_alpha_channel_label = uicontrol('parent', g_h_fresco_panel, ...
                                               'style', 'text', ...
                                               'units', 'normalized', ...
                                               'position', [0.05 0.05 0.7 0.2], ...
                                               'fontsize', 11, ...
                                               'string', 'Alpha channel:');

    g_h_fresco_alpha_channel_checkbox = uicontrol('parent', g_h_fresco_panel, ...
                                                  'units', 'normalized', ...
                                                  'position', [0.7 0.1 0.1 0.2], ...
                                                  'style', 'checkbox', ...
                                                  'fontsize', 11, ...
                                                  'handlevisibility', 'callback', ...
                                                  'Value', g_mydata.use_fresco_alpha, ...
                                                  'callback', @fresco_alpha_changed_callback);

    %---------------------------

    g_h_fragments_panel = uipanel('parent', g_fh_main, ...
                                 'title', 'Fragments', ...
                                 'fontsize', 11, ...
                                 'fontweight', 'bold', ...
                                 'units', 'normalized', ...
                                 'position', [0.01 0.55 0.19 0.28]);

    g_h_fragments_listbox = uicontrol('parent', g_h_fragments_panel, ...
                                      'units', 'normalized', ...
                                      'position', [0.05 0.64 0.9 0.32], ...
                                      'style', 'listbox', ...
                                      'fontsize', 11, ...
                                      'string', {}, ...
                                      'handlevisibility', 'callback', ...
                                      'callback', @fragments_list_changed_callback);

    g_h_fragments_add_button = uicontrol('parent', g_h_fragments_panel, ...
                                         'units', 'normalized', ...
                                         'position', [0.05 0.49 0.15 0.13], ...
                                         'style', 'pushbutton', ...
                                         'fontsize', 11, ...
                                         'string', '+', ...
                                         'handlevisibility', 'callback', ...
                                         'callback', @add_fragments_callback);

    g_h_fragments_remove_button = uicontrol('parent', g_h_fragments_panel, ...
                                            'units', 'normalized', ...
                                            'position', [0.24 0.49 0.15 0.13], ...
                                            'style', 'pushbutton', ...
                                            'fontsize', 15, ...
                                            'string', '-', ...
                                            'handlevisibility', 'callback', ...
                                            'callback', @remove_fragment_callback);

    g_h_fragments_clear_button = uicontrol('parent', g_h_fragments_panel, ...
                                           'units', 'normalized', ...
                                           'position', [0.43 0.49 0.15 0.13], ...
                                           'style', 'pushbutton', ...
                                           'fontsize', 11, ...
                                           'string', 'X', ...
                                           'handlevisibility', 'callback', ...
                                           'callback', @clear_fragments_list_callback);

    g_h_fragments_move_up_button = uicontrol('parent', g_h_fragments_panel, ...
                                             'units', 'normalized', ...
                                             'position', [0.62 0.49 0.15 0.13], ...
                                             'style', 'pushbutton', ...
                                             'fontsize', 15, ...
                                             'string', char(8593), ...
                                             'handlevisibility', 'callback', ...
                                             'callback', @move_up_fragment_in_list_callback);

    g_h_fragments_move_down_button = uicontrol('parent', g_h_fragments_panel, ...
                                               'units', 'normalized', ...
                                               'position', [0.8 0.49 0.15 0.13], ...
                                               'style', 'pushbutton', ...
                                               'fontsize', 15, ...
                                               'string', char(8595), ...
                                               'handlevisibility', 'callback', ...
                                               'callback', @move_down_fragment_in_list_callback);

    g_h_fragments_alpha_channel_label = uicontrol('parent', g_h_fragments_panel, ...
                                                  'style', 'text', ...
                                                  'units', 'normalized', ...
                                                  'position', [0.05 0.35 0.7 0.1], ...
                                                  'fontsize', 11, ...
                                                  'string', 'Alpha channel:');

    g_h_fragments_alpha_channel_checkbox = uicontrol('parent', g_h_fragments_panel, ...
                                                     'units', 'normalized', ...
                                                     'position', [0.6 0.37 0.1 0.1], ...
                                                     'style', 'checkbox', ...
                                                     'fontsize', 11, ...
                                                     'handlevisibility', 'callback', ...
                                                     'value', g_mydata.use_frags_alpha, ...
                                                     'callback', @fragments_alpha_changed_callback);

    g_h_fragments_inner_circle_label = uicontrol('parent', g_h_fragments_panel, ...
                                                  'style', 'text', ...
                                                  'units', 'normalized', ...
                                                  'position', [0.05 0.25 0.7 0.1], ...
                                                  'fontsize', 11, ...
                                                  'string', 'Inner circle:');

    g_h_fragments_inner_circle_checkbox = uicontrol('parent', g_h_fragments_panel, ...
                                                    'units', 'normalized', ...
                                                    'position', [0.6 0.27 0.1 0.1], ...
                                                    'style', 'checkbox', ...
                                                    'fontsize', 11, ...
                                                    'handlevisibility', 'callback', ...
                                                    'value', g_mydata.show_frags_inner_circle, ...
                                                    'callback', @fragments_inner_circle_changed_callback);

    g_h_fragments_inner_circle_color_button = uicontrol('parent', g_h_fragments_panel, ...
                                                        'units', 'normalized', ...
                                                        'position', [0.7 0.3 0.05 0.05], ...
                                                        'style', 'pushbutton', ...
                                                        'fontsize', 11, ...
                                                        'handlevisibility', 'callback', ...
                                                        'string', ' ', ...
                                                        'backgroundcolor', g_mydata.frags_inner_circle_color, ...
                                                        'callback', @fragments_inner_circle_color_changed_callback);

    g_h_fragments_outer_circle_label = uicontrol('parent', g_h_fragments_panel, ...
                                                 'style', 'text', ...
                                                 'units', 'normalized', ...
                                                 'position', [0.05 0.15 0.7 0.1], ...
                                                 'fontsize', 11, ...
                                                 'string', 'Outer circle:');

    g_h_fragments_outer_circle_checkbox = uicontrol('parent', g_h_fragments_panel, ...
                                                    'units', 'normalized', ...
                                                    'position', [0.6 0.17 0.1 0.1], ...
                                                    'style', 'checkbox', ...
                                                    'fontsize', 11, ...
                                                    'handlevisibility', 'callback', ...
                                                    'value', g_mydata.show_frags_outer_circle, ...
                                                    'callback', @fragments_outer_circle_changed_callback);

    g_h_fragments_outer_circle_color_button = uicontrol('parent', g_h_fragments_panel, ...
                                                        'units', 'normalized', ...
                                                        'position', [0.7 0.2 0.05 0.05], ...
                                                        'style', 'pushbutton', ...
                                                        'fontsize', 11, ...
                                                        'handlevisibility', 'callback', ...
                                                        'string', ' ', ...
                                                        'backgroundcolor', g_mydata.frags_outer_circle_color, ...
                                                        'callback', @fragments_outer_circle_color_changed_callback);

    g_h_gen_parameters_button = uicontrol('parent', g_h_fragments_panel, ...
                                          'units', 'normalized', ...
                                          'position', [0.05 0.03 0.45 0.15], ...
                                          'style', 'pushbutton', ...
                                          'fontsize', 11, ...
                                          'string', 'Gen param.', ...
                                          'handlevisibility', 'callback', ...
                                          'callback', @gen_parameters_callback);

    g_h_geometric_constraints_button = uicontrol('parent', g_h_fragments_panel, ...
                                                 'units', 'normalized', ...
                                                 'position', [0.5 0.03 0.45 0.15], ...
                                                 'style', 'pushbutton', ...
                                                 'fontsize', 11, ...
                                                 'string', 'Geo. constraints', ...
                                                 'handlevisibility', 'callback', ...
                                                 'callback', @geometric_constraints_callback);

    %---------------------------

    g_h_reconstructions_panel = uipanel('parent', g_fh_main, ...
                                        'title', 'Reconstructions', ...
                                        'fontsize', 11, ...
                                        'fontweight', 'bold', ...
                                        'units', 'normalized', ...
                                        'position', [0.01 0.25 0.19 0.29]);

    g_h_reconstructions_listbox = uicontrol('parent', g_h_reconstructions_panel, ...
                                            'units', 'normalized', ...
                                            'position', [0.05 0.65 0.9 0.32], ...
                                            'style', 'listbox', ...
                                            'string', {}, ...
                                            'fontsize', 11, ...
                                            'handlevisibility', 'callback', ...
                                            'callback', @reconstructions_list_changed_callback);

    g_mydata.recs_listbox = g_h_reconstructions_listbox;

    g_h_reconstructions_add_button = uicontrol('parent', g_h_reconstructions_panel, ...
                                               'units', 'normalized', ...
                                               'position', [0.05 0.49 0.15 0.13], ...
                                               'style', 'pushbutton', ...
                                               'fontsize', 11, ...
                                               'string', '+', ...
                                               'handlevisibility', 'callback', ...
                                               'callback', @add_reconstructions_callback);

    g_h_reconstructions_remove_button = uicontrol('parent', g_h_reconstructions_panel, ...
                                                  'units', 'normalized', ...
                                                  'position', [0.24 0.49 0.15 0.13], ...
                                                  'style', 'pushbutton', ...
                                                  'fontsize', 15, ...
                                                  'string', '-', ...
                                                  'handlevisibility', 'callback', ...
                                                  'callback', @remove_reconstruction_callback);

    g_h_reconstructions_clear_button = uicontrol('parent', g_h_reconstructions_panel, ...
                                                 'units', 'normalized', ...
                                                 'position', [0.43 0.49 0.15 0.13], ...
                                                 'style', 'pushbutton', ...
                                                 'fontsize', 11, ...
                                                 'string', 'X', ...
                                                 'handlevisibility', 'callback', ...
                                                 'callback', @clear_reconstructions_list_callback);

    g_h_reconstructions_move_up_button = uicontrol('parent', g_h_reconstructions_panel, ...
                                                   'units', 'normalized', ...
                                                   'position', [0.62 0.49 0.15 0.13], ...
                                                   'style', 'pushbutton', ...
                                                   'fontsize', 15, ...
                                                   'string', char(8593), ...
                                                   'handlevisibility', 'callback', ...
                                                   'callback', @move_up_reconstruction_in_list_callback);

    g_h_reconstructions_move_down_button = uicontrol('parent', g_h_reconstructions_panel, ...
                                                     'units', 'normalized', ...
                                                     'position', [0.8 0.49 0.15 0.13], ...
                                                     'style', 'pushbutton', ...
                                                     'fontsize', 15, ...
                                                     'string', char(8595), ...
                                                     'handlevisibility', 'callback', ...
                                                     'callback', @move_down_reconstruction_in_list_callback);

    g_h_reconstructions_alpha_channel_label = uicontrol('parent', g_h_reconstructions_panel, ...
                                                        'style', 'text', ...
                                                        'units', 'normalized', ...
                                                        'position', [0.05 0.36 0.7 0.1], ...
                                                        'fontsize', 11, ...
                                                        'string', 'Alpha channel:');

    g_h_reconstructions_alpha_channel_checkbox = uicontrol('parent', g_h_reconstructions_panel, ...
                                                           'units', 'normalized', ...
                                                           'position', [0.75 0.38 0.1 0.1], ...
                                                           'style', 'checkbox', ...
                                                           'fontsize', 11, ...
                                                           'handlevisibility', 'callback', ...
                                                           'value', g_mydata.use_recs_alpha, ...
                                                           'callback', @reconstructions_alpha_changed_callback);

    g_h_reconstructions_idx_label = uicontrol('parent', g_h_reconstructions_panel, ...
                                              'style', 'text', ...
                                              'units', 'normalized', ...
                                              'position', [0.05 0.27 0.7 0.1], ...
                                              'fontsize', 11, ...
                                              'string', 'Fragments idx:');

    g_h_reconstructions_idx_checkbox = uicontrol('parent', g_h_reconstructions_panel, ...
                                                 'units', 'normalized', ...
                                                 'position', [0.75 0.29 0.1 0.1], ...
                                                 'style', 'checkbox', ...
                                                 'fontsize', 11, ...
                                                 'handlevisibility', 'callback', ...
                                                 'value', g_mydata.show_recs_idx, ...
                                                 'callback', @reconstructions_idx_changed_callback);

    g_h_reconstructions_idx_color_button = uicontrol('parent', g_h_reconstructions_panel, ...
                                                     'units', 'normalized', ...
                                                     'position', [0.85 0.32 0.05 0.05], ...
                                                     'style', 'pushbutton', ...
                                                     'fontsize', 11, ...
                                                     'handlevisibility', 'callback', ...
                                                     'string', ' ', ...
                                                     'backgroundcolor', g_mydata.recs_idx_color, ...
                                                     'callback', @reconstructions_idx_color_changed_callback);

    g_h_reconstructions_inner_circle_label = uicontrol('parent', g_h_reconstructions_panel, ...
                                                       'style', 'text', ...
                                                       'units', 'normalized', ...
                                                       'position', [0.05 0.18 0.7 0.1], ...
                                                       'fontsize', 11, ...
                                                       'string', 'Inner circle:');

    g_h_reconstructions_inner_circle_checkbox = uicontrol('parent', g_h_reconstructions_panel, ...
                                                          'units', 'normalized', ...
                                                          'position', [0.75 0.2 0.1 0.1], ...
                                                          'style', 'checkbox', ...
                                                          'fontsize', 11, ...
                                                          'handlevisibility', 'callback', ...
                                                          'value', g_mydata.show_recs_inner_circle, ...
                                                          'callback', @reconstructions_inner_circle_changed_callback);

    g_h_reconstructions_inner_circle_color_button = uicontrol('parent', g_h_reconstructions_panel, ...
                                                              'units', 'normalized', ...
                                                              'position', [0.85 0.23 0.05 0.05], ...
                                                              'style', 'pushbutton', ...
                                                              'fontsize', 11, ...
                                                              'handlevisibility', 'callback', ...
                                                              'string', ' ', ...
                                                              'backgroundcolor', g_mydata.recs_inner_circle_color, ...
                                                              'callback', @reconstructions_inner_circle_color_changed_callback);

    g_h_reconstructions_outer_circle_label = uicontrol('parent', g_h_reconstructions_panel, ...
                                                       'style', 'text', ...
                                                       'units', 'normalized', ...
                                                       'position', [0.05 0.09 0.7 0.1], ...
                                                       'fontsize', 11, ...
                                                       'string', 'Outer circle:');

    g_h_reconstructions_outer_circle_checkbox = uicontrol('parent', g_h_reconstructions_panel, ...
                                                          'units', 'normalized', ...
                                                          'position', [0.75 0.11 0.1 0.1], ...
                                                          'style', 'checkbox', ...
                                                          'fontsize', 11, ...
                                                          'handlevisibility', 'callback', ...
                                                          'value', g_mydata.show_recs_outer_circle, ...
                                                          'callback', @reconstructions_outer_circle_changed_callback);

    g_h_reconstructions_outer_circle_color_button = uicontrol('parent', g_h_reconstructions_panel, ...
                                                              'units', 'normalized', ...
                                                              'position', [0.85 0.14 0.05 0.05], ...
                                                              'style', 'pushbutton', ...
                                                              'fontsize', 11, ...
                                                              'handlevisibility', 'callback', ...
                                                              'string', ' ', ...
                                                              'backgroundcolor', g_mydata.recs_outer_circle_color, ...
                                                              'callback', @reconstructions_outer_circle_color_changed_callback);

    g_h_reconstructions_neighbors_label = uicontrol('parent', g_h_reconstructions_panel, ...
                                                    'style', 'text', ...
                                                    'units', 'normalized', ...
                                                    'position', [0.05 0.0 0.7 0.1], ...
                                                    'fontsize', 11, ...
                                                    'string', 'Fragments neighbors:');

    g_h_reconstructions_neighbors_checkbox = uicontrol('parent', g_h_reconstructions_panel, ...
                                                       'units', 'normalized', ...
                                                       'position', [0.75 0.02 0.1 0.1], ...
                                                       'style', 'checkbox', ...
                                                       'fontsize', 11, ...
                                                       'handlevisibility', 'callback', ...
                                                       'value', g_mydata.show_recs_neighbors, ...
                                                       'callback', @reconstructions_neighbors_changed_callback);

    g_h_reconstructions_neighbors_color_button = uicontrol('parent', g_h_reconstructions_panel, ...
                                                           'units', 'normalized', ...
                                                           'position', [0.85 0.05 0.05 0.05], ...
                                                           'style', 'pushbutton', ...
                                                           'fontsize', 11, ...
                                                           'handlevisibility', 'callback', ...
                                                           'string', ' ', ...
                                                           'backgroundcolor', g_mydata.recs_neighbors_color, ...
                                                           'callback', @reconstructions_neighbors_color_changed_callback);

    %---------------------------

    g_h_appearance_settings_panel = uipanel('parent', g_fh_main, ...
                                            'title', 'Appearance settings', ...
                                            'fontsize', 11, ...
                                            'fontweight', 'bold', ...
                                            'units', 'normalized', ...
                                            'position', [0.01 0.16 0.19 0.08]);

    g_h_contrast_label = uicontrol('parent', g_h_appearance_settings_panel, ...
                                   'style', 'text', ...
                                   'units', 'normalized', ...
                                   'position', [0.01 0.6 0.45 0.3], ...
                                   'fontsize', 11, ...
                                   'string', sprintf('Contrast %.1f:', g_mydata.contrast));

    g_h_contrast_slider = uicontrol('parent', g_h_appearance_settings_panel, ...
                                    'units', 'normalized', ...
                                    'position', [0.5 0.6 0.45 0.35], ...
                                    'style', 'slider', ...
                                    'min', 0.5, ...
                                    'max', 2, ...
                                    'value', g_mydata.contrast, ...
                                    'fontsize', 11, ...
                                    'handlevisibility', 'callback', ...
                                    'callback', @contrast_changed_callback);

    g_h_luminosity_label = uicontrol('parent', g_h_appearance_settings_panel, ...
                                     'style', 'text', ...
                                     'units', 'normalized', ...
                                     'position', [0.01 0.15 0.45 0.3], ...
                                     'fontsize', 11, ...
                                     'string', sprintf('Luminosity %.1f:', g_mydata.luminosity));

    g_h_luminosity_slider = uicontrol('parent', g_h_appearance_settings_panel, ...
                                      'units', 'normalized', ...
                                      'position', [0.5 0.15 0.45 0.35], ...
                                      'style', 'slider', ...
                                      'min', -0.5, ...
                                      'max', 0.5, ...
                                      'value', g_mydata.luminosity, ...
                                      'fontsize', 11, ...
                                      'handlevisibility', 'callback', ...
                                      'callback', @luminosity_changed_callback);

    %---------------------------

    g_h_reconstruction_button = uicontrol('parent', g_fh_main, ...
                                          'units', 'normalized', ...
                                          'position', [0.01 0.11 0.1 0.04], ...
                                          'style', 'pushbutton', ...
                                          'fontsize', 11, ...
                                          'string', 'Reconstruction...', ...
                                          'handlevisibility', 'callback', ...
                                          'callback', @reconstruction_callback);

    g_h_measurements_button = uicontrol('parent', g_fh_main, ...
                                        'units', 'normalized', ...
                                        'position', [0.11 0.11 0.09 0.04], ...
                                        'style', 'pushbutton', ...
                                        'fontsize', 11, ...
                                        'string', 'Measurements...', ...
                                        'handlevisibility', 'callback', ...
                                        'callback', @measurements_callback);

    g_h_comparison_button = uicontrol('parent', g_fh_main, ...
                                     'units', 'normalized', ...
                                     'position', [0.01 0.06 0.1 0.04], ...
                                     'style', 'pushbutton', ...
                                     'fontsize', 11, ...
                                     'string', 'Comparison...', ...
                                     'handlevisibility', 'callback', ...
                                     'callback', @comparison_callback);

    g_h_save_view_button = uicontrol('parent', g_fh_main, ...
                                     'units', 'normalized', ...
                                     'position', [0.11 0.06 0.09 0.04], ...
                                     'style', 'pushbutton', ...
                                     'fontsize', 11, ...
                                     'string', 'Save view', ...
                                     'handlevisibility', 'callback', ...
                                     'callback', @save_image_view_callback);

    g_h_quit_button = uicontrol('parent', g_fh_main, ...
                                'units', 'normalized', ...
                                'position', [0.01 0.01 0.19 0.04], ...
                                'style', 'pushbutton', ...
                                'fontsize', 11, ...
                                'string', 'Quit', ...
                                'handlevisibility', 'callback', ...
                                'callback', @quit_callback);

    % We define the portion of the figure where images are displayed
    g_mydata.axes = axes('position', g_mydata.image_view);
    axis off;

    % We store GUI data
    guidata(g_fh_main, g_mydata);

    % We return results
    if nargout>0
        output_args{1} = g_fh_main;
        [varargout{1:nargout}] = output_args{:};
    end

    %----------------------------------------------------------------------
    %---------------------------- Non-callbacks ---------------------------
    %----------------------------------------------------------------------

    function update_view( use_alpha_channel )
        % We keep track of current alpha value
        g_mydata.current_alpha = use_alpha_channel;

        % We first check if current image is available
        if isempty(g_mydata.im_current)
            return;
        end

        % If so, we compute a version of it with stretched image intensities
        im_src = max(min(g_mydata.luminosity + g_mydata.contrast*im2double(g_mydata.im_current(:,:,1:end-1)),1),0);

        % We enable the figure
        figure(g_fh_main);

        % If alpha channel is present, we use it
        if use_alpha_channel
            image(g_mydata.axes, im_src, 'AlphaData', g_mydata.im_current(:,:,end));
            set(g_mydata.axes, 'visible', 'off');
            set(g_mydata.axes, 'color', 'none');
            axis image;
        else
             imshow(im_src,[]);
        end

        hold on;

        if ~isempty(g_mydata.frags_infos) && g_mydata.current_frags_idx>=1 && g_mydata.current_frags_idx<=numel(g_mydata.frags_infos)
            if g_mydata.show_frags_inner_circle
                icc = g_mydata.frags_infos{g_mydata.current_frags_idx}.inner_circle_center;
                icr = g_mydata.frags_infos{g_mydata.current_frags_idx}.inner_circle_radius;
                viscircles(flip(icc), icr, 'Color', g_mydata.frags_inner_circle_color);
            end

            if g_mydata.show_frags_outer_circle
                occ = g_mydata.frags_infos{g_mydata.current_frags_idx}.outer_circle_center;
                ocr = g_mydata.frags_infos{g_mydata.current_frags_idx}.outer_circle_radius;
                viscircles(flip(occ), ocr, 'Color', g_mydata.frags_outer_circle_color);
            end
        end

        hold off;

        % We show toolbar
        axtoolbar(g_mydata.axes, {'zoomin','zoomout','restoreview','datacursor','pan','export'});
    end

    function update_reconstruction()
        % We check if reconstructed frescoes are available
        if numel(g_mydata.frags_sols)==0 || g_mydata.current_recs_idx<1 || g_mydata.current_recs_idx>numel(g_mydata.frags_sols)
            return;
        end

        % We get the current fragments solution
        frags_sol = g_mydata.frags_sols{g_mydata.current_recs_idx};
        hold on;

        % We draw neighboring relationships between fragments
        if g_mydata.show_recs_neighbors
            for k=1:numel(frags_sol)
                % We get the inner circle center of current fragment
                icc = frags_sol{k}.inner_circle_center;

                % We loop over neighbors linking current fragment
                for j=frags_sol{k}.neighbors
                    icc2 = frags_sol{j}.inner_circle_center;
                    plot([icc(2),icc2(2)], [icc(1),icc2(1)], 'g-', 'LineWidth', 3, 'Color', g_mydata.recs_neighbors_color);
                end
            end
        end

        % We draw fragments center and idx
        if g_mydata.show_recs_idx
            for k=1:numel(frags_sol)
                % We get the idx, inner circle center and inner circle radius of current fragment
                idx = frags_sol{k}.idx;
                icc = frags_sol{k}.inner_circle_center;
                icr = frags_sol{k}.inner_circle_radius;
                occ = frags_sol{k}.outer_circle_center;
                ocr = frags_sol{k}.outer_circle_radius;

                % We draw fragments idx
                if g_mydata.show_recs_idx
                    text(double(icc(2)+10), double(icc(1)+10), sprintf('%d', idx-1), 'Color', g_mydata.recs_idx_color, 'FontSize', 12);
                    ph = plot(icc(2), icc(1), 'r+', 'MarkerSize', round(0.3*icr), 'Color', g_mydata.recs_idx_color, 'LineWidth', 3);
                    %----- tooltip (too long to display) ------
                    %dt = datatip(ph, icc(2), icc(1), 'Visible', 'off');
                    %ph.DataTipTemplate.DataTipRows(1).Label = 'Id =';
                    %ph.DataTipTemplate.DataTipRows(1).Value = idx-1;
                    %ph.DataTipTemplate.DataTipRows(2).Label = 't =';
                    %ph.DataTipTemplate.DataTipRows(2).Value = double(sprintf('%.2f', frag_sol{k}.translation));
                    %ph.DataTipTemplate.DataTipRows(3).Label = '\theta =';
                    %ph.DataTipTemplate.DataTipRows(3).Value = double(sprintf('%.2f', frag_sol{k}.angle));
                    %------------------------------------------
                end

                % We draw inner circles
                if g_mydata.show_recs_inner_circle
                    viscircles(flip(icc), icr, 'Color', g_mydata.recs_inner_circle_color);
                end

                % We draw outer circles
                if g_mydata.show_recs_outer_circle
                    viscircles(flip(occ), ocr, 'Color', g_mydata.recs_outer_circle_color);
                end
            end
        end

        hold off;
    end

    %----------------------------------------------------------------------
    %----------------------------- Callbacks ------------------------------
    %----------------------------------------------------------------------

    function fresco_filename_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We update the current image view
        g_mydata.im_current = g_mydata.im_fresco;
        update_view(g_mydata.use_fresco_alpha);

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function load_fresco_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We get the filename of the fresco
        [filename,directory] = uigetfile({'*.png;*.jpg;*.tif'}, 'Select one fresco image', g_mydata.data_root_dir, 'Multiselect', 'off');

        % If a file is selected, we try to load it the corresponding fresco image
        if ~isequal(filename, 0)
            full_filename                     = [directory filename];
            [im_fresco_color,im_fresco_alpha] = load_image(full_filename, false);

            % We check is the fresco image has been successfully loaded
            if isempty(im_fresco_color)
                % If not, we display an error message
                uiwait(errordlg(sprintf('Unable to load fresco image %s', full_filename), 'ARTEAK ERROR', 'modal'));
            else
                % Otherwise, we add it to the GUI and update the view with it
                [g_mydata.current_fresco_dir,~,~] = fileparts(directory);

                if isempty(im_fresco_alpha)
                    fs              = size(im_fresco_color);
                    im_fresco_alpha = uint8(255*ones(fs(1:2)));
                end

                g_mydata.im_current = cat(3, im_fresco_color, im_fresco_alpha);
                g_mydata.im_fresco  = g_mydata.im_current;
                set(g_h_fresco_filename_edit, 'string', full_filename);
                update_view(g_mydata.use_fresco_alpha);
            end
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function remove_fresco_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We unload the fresco image and make image view as empty
        if ~isempty(g_mydata.im_fresco)
            g_mydata.current_fresco_dir = [];
            g_mydata.im_fresco          = [];
            g_mydata.im_current         = [];
            delete(get(gca,'Children'));
            set(g_h_fresco_filename_edit, 'string', '');
            update_view(g_mydata.use_fresco_alpha);
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function fresco_alpha_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We enable/disable alpha channel and update the image view
        g_mydata.use_fresco_alpha = ~g_mydata.use_fresco_alpha;

        if ~isempty(g_mydata.im_fresco)
            g_mydata.im_current = g_mydata.im_fresco;
            update_view(g_mydata.use_fresco_alpha);
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function fragments_list_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % If the fragments list is not empty, we update view with the selected one
        if ~isempty(g_mydata.frags_infos)
            g_mydata.current_frags_idx = get(h_object, 'value');
            frag_info                  = g_mydata.frags_infos{g_mydata.current_frags_idx};
            g_mydata.im_current        = cat(3, frag_info.color, frag_info.alpha);
            update_view(g_mydata.use_frags_alpha);
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function add_fragments_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We check if fresco image is available
        if isempty(g_mydata.im_fresco)
            uiwait(errordlg('Please load first a fresco image', 'ARTEAK ERROR', 'modal'));
            return;
        end

        % We get the filename of the fragments
        if ~isempty(g_mydata.current_fresco_dir)
            frags_dir = g_mydata.current_fresco_dir;

            if isfolder([g_mydata.current_fresco_dir filesep g_mydata.frags_dir])
                frags_dir = [g_mydata.current_fresco_dir filesep g_mydata.frags_dir];
            end
        else
            frags_dir = g_mydata.data_root_dir;
        end

        directory = uigetdir(frags_dir, 'Select the directory for fragments');

        % We check if directory is selected
        if isequal(directory, 0)
            return;
        end

        % Selected filenames are converted to cell array for convenience
        if ~iscell(directory)
            directory = {directory};
        end

        % We check if text files exist
        gen_parameters_fn        = [directory{1} filesep g_mydata.gen_parameters_fn];
        geometric_constraints_fn = [directory{1} filesep g_mydata.geometric_constraints_fn];

        if ~isfile(gen_parameters_fn)
            uiwait(errordlg(sprintf('Text file %s not found in %s', g_mydata.gen_parameters_fn, directory{1}), 'ARTEAK ERROR', 'modal'));
            return;
        end

        if ~isfile(geometric_constraints_fn)
            uiwait(errordlg(sprintf('Text file %s not found in %s', g_mydata.geometric_constraints_fn, directory{1}), 'ARTEAK ERROR', 'modal'));
            return;
        end

        % We load parameters used for reconstruction
        gen_parameters = load_gen_parameters(gen_parameters_fn);

        % We load geometric constraints
        geometric_constraints = load_geometric_constraints(geometric_constraints_fn);

        % We display a progress bar
        pbh = waitbar(0, 'Please wait while loading fragment images');

        % We get the list of fragment image filenames
        filenames = get_matching_files(directory{1}, '.*\.png');

        for k=1:numel(filenames)
            [~,fresco_name,~] = fileparts(filenames{k});

            % We check if fragment does not belong to the list of fragments
            items = get(g_h_fragments_listbox, 'string');
            ok    = true;

            for i=1:numel(items)
                if strcmp(items{i}, fresco_name)
                    uiwait(warndlg(sprintf('Fragment image %s cannot be added because it already belongs to the fragments list', filenames{k}), 'ARTEAK ERROR', 'modal'));
                    ok = false;
                    break;
                end
            end

            if ~ok
                continue;
            end

            % We load fragment image
            [im_frag_color,im_frag_alpha] = load_image(filenames{k}, false);

            if isempty(im_frag_color)
                % If loading of fragment image fails, we display an error message
                uiwait(errordlg(sprintf('Fragment image %s cannot be loaded', filenames{k}), 'ARTEAK ERROR', 'modal'));
            else
                % Otherwise, we add it to the list of fragments
                if isempty(im_frag_alpha)
                    fs            = size(im_frag_color);
                    im_frag_alpha = uint8(255*ones(fs(1:2)));
                end

                [occ,ocr]   = get_outer_circle(im_frag_alpha, 200, false); % nb_iterations = 200
                [icc,icr]   = get_inner_circle(im_frag_alpha, occ);
                [rows,cols] = find(im_frag_alpha);
                frag_int    = get_intensities(im_frag_color, [rows,cols], g_mydata.interpolation_type);
                frag_std    = mean(std(frag_int, 0, 1));
                frag_info   = struct('color', im_frag_color, 'alpha', im_frag_alpha, 'inner_circle_center', icc, 'inner_circle_radius', icr, ...
                                     'outer_circle_center', occ, 'outer_circle_radius', ocr, 'std', frag_std);

                g_mydata.frags_infos           = {g_mydata.frags_infos{:},frag_info};
                g_mydata.gen_parameters        = gen_parameters;
                g_mydata.geometric_constraints = geometric_constraints;
                set(g_h_fragments_listbox, 'string', {items{:},fresco_name});

                % If at least one fragment image is loaded, we set the current frags directory
                g_mydata.current_frags_dir = directory{1};
            end

            % We update the progress bar
            waitbar(k/numel(filenames), pbh, 'Please wait while loading fragment images');
        end

        % We close the progress bar
        delete(findall(0,'type','figure','tag','TMWWaitbar'));

        % We update the view with the first fragment image of the list
        if numel(g_mydata.frags_infos)>0
            g_mydata.current_frags_idx = numel(g_mydata.frags_infos);
            set(g_h_fragments_listbox, 'value', g_mydata.current_frags_idx);
            g_mydata.im_current = cat(3, g_mydata.frags_infos{g_mydata.current_frags_idx}.color, g_mydata.frags_infos{g_mydata.current_frags_idx}.alpha);
            update_view(g_mydata.use_frags_alpha);
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function remove_fragment_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % If the list of fragments is not empty, we remove the current item from it
        if numel(g_mydata.frags_infos)==0
            return;
        end

        current_idx     = get(g_h_fragments_listbox, 'value');
        current_fns     = get(g_h_fragments_listbox, 'string');
        new_frags_infos = {};
        new_fns         = {};
        idx             = 1;

        for k=1:numel(g_mydata.frags_infos)
            if k~=current_idx
                new_frags_infos{idx} = g_mydata.frags_infos{k};
                new_fns{idx}         = current_fns{k};
                idx                  = idx + 1;
            end
        end

        g_mydata.frags_infos = new_frags_infos;
        set(g_h_fragments_listbox, 'string', new_fns);

        % We set the current image as empty
        g_mydata.im_current = [];
        delete(get(gca,'Children'));

        if numel(g_mydata.frags_infos)>0
            g_mydata.current_frags_idx = 1;
        else
            g_mydata.current_frags_idx     = -1;
            g_mydata.geometric_constraints = [];
            g_mydata.gen_parameters        = [];
            g_mydata.current_frags_dir     = [];
        end
        
        set(g_h_fragments_listbox, 'value', g_mydata.current_frags_idx);
        update_view(g_mydata.use_frags_alpha);

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function clear_fragments_list_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % If the list is not empty, we remove all fragment images
        if numel(g_mydata.frags_infos)==0
            return;
        end

        g_mydata.frags_infos           = {};
        g_mydata.gen_parameters        = [];
        g_mydata.geometric_constraints = [];
        g_mydata.im_current            = [];
        g_mydata.current_frags_idx     = -1;
        g_mydata.current_frags_dir     = [];
        set(g_h_fragments_listbox, 'string', {});
        delete(get(gca,'Children'));
        update_view(g_mydata.use_frags_alpha);

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function move_up_fragment_in_list_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % If the list is not empty, we remove all fragment images
        if numel(g_mydata.frags_infos)==0
            return;
        end

        % We move up the current element
        current_frags_infos = g_mydata.frags_infos;
        current_fns         = get(g_h_fragments_listbox, 'string');
        current_idx         = get(g_h_fragments_listbox, 'value');
        new_idx             = mod(current_idx-2, numel(current_fns))+1;

        [current_frags_infos{new_idx},current_frags_infos{current_idx}] = swap_vars(current_frags_infos{current_idx}, current_frags_infos{new_idx});
        [current_fns{new_idx},current_fns{current_idx}]                 = swap_vars(current_fns{current_idx}, current_fns{new_idx});

        set(g_h_fragments_listbox, 'string', current_fns);
        g_mydata.frags_infos = current_frags_infos;

        g_mydata.current_frags_idx = new_idx;
        set(g_h_fragments_listbox, 'value', g_mydata.current_frags_idx);

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function move_down_fragment_in_list_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % If the list is not empty, we remove all fragment images
        if numel(g_mydata.frags_infos)==0
            return;
        end

        % We move up the current element
        current_frags_infos = g_mydata.frags_infos;
        current_fns         = get(g_h_fragments_listbox, 'string');
        current_idx         = get(g_h_fragments_listbox, 'value');
        new_idx             = mod(current_idx, numel(current_fns))+1;

        [current_frags_infos{new_idx},current_frags_infos{current_idx}] = swap_vars(current_frags_infos{current_idx}, current_frags_infos{new_idx});
        [current_fns{new_idx},current_fns{current_idx}]                 = swap_vars(current_fns{current_idx}, current_fns{new_idx});

        set(g_h_fragments_listbox, 'string', current_fns);
        g_mydata.frags_infos = current_frags_infos;

        g_mydata.current_frags_idx = new_idx;
        set(g_h_fragments_listbox, 'value', g_mydata.current_frags_idx);

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function fragments_alpha_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We enable/disable alpha channel and update the view of the image
        g_mydata.use_frags_alpha = ~g_mydata.use_frags_alpha;

        if ~isempty(g_mydata.frags_infos)
            frag_info           = g_mydata.frags_infos{g_mydata.current_frags_idx};
            g_mydata.im_current = cat(3, frag_info.color, frag_info.alpha);
            update_view(g_mydata.use_frags_alpha);
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function fragments_inner_circle_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We enable/disable flag and update the view of the image
        g_mydata.show_frags_inner_circle = ~g_mydata.show_frags_inner_circle;

        if ~isempty(g_mydata.frags_infos)
            frag_info           = g_mydata.frags_infos{g_mydata.current_frags_idx};
            g_mydata.im_current = cat(3, frag_info.color, frag_info.alpha);
            update_view(g_mydata.use_frags_alpha);
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function fragments_outer_circle_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We enable/disable flag and update the view of the image
        g_mydata.show_frags_outer_circle = ~g_mydata.show_frags_outer_circle;

        if ~isempty(g_mydata.frags_infos)
            frag_info           = g_mydata.frags_infos{g_mydata.current_frags_idx};
            g_mydata.im_current = cat(3, frag_info.color, frag_info.alpha);
            update_view(g_mydata.use_frags_alpha);
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function fragments_inner_circle_color_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We set the color
        g_mydata.frags_inner_circle_color = uisetcolor(g_mydata.frags_inner_circle_color);
        set(h_object, 'backgroundcolor', g_mydata.frags_inner_circle_color);

        if ~isempty(g_mydata.frags_infos)
            frag_info           = g_mydata.frags_infos{g_mydata.current_frags_idx};
            g_mydata.im_current = cat(3, frag_info.color, frag_info.alpha);
            update_view(g_mydata.use_frags_alpha);
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function fragments_outer_circle_color_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We set the color
        g_mydata.frags_outer_circle_color = uisetcolor(g_mydata.frags_outer_circle_color);
        set(h_object, 'backgroundcolor', g_mydata.frags_outer_circle_color);

        if ~isempty(g_mydata.frags_infos)
            frag_info           = g_mydata.frags_infos{g_mydata.current_frags_idx};
            g_mydata.im_current = cat(3, frag_info.color, frag_info.alpha);
            update_view(g_mydata.use_frags_alpha);
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function gen_parameters_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We display the needed information
        fns = fieldnames(g_mydata.gen_parameters);

        if isempty(g_mydata.gen_parameters)
            str = 'The list of gen parameters is empty.';
        else
            str = 'The list of gen parameters is as follows:';

            for k=1:numel(fns)
                value = getfield(g_mydata.gen_parameters, fns{k});

                if isnumeric(value)
                    str = strvcat(str,sprintf('* %s: %f', fns{k}, value));
                elseif isstring(value)
                    str = strvcat(str,sprintf('* %s: %s', fns{k}, value));
                else
                    str = strvcat(str,sprintf('* %s: ???', fns{k}, value));
                end
            end
        end

        helpdlg(str, 'ARTEAK INFO');

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function geometric_constraints_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We display the needed information
        if isempty(g_mydata.geometric_constraints.locations)
            str = 'The list of constrained locations is empty.';
        else
            str = 'The list of constrained locations is as follows (in pixels):';

            for k=1:size(g_mydata.geometric_constraints.locations,1)
                str = strvcat(str, sprintf('* (%f,%f)', g_mydata.geometric_constraints.locations(k,1), g_mydata.geometric_constraints.locations(k,2)));
            end
        end

        if isempty(g_mydata.geometric_constraints.orientations)
            str = strvcat(str, 'The list of constrained orientations is empty.');
        else
            str = strvcat(str, 'The list of constrained orientations is as follows (in degrees):');

            for k=1:numel(g_mydata.geometric_constraints.orientations)
                str = strvcat(str, sprintf('* %f', g_mydata.geometric_constraints.orientations(k)));
            end
        end

        helpdlg(str, 'ARTEAK INFO');

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function reconstructions_list_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % If the reconstructions list is not empty, we update view with the selected one
        if ~isempty(g_mydata.im_recs_color)
            g_mydata.current_recs_idx = get(h_object, 'value');
            g_mydata.im_current       = g_mydata.im_recs_color{g_mydata.current_recs_idx};
            update_view(g_mydata.use_recs_alpha);
            update_reconstruction();
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function add_reconstructions_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We check if fragment images are available
        if isempty(g_mydata.im_fresco) || isempty(g_mydata.frags_infos)
            uiwait(errordlg('Fresco and fragment images must be loaded before loading reconstructions', 'ARTEAK ERROR', 'modal'));
            return;
        end

        % We get the filename of the reconstructions
        if ~isempty(g_mydata.current_fresco_dir)
            recs_dir = g_mydata.current_fresco_dir;
        else
            recs_dir = g_mydata.data_root_dir;
        end

        full_directories = uigetdir(recs_dir, 'Select one or multiple reconstructions');

        % We check if directories are selected
        if isequal(full_directories, 0)
            return;
        end

        % Selected directories are converted to cell array for convenience
        if ~iscell(full_directories)
            full_directories = {full_directories};
        end

        % We sort directories in lexicographical order
        full_directories = natsortfiles(full_directories);

        % We get a shorter version with only last part of path directories
        directories = full_directories;

        for k=1:numel(full_directories)
            [~,directories{k},~] = fileparts(full_directories{k});
        end

        % We display a progress bar
        pbh = waitbar(0, 'Please wait while loading reconstructed frescoes');

        for k=1:numel(full_directories)
            % We check if the reconstruction does not belong to the list of reconstructions
            items = get(g_h_reconstructions_listbox, 'string');
            ok    = true;

            for i=1:numel(items)
                if strcmp(items{i}, directories{k})
                    uiwait(warndlg(sprintf('Reconstruction %s cannot be added because it already belongs to the reconstructions list', directories{k}), 'ARTEAK ERROR', 'modal'));
                    ok = false;
                    break;
                end
            end

            if ~ok
                continue;
            end

            % We check if all text files exist
            true_frags_fn      = [full_directories{k} filesep g_mydata.true_frags_fn];
            neighbors_frags_fn = [full_directories{k} filesep g_mydata.neighbors_frags_fn];

            if ~isfile(true_frags_fn)
                uiwait(errordlg(sprintf('Text file %s not found for reconstruction %s', g_mydata.true_frags_fn, directories{k}), 'ARTEAK ERROR', 'modal'));
                continue;
            end

            if ~isfile(neighbors_frags_fn)
                uiwait(errordlg(sprintf('Text file %s not found for reconstruction %s', g_mydata.neighbors_frags_fn, directories{k}), 'ARTEAK ERROR', 'modal'));
                continue;
            end

            % We load "true" fragments list
            [ids,tx,ty,angles] = textread(true_frags_fn, '%d %f %f %f');

            if numel(ids)~=numel(tx) || numel(tx)~=numel(ty) || numel(ty)~=numel(angles)
                uiwait(errordlg(sprintf('Text file %s is wrongly formatted for reconstruction %s', true_frags_fn, full_directories{k}), 'ARTEAK ERROR', 'modal'));
            end

            % We construct the structure describing a fresco to reconstruct
            frags_sol = {};

            for i=1:numel(ids)
                idx = ids(i)+1;

                if idx>numel(g_mydata.frags_infos)
                    continue;
                end

                angle       = -angles(i); % CAUTION: OPPOSITE ANGLE IS TAKEN
                translation = [ty(i),tx(i)];
                frag_size   = size(g_mydata.frags_infos{idx}.alpha);
                icc         = apply_forward_transform(g_mydata.frags_infos{idx}.inner_circle_center, translation, angle, frag_size*0.5);
                icr         = g_mydata.frags_infos{idx}.inner_circle_radius;
                occ         = apply_forward_transform(g_mydata.frags_infos{idx}.outer_circle_center, translation, angle, frag_size*0.5);
                ocr         = g_mydata.frags_infos{idx}.outer_circle_radius;
                frag_std    = g_mydata.frags_infos{idx}.std;
                frags_sol   = {frags_sol{:},struct('idx', idx, 'translation', translation, 'angle', angle, 'neighbors', [], ...
                                                   'fresco_coords', [], 'frag_coords', [], 'color_idx', [], 'inner_circle_center', icc, ...
                                                   'inner_circle_radius', icr, 'outer_circle_center', occ, 'outer_circle_radius', ocr, 'std', frag_std)};
            end

            % We load neighbors list
            [neighbors1,neighbors2] = textread(neighbors_frags_fn, '%d %d');
            neighbors1              = neighbors1 + 1;
            neighbors2              = neighbors2 + 1;

            if numel(neighbors1)~=numel(neighbors2)
                uiwait(errordlg(sprintf('Text file %s is wrongly formatted for reconstruction %s', neighbors_frags_fn, full_directories{k}), 'ARTEAK ERROR', 'modal'));
            end

            for l=1:numel(frags_sol)
                idx_n     = neighbors2(find(neighbors1==frags_sol{l}.idx));
                neighbors = [];

                for i=1:numel(idx_n)
                    j = find(cellfun(@(x) x.idx, frags_sol)==idx_n(i));
    
                    if numel(j)==1 && j>=1 && j<=numel(frags_sol)
                        neighbors = [neighbors,j];
                    end
                end

                frags_sol{l}.neighbors = neighbors;
            end

            % We build the reconstructed fresco and add it to the list
            [im_rec_gray,~,im_rec_color] = get_reconstructed_fresco(g_mydata.im_fresco(:,:,1:end-1), g_mydata.frags_infos, frags_sol, ...
                                                                    g_mydata.interpolation_type, g_mydata.recs_background_color);
            im_tmp1                      = cat(3, im_rec_color, g_mydata.im_fresco(:,:,end));
            im_tmp2                      = cat(3, im_rec_gray, g_mydata.im_fresco(:,:,end));
            g_mydata.im_recs_color       = {g_mydata.im_recs_color{:},im_tmp1};
            g_mydata.im_recs_filled      = {g_mydata.im_recs_filled{:},im_tmp2};
            g_mydata.frags_sols          = {g_mydata.frags_sols{:},frags_sol};
            set(g_h_reconstructions_listbox, 'string', {items{:},directories{k}});

            % We update the progress bar
            waitbar(k/numel(full_directories), pbh, 'Please wait while loading reconstructed frescoes');
        end

        % We close the progress bar
        delete(findall(0,'type','figure','tag','TMWWaitbar'));

        % We update the view with the first reconstruction of the list
        if numel(g_mydata.frags_sols)>0
            g_mydata.current_recs_idx = numel(g_mydata.frags_sols);
            set(g_h_reconstructions_listbox, 'value', g_mydata.current_recs_idx);
            g_mydata.im_current = g_mydata.im_recs_color{g_mydata.current_recs_idx};
            update_view(g_mydata.use_recs_alpha);
            update_reconstruction();
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function remove_reconstruction_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % If the list of reconstructions is not empty, we remove the current item from it
        if numel(g_mydata.im_recs_color)==0
            return;
        end

        current_idx        = get(g_h_reconstructions_listbox, 'value');
        current_dirs       = get(g_h_reconstructions_listbox, 'string');
        new_frags_sols     = {};
        new_im_recs_filled = {};
        new_im_recs_color  = {};
        new_dirs           = {};
        idx                = 1;

        for k=1:numel(g_mydata.im_recs_color)
            if k~=current_idx
                new_frags_sols{idx}     = g_mydata.frags_sols{k};
                new_im_recs_color{idx}  = g_mydata.im_recs_color{k};
                new_im_recs_filled{idx} = g_mydata.im_recs_filled{k};
                new_dirs{idx}           = current_dirs{k};
                idx                     = idx + 1;
            end
        end

        g_mydata.frags_sols     = new_frags_sols;
        g_mydata.im_recs_color  = new_im_recs_color;
        g_mydata.im_recs_filled = new_im_recs_filled;
        set(g_h_reconstructions_listbox, 'string', new_dirs);

        % We set the current image as empty
        g_mydata.im_current = [];
        delete(get(gca,'Children'));

        if numel(g_mydata.im_recs_color)>0
            g_mydata.current_recs_idx = 1;
        else
            g_mydata.current_recs_idx = -1;
        end
        
        set(g_h_reconstructions_listbox, 'value', g_mydata.current_recs_idx);
        update_view(g_mydata.use_recs_alpha);
        update_reconstruction();

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function clear_reconstructions_list_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % If the list is not empty, we remove all reconstructions
        if numel(g_mydata.im_recs_color)==0
            return;
        end

        g_mydata.frags_sols       = {};
        g_mydata.im_recs_color    = {};
        g_mydata.im_recs_filled   = {};
        g_mydata.im_current       = [];
        g_mydata.current_recs_idx = -1;
        set(g_h_reconstructions_listbox, 'string', {});
        delete(get(gca,'Children'));
        update_view(g_mydata.use_recs_alpha);

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function move_up_reconstruction_in_list_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % If the list is not empty, we remove all reconstructions
        if numel(g_mydata.im_recs_color)==0
            return;
        end

        % We move up the current element
        current_frags_sols  = g_mydata.frags_sols;
        current_recs_color  = g_mydata.im_recs_color;
        current_recs_filled = g_mydata.im_recs_filled;
        current_dirs        = get(g_h_reconstructions_listbox, 'string');
        current_idx         = get(g_h_reconstructions_listbox, 'value');
        new_idx             = mod(current_idx-2, numel(current_dirs))+1;

        [current_frags_sols{new_idx},current_frags_sols{current_idx}]    = swap_vars(current_frags_sols{current_idx}, current_frags_sols{new_idx});
        [current_recs_color{new_idx},current_recs_color{current_idx}]    = swap_vars(current_recs_color{current_idx}, current_recs_color{new_idx});
        [current_recs_filled{new_idx},current_recs_filled{current_idx}]  = swap_vars(current_recs_filled{current_idx}, current_recs_filled{new_idx});
        [current_dirs{new_idx},current_dirs{current_idx}]                = swap_vars(current_dirs{current_idx}, current_dirs{new_idx});

        set(g_h_reconstructions_listbox, 'string', current_dirs);
        g_mydata.frags_sols     = current_frags_sols;
        g_mydata.im_recs_color  = current_recs_color;
        g_mydata.im_recs_filled = current_recs_filled;

        g_mydata.current_recs_idx = new_idx;
        set(g_h_reconstructions_listbox, 'value', g_mydata.current_recs_idx);

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function move_down_reconstruction_in_list_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % If the list is not empty, we remove all reconstructions
        if numel(g_mydata.im_recs_color)==0
            return;
        end

        % We move up the current element
        current_frags_sols  = g_mydata.frags_sols;
        current_recs_color  = g_mydata.im_recs_color;
        current_recs_filled = g_mydata.im_recs_filled;
        current_dirs        = get(g_h_reconstructions_listbox, 'string');
        current_idx         = get(g_h_reconstructions_listbox, 'value');
        new_idx             = mod(current_idx, numel(current_dirs))+1;

        [current_frags_sols{new_idx},current_frags_sols{current_idx}]   = swap_vars(current_frags_sols{current_idx}, current_frags_sols{new_idx});
        [current_recs_color{new_idx},current_recs_color{current_idx}]   = swap_vars(current_recs_color{current_idx}, current_recs_color{new_idx});
        [current_recs_filled{new_idx},current_recs_filled{current_idx}] = swap_vars(current_recs_filled{current_idx}, current_recs_filled{new_idx});
        [current_dirs{new_idx},current_dirs{current_idx}]               = swap_vars(current_dirs{current_idx}, current_dirs{new_idx});

        set(g_h_reconstructions_listbox, 'string', current_dirs);
        g_mydata.frags_sols    = current_frags_sols;
        g_mydata.im_recs_color = current_recs_color;
        g_mydata.im_recs_filled  = current_recs_filled;

        g_mydata.current_recs_idx = new_idx;
        set(g_h_reconstructions_listbox, 'value', g_mydata.current_recs_idx);

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function reconstructions_alpha_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We enable/disable alpha channel and update the view of the image
        g_mydata.use_recs_alpha = ~g_mydata.use_recs_alpha;

        if ~isempty(g_mydata.im_recs_color)
            g_mydata.im_current = g_mydata.im_recs_color{g_mydata.current_recs_idx};
            update_view(g_mydata.use_recs_alpha);
            update_reconstruction();
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function reconstructions_idx_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We enable/disable flag and update the view of the image
        g_mydata.show_recs_idx = ~g_mydata.show_recs_idx;

        if ~isempty(g_mydata.im_recs_color)
            g_mydata.im_current = g_mydata.im_recs_color{g_mydata.current_recs_idx};
            update_view(g_mydata.use_recs_alpha);
            update_reconstruction();
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function reconstructions_inner_circle_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We enable/disable flag and update the view of the image
        g_mydata.show_recs_inner_circle = ~g_mydata.show_recs_inner_circle;

        if ~isempty(g_mydata.im_recs_color)
            g_mydata.im_current = g_mydata.im_recs_color{g_mydata.current_recs_idx};
            update_view(g_mydata.use_recs_alpha);
            update_reconstruction();
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function reconstructions_outer_circle_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We enable/disable flag and update the view of the image
        g_mydata.show_recs_outer_circle = ~g_mydata.show_recs_outer_circle;

        if ~isempty(g_mydata.im_recs_color)
            g_mydata.im_current = g_mydata.im_recs_color{g_mydata.current_recs_idx};
            update_view(g_mydata.use_recs_alpha);
            update_reconstruction();
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function reconstructions_neighbors_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We enable/disable flag and update the view of the image
        g_mydata.show_recs_neighbors = ~g_mydata.show_recs_neighbors;

        if ~isempty(g_mydata.im_recs_color)
            g_mydata.im_current = g_mydata.im_recs_color{g_mydata.current_recs_idx};
            update_view(g_mydata.use_recs_alpha);
            update_reconstruction();
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function reconstructions_idx_color_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We set the color
        g_mydata.recs_idx_color = uisetcolor(g_mydata.recs_idx_color);
        set(h_object, 'backgroundcolor', g_mydata.recs_idx_color);

        % We update the current view of the image
        if ~isempty(g_mydata.im_recs_color)
            g_mydata.im_current = g_mydata.im_recs_color{g_mydata.current_recs_idx};
            update_view(g_mydata.use_recs_alpha);
            update_reconstruction();
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function reconstructions_inner_circle_color_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We set the color
        g_mydata.recs_inner_circle_color = uisetcolor(g_mydata.recs_inner_circle_color);
        set(h_object, 'backgroundcolor', g_mydata.recs_inner_circle_color);

        % We update the current view of the image
        if ~isempty(g_mydata.im_recs_color)
            g_mydata.im_current = g_mydata.im_recs_color{g_mydata.current_recs_idx};
            update_view(g_mydata.use_recs_alpha);
            update_reconstruction();
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function reconstructions_outer_circle_color_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We set the color
        g_mydata.recs_outer_circle_color = uisetcolor(g_mydata.recs_outer_circle_color);
        set(h_object, 'backgroundcolor', g_mydata.recs_outer_circle_color);

        % We update the current view of the image
        if ~isempty(g_mydata.im_recs_color)
            g_mydata.im_current = g_mydata.im_recs_color{g_mydata.current_recs_idx};
            update_view(g_mydata.use_recs_alpha);
            update_reconstruction();
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function reconstructions_neighbors_color_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We set the color
        g_mydata.recs_neighbors_color = uisetcolor(g_mydata.recs_neighbors_color);
        set(h_object, 'backgroundcolor', g_mydata.recs_neighbors_color);

        % We update the current view of the image
        if ~isempty(g_mydata.im_recs_color)
            g_mydata.im_current = g_mydata.im_recs_color{g_mydata.current_recs_idx};
            update_view(g_mydata.use_recs_alpha);
            update_reconstruction();
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function contrast_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We get the contrast factor
        g_mydata.contrast = get(h_object, 'Value');
        set(g_h_contrast_label, 'string', sprintf('Contrast: %.1f', g_mydata.contrast));

        % We change the contrast of the image and display it
        update_view(g_mydata.current_alpha);
        update_reconstruction();

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function luminosity_changed_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We get the contrast factor
        g_mydata.luminosity = get(h_object, 'Value');
        set(g_h_luminosity_label, 'string', sprintf('Luminosity: %.1f', g_mydata.luminosity));

        % We change the contrast of the image and display it
        update_view(g_mydata.current_alpha);
        update_reconstruction();

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function reconstruction_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We open the reconstruction subwindow
        [new_frags_sol,new_im_rec_color,new_im_rec_filled,rec_name] = arteak_reconstruction(g_fh_main);

        % We check if results are consistent
        if ~isempty(new_frags_sol) && ~isempty(new_im_rec_color) && ~isempty(new_im_rec_filled)
            % If so, we add results to their respective arrays
            g_mydata.im_recs_filled  = {g_mydata.im_recs_filled{:},new_im_rec_filled};
            g_mydata.im_recs_color = {g_mydata.im_recs_color{:},new_im_rec_color};
            g_mydata.frags_sols    = {g_mydata.frags_sols{:},new_frags_sol};

            recs_list = get(g_h_reconstructions_listbox, 'string');
            set(g_h_reconstructions_listbox, 'string', {recs_list{:},rec_name});
            g_mydata.current_recs_idx = numel(recs_list)+1;
            set(g_h_reconstructions_listbox, 'value', g_mydata.current_recs_idx);
            g_mydata.im_current = new_im_rec_color;
            update_view(g_mydata.use_recs_alpha);
            update_reconstruction();
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function comparison_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We open the comparison subwindow
        arteak_comparison(g_fh_main);

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function measurements_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We open the measurements subwindow
        arteak_measurements(g_fh_main);

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function unload_all_data_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We use a flag for view updating
        clear_view = false;

        % We unload fresco data
        if ~isempty(g_mydata.im_fresco)
            g_mydata.current_fresco_dir = [];
            g_mydata.im_fresco          = [];
            clear_view                  = true;
            set(g_h_fresco_filename_edit, 'string', '');
        end

        % We unload reconstructions data
        if numel(g_mydata.im_recs_color)>0
            g_mydata.im_recs_color    = {};
            g_mydata.im_recs_filled   = {};
            g_mydata.current_recs_idx = -1;
            clear_view                = true;
            set(g_h_reconstructions_listbox, 'string', {});
        end

        % We unload fragments data
        if numel(g_mydata.frags_infos)>0
            g_mydata.current_frags_dir     = [];
            g_mydata.frags_infos           = {};
            g_mydata.gen_parameters        = [];
            g_mydata.geometric_constraints = [];
            g_mydata.current_frags_idx     = -1;
            clear_view                     = true;
            set(g_h_fragments_listbox, 'string', {});
        end

        % We make as empty current image view
        if clear_view
            g_mydata.im_current = [];
            delete(get(gca,'Children'));
            update_view(g_mydata.use_fresco_alpha);
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function save_image_view_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We check if current view is available
        if isempty(g_mydata.im_current)
            uiwait(errordlg('Please fill view with some image before saving it', 'ARTEAK ERROR', 'modal'));
        else
            % We get an image of current view
            f = getframe(g_mydata.axes);
            im_view = frame2im(f);

            % We ask for filename to save
            [filename,directory] = uiputfile({'*.png'}, 'Save view as image file', 'view.png');

            % We save view as image file
            if ~isequal(filename,0) && ~isequal(directory,0)
                imwrite(im_view, fullfile(directory,filename));
            end
        end

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function quit_callback( h_object, event_data )
        delete(gcf);
    end

    function help_software_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We open the webpage of the software
        web(g_mydata.software_url);

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function help_datasets_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We open the webpage of the datasets
        web(g_mydata.datasets_url);

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end

    function about_callback( h_object, event_data )
        % We load GUI data
        g_mydata = guidata(g_fh_main);

        % We open the about subwindow
        arteak_about(g_fh_main);

        % We save GUI data
        guidata(g_fh_main, g_mydata);
    end
end