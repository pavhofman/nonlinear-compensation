result = calibrate(buffer, fs, jointDeviceName, calExtraCircuit, restartCal);
restartCal = false;
if (result == FINISHED_RESULT)
  % turn off calibration
  removeFromStatus(CALIBRATING);
  if isempty(status)
    cmd = {PASS};
  endif
endif
