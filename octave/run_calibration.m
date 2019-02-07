result = calibrate(buffer, fs, calFreqs, jointDeviceName, calExtraCircuit, restartCal);
setStatusResult(CALIBRATING, result);
restartCal = false;
if isResultFinished(result)
  % end of calibration
  if isResultOK(result)
    % new calfile, instruct analysis to reload
    reloadCalFiles = true;
  endif

  % turn off calibration
  removeFromStatus(CALIBRATING);
  % calibration command finished
  cmdDoneID = cmdID;
  
  if numfields(statusStruct) == 0
    cmd = {PASS};
  endif
endif
