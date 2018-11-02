#!/usr/bin/octave -qf

% load functions from a directory of this script
addpath(fileparts(mfilename('fullpath')));

arg_list = argv();

if (length(arg_list) < 1)
    printf('Usage: %s INPUT_FILE [channel:1|2] [frequency:1000] [|w|p]\n', program_name());
    return
end

% at least 2 secs of recording, stereo or mono
wavPath = arg_list{1};

% 1 = left, 2 = right
if (length(arg_list) >= 2)
    channel = str2num(arg_list{2});
else
    channel = 1;
end

% measured frequency (TODO - detect/adjust automatically by measuring relative phaseshift of reference and recorded at the end of recorded/reference)
if (length(arg_list) >= 3)
    measfreq = str2num(arg_list{3});
else
    measfreq = 1000.0;
end

% show or not to show graphs
if (length(arg_list) >= 4)
    show = arg_list{4};
else
    show = '';
end

format long;
[recorded, fs] = audioreadAndCut(wavPath, channel);

[refGain, phaseShift, ys, bins] = measurePhase(recorded, fs, measfreq);
y = 20 * log10(refGain)
phaseShift

plotPhase(recorded, fs, measfreq, refGain, phaseShift, ys, bins);

waitOrPrint(show, wavPath, '', channel);
