addpath(fileparts(mfilename('fullpath')));

clear;
source 'consts.m';
global direction;
direction = DIR_REC;
global logPath;
logPath = stdout;

source 'main.m';