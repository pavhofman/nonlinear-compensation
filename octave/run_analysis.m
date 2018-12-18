[measuredPeaks, startingT, fundPeaks, distortPeaks, freqs, result] = analyse(buffer, fs, freqs, calDeviceName, compExtraCircuit, restartAnalysis);
restartAnalysis = false;
if (result == 1)
  % finished
  % from now on only compensation
  %status = COMPENSATING;
  % or could start new analysis right away + keeping DISTORTING flag
  status = addStatus(status, COMPENSATING);
  status = addStatus(status, ANALYSING);
endif
