[measuredPeaks, startingT, fundPeaks, distortPeaks, freqs, result] = analyse(buffer, fs, freqs, calDeviceName, extraCircuit, restartAnalysis);
restartAnalysis = false;
if (result == 1)
  % finished
  % from now on only compensation
  %status = COMPENSATING;
  % or could start new analysis right away + keeping DISTORTING flag
  isDistorting = statusContains(status, DISTORTING);  
  status = [COMPENSATING, ANALYSING];
  if (isDistorting)
    status = [status, DISTORTING];
  endif
endif
