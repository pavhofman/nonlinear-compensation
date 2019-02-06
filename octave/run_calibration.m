result = calibrate(buffer, fs, calFreqs, jointDeviceName, calExtraCircuit, restartCal);
restartCal = false;
if result == FINISHED_RESULT || result == FAILED_RESULT
  % end of calibration
  if result == FINISHED_RESULT 
    % new calfile, instruct analysis to reload
    reloadCalFiles = true;
  endif

  % turn off calibration
  removeFromStatus(CALIBRATING);
  % calibration command finished
  cmdDoneID = cmdID;
  
  if isempty(status)
    cmd = {PASS};
  endif
endif
