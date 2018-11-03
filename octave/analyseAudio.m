#!/usr/bin/octave -qf

pkg load signal;

% load functions from a directory of this script
addpath(fileparts(mfilename('fullpath')));

arg_list = argv();

if (length(arg_list) < 1)
    printf('Usage: %s AUDIO_FILE [channel:1|2] [frequency:1000] [|w|p]\n', program_name());
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

[recorded, fs] = audioreadAndCut(wavPath, channel);

[ peaks, x, y ] = getHarmonics(recorded, fs);

fprintf(['Signal:\n']);
fprintf('%8.2f Hz, %7.2f dB, %7.2f dg\n', peaks');

label2 = cstrcat('Signal with filterred fundamental (fundamental ~',
    num2str(peaks(1,1), '%.2f'), ' kHz, ',
    num2str(peaks(1,2), '%.2f'), ' dB)');

plotsCnt = 5;

reference = getReferenceSignal(recorded, fs, measfreq);
diff = recorded - reference;

[ peaks, x, y ] = getHarmonics(diff, fs);
drawHarmonics(x, y, label2, 1, plotsCnt, [-150, -70]);

plotDiff(diff, 2, plotsCnt, label2);

h1 = filterHarmonic(diff, fs, measfreq, 1);
plotDiff(h1, 3, plotsCnt, 'fundamental residual');

h2 = filterHarmonic(diff, fs, measfreq, 2);
plotDiff(h2, 4, plotsCnt, '2nd harmonic residual');

h3 = filterHarmonic(diff, fs, measfreq, 3);
plotDiff(h3, 5, plotsCnt, '3rd harmonic residual');

waitOrPrint(show, wavPath, '', channel);
