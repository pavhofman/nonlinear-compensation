#!/usr/bin/octave -qf

% load functions from a directory of this script
addpath(fileparts(mfilename('fullpath')));

arg_list = argv();

if (length(arg_list) < 1)
    printf('Usage: %s AUDIO_FILE [channel:1|2] [|w|p]\n', program_name());
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

% show or not to show graphs
if (length(arg_list) >= 3)
    show = arg_list{3};
else
    show = '';
end

showFFTwithDiff(wavPath, channel, 'Input', 1, 2);

waitOrPrint(show, wavPath, '', channel);
