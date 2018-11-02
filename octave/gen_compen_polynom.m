#!/usr/bin/octave -qf

% load functions from a directory of this script
addpath(fileparts(mfilename('fullpath')));

arg_list = argv();

if (length(arg_list) < 1)
    printf('Usage: %s INPUT_FILE [channel:1|2] [polydeg:5] [frequency:1000] [|q|w]\n', program_name());
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

% polynome degree
if (length(arg_list) >= 3)
    polyDeg = str2num(arg_list{3});
else
    polyDeg = 5;
end

% measured frequency (TODO - detect/adjust automatically by measuring relative phaseShift of reference and recorded at the end of recorded/reference)
if (length(arg_list) >= 4)
    measfreq = str2num(arg_list{4});
else
    measfreq = 1000.0;
end

% show or not to show graphs
if (length(arg_list) >= 5)
    show = arg_list{5};
else
    show = '';
end

format long e;
[recorded, fs] = audioreadAndCut(wavPath, channel);

% refGain:
%   the polynomial will transform recorded to reference. Adjust gain of the generated reference sine to fit the recorded first harmonics.
% phaseShift:
%   polynomial can be generated only when the phase shift is correctly detected
%   (i.e. only one peak, recorded and reference waveforms are at the end properly aligned!
[refGain, phaseShift, ys, bins] = measurePhase(recorded, fs, measfreq);

t = 0:1/fs:length(recorded)/fs;
t = t(1:length(recorded))';
reference = cos(2*pi * measfreq * t + phaseShift) * refGain;

polyCoeff = polyfit(recorded, reference, polyDeg);

polyCoeffPath = regexprep(wavPath, '(.*).wav', strcat('$1.polycoeff', num2str(channel)));
f = fopen(polyCoeffPath, 'w');
fprintf(f, 'polynom [');
fprintf(f, ' %e', fliplr(polyCoeff));
fprintf(f, ' ]\n');
fclose(f);

if (show == 'q')
    return;
end

plotsCnt = 2;
showFFT(recorded, "Recorded", 1, fs, plotsCnt);

recovered = polyval(polyCoeff, recorded);
showFFT(recovered, "Recovered", 2, fs, plotsCnt);

printf("Compensation Polynomial (copy to capture route 'polynom [ xx xx xx ...]'):\n");
disp(fliplr(polyCoeff)');

waitOrPrint(show, wavPath, '', channel);
