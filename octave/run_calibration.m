result = calibrate(buffer, fs, jointDeviceName, calExtraCircuit, restartCal);
restartCal = false;
if (result == FINISHED_RESULT)
  % turn off calibration
  status = removeFromStatus(status, CALIBRATING);
  if isempty(status)
    cmd = {PASS};
  endif
endif
