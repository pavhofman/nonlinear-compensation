addpath(fileparts(mfilename('fullpath')));
% we cannot call 'clear all' since it clears all funcions => also all breakpoints in funcions
clear;
source 'consts.m';
direction = DIR_PLAY;
source 'main.m';