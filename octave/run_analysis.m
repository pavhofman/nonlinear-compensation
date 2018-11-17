[compenReference, result] = analyse(buffer, fs, freqs, restartAnalysis);
compenPos = 1;
restartAnalysis = false;
if (result == 1)
  % finished
  % from now on only compensation
  %status = COMPENSATING;
  % or could start new analysis right away + keeping DISTORTING flag
  status = bitor(bitor(COMPENSATING, ANALYSING), bitand(status, DISTORTING));
endif
