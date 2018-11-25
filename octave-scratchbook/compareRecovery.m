#!/usr/bin/octave -qf

% load functions from a directory of this script
addpath(fileparts(mfilename('fullpath')));

arg_list = argv();

if (length(arg_list) < 2)
    printf('Usage: %s RECORDED_FILE RECOVERED_FILE [channel:1|2] [|q|w]\n', program_name());
    return
end

% at least 2 secs of recording, stereo or mono
recordedPath = arg_list{1};
recoveredPath = arg_list{2};

% 1 = left, 2 = right
if (length(arg_list) >= 3)
    channel = str2num(arg_list{3});
else
    channel = 1;
end

% show or not to show graphs
if (length(arg_list) >= 4)
    show = arg_list{4};
else
    show = '';
end

showFFTwithDiff(recordedPath, channel, 'Recorded', 1, 4);
showFFTwithDiff(recoveredPath, channel, 'Recovered', 3, 4);

[dir, name2, ext] = fileparts(recoveredPath);
waitOrPrint(show, recordedPath, strcat('-', name2), channel);
