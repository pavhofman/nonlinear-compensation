#!/usr/bin/octave -qf
addpath(fileparts(mfilename('fullpath')));

if (exist('config.m'))
  source 'config.m';
else
  [ wavPath, channel, showCharts ] = loadCalibArgv(argv());
endif
  

[recorded, fs] = audioreadAndCut(wavPath, channel);

samples = recorded(1:fs);
peaks = getHarmonics(samples, fs);

format short;
disp(convertPeaksToPrintable(peaks));
% WIP
return;
