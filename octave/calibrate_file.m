#!/usr/bin/octave -qf
addpath(fileparts(mfilename('fullpath')));

if (exist('config.m'))
  source 'config.m';
else
  [ wavPath, channel, showCharts ] = loadCalibArgv(argv());
endif
  

[recorded, fs] = audioreadAndCut(wavPath, channel);

samples = recorded(1:fs, :);
peaks = getHarmonics(samples, fs);

format short;
disp(convertPeaksToPrintable(peaks));

calRec.time = time();
calRec.direction = 'capture';
calRec.device = wavPath;
calRec.channel = channel;
calRec.freq = peaks(1,1);
calRec.level = peaks(1,2);
calRec.peaks = peaks(1:10,:);

disp(calRec);

save(calFile, "calRec");
