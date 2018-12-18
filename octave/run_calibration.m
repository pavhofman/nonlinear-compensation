[freqs, result] = calibrate(buffer, fs, jointDeviceName, calExtraCircuit, freqs, restartCal);
restartCal = false;
if (result == 1)
  % finished
  % request compensation
  cmd = {COMPENSATE; jointDeviceName};
  % tell analysis to re-read the updated calibration file
  restartAnalysis = true;
endif
