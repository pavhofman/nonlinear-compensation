function [refGain, phaseShift, ys, bins] = measurePhase(recorded, fs, measfreq, showCharts)
  % For the phase detection to work precisely, fft must be applied to number of samples corresponding exctly to whole measfreq periods (to the sample)
  % Too many periods can result in imprecise phase detection due to instable fs lock. Just a few periods actually suffice.

  % Warning - 44100Hz FS requires multiples of 10 for measfreq = 1kHz (10 * 44100/1000  => integer )

  % number of measfreq periods for phase detection
  periods = 10;

  samplesInPeriods = periods * uint32(fs/measfreq);
  x = recorded(1:samplesInPeriods);

  ys = fft(x);
  ys = fftshift(ys);
  % remove frequency mirror
  bins = length(x)/2;
  ys = ys(bins + 1:length(x));

  % We need to find amplitude and phase of the largest fft value
  [max_fft, index] =max(ys);
  refGain = abs(max_fft) / bins;
  phaseShift = angle(max_fft);
  if (!showCharts)
    return;
  endif

  # plotting abs(fft)
  f = linspace(1, fs/2, bins);

  subplot(2,1,1);
  stem(f,abs(ys));
  xlabel 'Frequency (Hz)';
  ylabel '|y|';
  grid;


  # generating the reference sine
  t = 0:1/fs:length(recorded)/fs;
  t = t(1:length(recorded));
  refGain = db2mag(-12);
  reference = cos(2*pi * measfreq * t + phaseShift)* refGain;

  # finding end of arrays
  samplesPlotted = 100;
  # just in case the final samples of the wav are garbled
  offsetFromEnd = 100;
  endPos = length(recorded) - offsetFromEnd;
  lowT = endPos - samplesPlotted;
  highT = endPos;

  # the curves must be exactly phase-aligned!!!
  subplot(2,1,2);
  plot((lowT:highT), recorded(lowT:highT), "-", (lowT:highT), reference(lowT:highT), "*");
  waitforbuttonpress();

endfunction
