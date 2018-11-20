% determining phase and amplitude with curve fitting
function [ampl, phaseShift] = measurePhaseCurvefit(recorded, fs, measfreq, fundAmpl, showCharts)
  periodLength = floor(fs/measfreq); 
  % even a fraction of period will do, but the more periods, the better when larger distortion is involved (more data for curve fitting)
  periods = min(2, floor(length(recorded)/periodLength));
  totalSamples = periods * periodLength;

  t = 0:1/fs:totalSamples/fs;
  t = t(1:totalSamples)';
  % curve - phaseshifted cosine
  f = @(p, x) cos(2*pi * measfreq * x + p(2))* p(1);
  % curve fitting init - amplitude should be close to fundAmpl, phaseShift is unknown
  init = [fundAmpl; 0];
  y = recorded(1:totalSamples);
  [p, model_values, cvg, outp] = nonlin_curvefit (f, init, t, y);
  ampl = p(1);
  phaseShift = p(2);
  
  if (!showCharts)
    return;
  endif

  # generating the reference sine
  t = 0:1/fs:length(recorded)/fs;
  t = t(1:length(recorded));  
  reference = cos(2*pi * measfreq * t + phaseShift)* ampl;

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
