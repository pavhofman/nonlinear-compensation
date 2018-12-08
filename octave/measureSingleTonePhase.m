% determining phase and amplitude with curve fitting - for one tone
function measuredPeaksCh = measureSingleTonePhase(samples, fs, fundPeaksCh, showCharts)
  fundAmpl = fundPeaksCh(1, 2);
  measfreq = fundPeaksCh(1, 1);

  totalSamples = length(samples);
  t = linspace(0, (totalSamples - 1)/fs, totalSamples)';
  % curve - phaseshifted cosine
  f = @(p, x) cos(2*pi * measfreq * x + p(2))* p(1);
  % curve fitting init - amplitude should be close to fundAmpl, phaseShift is unknown
  init = [fundAmpl; 0];
  y = samples(1:totalSamples);
  % unfortunately no lower/upper bounds work
  [p, model_values, cvg, outp] = nonlin_curvefit (f, init, t, y);
  ampl = p(1);
  phaseShift = p(2);
  % we need ampl > 0. If ampl < 0, we must invert phase
  [ampl, phaseShift] = fixMeasuredAmplPhase(ampl, phaseShift);
  
  measuredPeaksCh = [measfreq, ampl, phaseShift];

  if (!showCharts)
    return;
  endif

  # generating the reference sine
  t = 0:1/fs:length(samples)/fs;
  t = t(1:length(samples));
  reference = cos(2*pi * measfreq * t + phaseShift)* ampl;

  # finding end of arrays
  samplesPlotted = 100;
  # just in case the final samples of the wav are garbled
  offsetFromEnd = 100;
  endPos = length(samples) - offsetFromEnd;
  lowT = endPos - samplesPlotted + 1;
  highT = endPos;

  # the curves must be exactly phase-aligned!!!
  subplot(2,1,2);
  plot((lowT:highT), samples(lowT:highT), "-", (lowT:highT), reference(lowT:highT), "*");
  waitforbuttonpress();

endfunction
