[freqs, result] = calibrate(buffer, fs, jointDeviceName, calExtraCircuit, freqs, restartCal);
restartCal = false;
if (result == 1)
  % finished
  % request joint-device compensation for calExtraCircuit
  if (length(calExtraCircuit) > 0)
    cmd = {COMPENSATE; jointDeviceName; calExtraCircuit};
  else
    cmd = {COMPENSATE; jointDeviceName};
  endif
  % tell analysis to re-read the updated calibration file
  restartAnalysis = true;
endif
