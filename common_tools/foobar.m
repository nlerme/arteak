clear all;
close all;
clc;

fns = {'giotto_95_ed_grayscale.mat','giotto_95_ed_rgb.mat',...
       'piero_183_ed_grayscale.mat','piero_183_ed_rgb.mat',...
       'piero_109_ed_grayscale.mat','piero_109_ed_rgb.mat'};

for k=1:numel(fns)
    disp(sprintf('+ %s', fns{k}));
    r = load(fns{k});
    frag_intensities_tf   = r.frag_intensities_tp;   % true fragment
    fresco_intensities_tf = r.fresco_intensities_tp; % true fragment
    frag_intensities_ff   = r.frag_intensities_fp;   % false fragment
    fresco_intensities_ff = r.fresco_intensities_fp; % false fragment
    save(fns{k}, '-v7.3', 'frag_intensities_tf', 'fresco_intensities_tf', 'frag_intensities_ff', 'fresco_intensities_ff');
end

disp('-----------------');

fns = {'giotto_95_esf_grayscale.mat','giotto_95_esf_rgb.mat',...
       'piero_183_esf_grayscale.mat','piero_183_esf_rgb.mat',...
       'piero_109_esf_grayscale.mat','piero_109_esf_rgb.mat'};

for k=1:numel(fns)
    disp(sprintf('+ %s', fns{k}));
    r = load(fns{k});
    frag_i_intensities_tn = r.frag_i_intensities_tp; % true neighbors i
    frag_j_intensities_tn = r.frag_j_intensities_tp; % true neighbors j
    frag_i_intensities_fn = r.frag_i_intensities_fp; % false neighbors i
    frag_j_intensities_fn = r.frag_j_intensities_fp; % false neighbors j
    save(fns{k}, '-v7.3', 'frag_i_intensities_tn', 'frag_j_intensities_tn', 'frag_i_intensities_fn', 'frag_j_intensities_fn');
end