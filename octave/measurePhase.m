function [refGain, phaseShift, ys, bins] = measurePhase(recorded, fs, measfreq)
  % Offset must be large enough to skip samples from the first alsa period where some garbled data appears.
  % Alsa period size could be read precisely from /proc/asound/cardXXX/pcmXc/sub0/hw_params
  % Safe bet is 200ms.
  offset = 0.2 * fs;

  % For the phase detection to work precisely, fft must be applied to number of samples corresponding exctly to whole measfreq periods (to the sample)
  % Too many periods can result in imprecise phase detection due to instable fs lock. Just a few periods actually suffice.

  % Warning - 44100Hz FS requires multiples of 10 for measfreq = 1kHz (10 * 44100/1000  => integer )

  % number of measfreq periods for phase detection
  periods = 10;

  samplesInPeriods = periods * fs/measfreq;
  x = recorded(offset + 1:offset + samplesInPeriods);

  ys = fft(x);
  ys = fftshift(ys);
  % remove frequency mirror
  bins = length(x)/2;
  ys = ys(bins + 1:length(x));

  % We need to find amplitude and phase of the largest fft value
  [max_fft, index] =max(ys);
  refGain = abs(max_fft) / bins;
  phaseShift = angle(max_fft);
endfunction
