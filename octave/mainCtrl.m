clear;
currDir = fileparts(mfilename('fullpath'));
addpath(currDir);
ctrlDir = [currDir filesep() 'ctrl'];
addpath(ctrlDir);


source 'consts.m';

% we need some global settings - assuming recording direction (corresponding to config.m)
direction = DIR_REC;
source 'config.m';
source 'run_device_names.m';

source ([ctrlDir filesep() 'run_ctrl.m']);