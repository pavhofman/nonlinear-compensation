
# at least 2 secs of recording, stereo or mono
wavPath = "/home/hestia/tmp/octave/wavs/juli/recorded.wav";
# 1 = left, 2 = right
channel = 2;


# measured frequency (TODO - detect/adjust automatically by measuring relative phaseshift of reference and recorded at the end of recorded/reference)
measfreq = 1000.000;

format long;
[recorded, fs] = audioread(wavPath);

if columns(recorded) > 1
%    % convert to mono
    recorded = recorded(:, channel);
end

# Offset must be large enough to skip samples from the first alsa period where some garbled data appears.
# Alsa period size could be read precisely from /proc/asound/cardXXX/pcmXc/sub0/hw_params
# Safe bet is 200ms.
offset = 0.2 * fs;

# For the phase detection to work precisely, fft must be applied to number of samples corresponding exctly to whole measfreq periods (to the sample)
# Too many periods can result in imprecise phase detection due to instable fs lock. Just a few periods actually suffice.

# Warning - 44100Hz FS requires multiples of 10 for measfreq = 1kHz (10 * 44100/1000  => integer )

# number of measfreq periods for phase detection
periods = 10;

recorded = recorded(offset + 1:end);

samplesInPeriods = periods * fs/measfreq;
x = recorded(1:offset + samplesInPeriods);

ys = fft(x);
ys = fftshift(ys);
# remove frequency mirror
bins = length(x)/2;
ys = ys(bins + 1:length(x));

f = linspace(1, fs/2, bins);


# We want to see ys maximum. We do it by zeroing all ys under certain level (note - we did not normalize, raw numbers!)
# TODO - this procedure needs more robustness
yslimit = 10;
ys(abs(ys) < yslimit) = 0;

# plotting abs(fft)
subplot(3,1,1);
stem(f,abs(ys));
xlabel 'Frequency (Hz)';
ylabel '|y|';
grid;

phs = angle(ys);

# plotting phase(fft)
subplot(3,1,2);
stem(f,phs/pi)
xlabel 'Frequency (Hz)';
ylabel 'Phase / \pi';
grid;


# We need to find phase of the largest fft value
[max_fft, index] =max(ys);
phaseshift = phs(index);

offset
phaseshift

# plotting phase alignment of calculated reference sine and recorded at the end of the array

# generating the reference sine
t = 0:1/fs:length(recorded)/fs;
t = t(1:length(recorded));
refGain = db2mag(-3);
reference = cos(2*pi * measfreq * t + phaseshift)* refGain;

# finding end of arrays
samplesPlotted = 100;
# just in case the final samples of the wav are garbled
offsetFromEnd = 100;
endPos = length(recorded) - offsetFromEnd;
lowT = endPos - samplesPlotted;
highT = endPos;

# the curves must be exactly phase-aligned!!!
subplot(3,1,3);
plot((lowT:highT), recorded(lowT:highT), "-", (lowT:highT), reference(lowT:highT), "*");
