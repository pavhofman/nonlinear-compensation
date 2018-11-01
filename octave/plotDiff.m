function plotDiff(recorded, fs, measfreq, refGain, phaseShift, ys, bins, plotID, plotsCnt, name)
  f = linspace(1, fs/2, bins);

  % plotting phase alignment of calculated reference sine and recorded at the end of the array

  % generating the reference sine
  t = 0:1/fs:length(recorded)/fs;
  t = t(1:length(recorded))';
  reference = cos(2*pi * measfreq * t + phaseShift)* refGain;

  % finding end of arrays
  samplesPlotted = 1000;
  endPos = length(recorded);
  % align to have a nice graph
  endPos = endPos - mod(endPos, samplesPlotted);
  lowT = endPos - samplesPlotted;
  highT = endPos;

  subplot(plotsCnt,1,plotID);
  plot(
    (lowT:highT), recorded(lowT:highT)-reference(lowT:highT)
  );
  t = strcat(name, ' - Reference (difference)');
  title(t);
endfunction
