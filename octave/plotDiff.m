function plotDiff(recorded, reference, fs, bins, plotID, plotsCnt, name)
  f = linspace(1, fs/2, bins);

  % plotting phase alignment of calculated reference sine and recorded at the end of the array

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
