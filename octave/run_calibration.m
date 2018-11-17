result = calibrate(buffer, fs, restartCal);
restartCal = false;
if (result == 1)
  % finished
  % request compensation
  cmd = COMPENSATE;
  % tell analysis to re-read the updated calibration file
  restartAnalysis = true;
endif
