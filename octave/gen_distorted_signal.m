#!/usr/bin/octave -qf

pkg load control
pkg load miscellaneous
pkg load signal

% load functions from a directory of this script
addpath(fileparts(mfilename('fullpath')));

arg_list = argv();

if (length(arg_list) >= 1)
    fundfreq = str2num(arg_list{1});
else
    fundfreq = 1000;
end

l = (length(arg_list) - 1) / 2;
for i = 1:l
    vol(i) = str2num(arg_list{2*i});
    pha(i) = str2num(arg_list{2*i + 1});
    if (vol(i) > 0)
        printf('Error: volume for harmonic #%d is too high!', i);
        exit(1);
    end
endfor
if l == 0
    vol(1) = 0;
    pha(1) = 0;
    l = 1;
end
l += 1;

# Generating distortion polynom from specification
leftpadz = @(p) [zeros(1,max(0,l-numel(p))),p];

poly = leftpadz(0);
fn = '';
for i = 1:l-1
    poly += leftpadz(db2mag(vol(i)) * chebyshevpoly(1,i));
    fn = sprintf('%s_%d(%d@%d)', fn, i, vol(i), pha(i));
endfor

% generating the reference sine
fs = 44100;
t = 0:1/fs:12;
reference = sin(2*pi * fundfreq * t');

signal = polyval(poly, reference);

if max(signal) >= 1 || min(signal) <= -1
    printf('Warning: Possible clipping!');
end

% TODO implement phase alignment

signalPath = sprintf('signal_%dHz%s.wav', fundfreq, fn);
audiowrite(signalPath, real(signal), fs, 'BitsPerSample', 32);


%%% TODO work-in-progress (display graphs)

[ peaks, x, y ] = getHarmonics(signal, fs);
fprintf(['Signal:\n']);
fprintf('%8.2f Hz, %7.2f dB, %7.2f dg\n', peaks');

plotsCnt = 2;

reference = getReferenceSignal(signal, fs, fundfreq);
diff = signal - reference;

[ peaks, x, y ] = getHarmonics(diff, fs);
drawHarmonics(x, y, '', 1, plotsCnt, [-150, -0]);

h2 = filterHarmonic(signal, fs, fundfreq, 2);
plotDiff(h2, 1, plotsCnt, '2nd harmonic');

[a,b] = allpass(1, x=2000+10, x, 1-1/200, 44100);
signal2 = filter(a, b, signal);

[ peaks, x, y ] = getHarmonics(signal2, fs);
fprintf(['Signal:\n']);
fprintf('%8.2f Hz, %7.2f dB, %7.2f dg\n', peaks');

h2 = filterHarmonic(signal2, fs, fundfreq, 2);
plotDiff(h2, 2, plotsCnt, '2nd harmonic aligned');

waitOrPrint('w');
