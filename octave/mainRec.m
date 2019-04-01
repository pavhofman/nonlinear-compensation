addpath(fileparts(mfilename('fullpath')));

clear;
source 'consts.m';
global direction = DIR_REC;
global logPath = stdout;

source 'main.m';