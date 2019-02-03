result = calibrate(buffer, fs, jointDeviceName, calExtraCircuit, restartCal);
restartCal = false;
if (result == FINISHED_RESULT)
  % turn off calibration
  removeFromStatus(CALIBRATING);
  % calibration command finished
  cmdDoneID = cmdID;
  
  if isempty(status)
    cmd = {PASS};
  endif
endif
