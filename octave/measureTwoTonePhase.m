% determining phase and amplitude with curve fitting
function measuredPeaksCh = measureTwoTonePhase(samples, fs, fundPeaksCh, showCharts)
  origAmpl1 = fundPeaksCh(1, 2);
  origFreq1 = fundPeaksCh(1, 1);

  origAmpl2 = fundPeaksCh(2, 2);
  origFreq2 = fundPeaksCh(2, 1);
  
  totalSamples = length(samples);
  t = linspace(0, (totalSamples - 1)/fs, totalSamples)';
  % curve - phaseshifted cosine
  f = @(p, x) cos(2*pi * origFreq1 * x + p(2))* p(1) + cos(2*pi * origFreq2 * x + p(4))* p(3);
  % curve fitting init - amplitude should be close to fundAmpl, phaseShift is unknown
  init = [origAmpl1; 0;, origAmpl2; 0];
  y = samples(1:totalSamples);
  [p, model_values, cvg, outp] = nonlin_curvefit (f, init, t, y);  
  ampl1 = p(1);
  phaseShift1 = p(2);
  
  ampl2 = p(3);
  phaseShift2 = p(4);
  % we need ampl > 0. If ampl < 0, we must invert phase
  [ampl1, phaseShift1] = fixMeasuredAmplPhase(ampl1, phaseShift1);
  [ampl2, phaseShift2] = fixMeasuredAmplPhase(ampl2, phaseShift2);

  measuredPeaksCh = [ origFreq1, ampl1, phaseShift1];
  measuredPeaksCh = [measuredPeaksCh; origFreq2, ampl2, phaseShift2];
  if (!showCharts)
    return;
  endif

  # generating the reference sine
  t = 0:1/fs:length(samples)/fs;
  t = t(1:length(samples));  
  reference = f(p, t);

  # finding end of arrays
  samplesPlotted = 80;
  # just in case the final samples of the wav are garbled
  offsetFromEnd = 0;
  endPos = length(samples) - offsetFromEnd;
  lowT = endPos - samplesPlotted;
  highT = endPos;

  # the curves must be exactly phase-aligned!!!
  subplot(2,1,2);
  plot((lowT:highT), samples(lowT:highT), "-", (lowT:highT), reference(lowT:highT), "*");
  waitforbuttonpress();

endfunction
