[freqs, result] = calibrate(buffer, fs, jointDeviceName, extraCircuit, restartCal);
restartCal = false;
if (result == 1)
  % finished
  % request compensation
  cmd = {COMPENSATE; jointDeviceName};
  % tell analysis to re-read the updated calibration file
  restartAnalysis = true;
endif
