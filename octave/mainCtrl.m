clear;
currDir = fileparts(mfilename('fullpath'));
addpath(currDir);
ctrlDir = [currDir filesep() 'ctrl'];
addpath(ctrlDir);


source 'consts.m';

% we need some global settings
source 'config.m';
source ([ctrlDir filesep() 'run_ctrl.m']);