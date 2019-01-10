result = calibrate(buffer, fs, jointDeviceName, calExtraCircuit, restartCal);
restartCal = false;
if (result == FINISHED_RESULT)
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
