[info.measuredPeaks, startingT, info.fundPeaks, info.distortPeaks, result] = analyse(buffer, fs, calDeviceName, compExtraCircuit, restartAnalysis);
restartAnalysis = false;
if result == FINISHED_RESULT
  % finished
  % from now on only compensation
  %status = COMPENSATING;
  % or could start new analysis right away + keeping DISTORTING flag
  addStatus(COMPENSATING);
  addStatus(ANALYSING);
endif
