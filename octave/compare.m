#!/usr/bin/octave -qf

% load functions from a directory of this script
addpath(fileparts(mfilename('fullpath')));

arg_list = argv();

% 1 = left, 2 = right
if (length(arg_list) >= 1)
    channel = str2num(arg_list{1});
else
    channel = 1;
end

showFFTwithDiff('cal-in.wav', channel, 'Recorded', 1, 4);
showFFTwithDiff('ver-in.wav', channel, 'Recovered', 3, 4);

waitforbuttonpress();

print(strcat('cmp-in', num2str(channel), '.pdf'))
