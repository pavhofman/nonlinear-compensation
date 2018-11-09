#!/usr/bin/octave -qf
addpath(fileparts(mfilename('fullpath')));

if (exist('config.m'))
  source 'config.m';
else
  [ wavPath, channel, showCharts ] = loadCalibArgv(argv());
endif
  
load 'cal.dat' calRec;

peaks = calRec.peaks;
disp(convertPeaksToPrintable(peaks));

measfreq = peaks(1, 1);

[recorded, fs] = audioreadAndCut(wavPath, channel);

periodLength = fs/measfreq;

periods = 1200;
cnt = periodLength * periods;
lowerLimit = fs * 2;
%lowerLimit = 1;

recorded = recorded(lowerLimit:lowerLimit + cnt - 1);

% finding phase

[ampl, phase] = measurePhase(recorded, fs, measfreq, false);

% only first 10 harmonics
refFragment = genCompenReference(peaks(1:10, :), phase, ampl, fs, periodLength);
reference = repmat(refFragment, periods, 1);

showFFT(reference, "Reference", 1, fs, 2);



showFFT(recorded + reference, "Recovered", 2, fs, 2);



