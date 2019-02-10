[result, runID, sameFreqsCounter, msg] = calibrate(buffer, fs, calFreqs, jointDeviceName, calExtraCircuit, restartCal);
setStatusResult(CALIBRATING, result);

% building complete status infomessage
completeMsg = [num2str(sameFreqsCounter(1)) '-' num2str(sameFreqsCounter(2)) '/' num2str(runID) ' ' msg];
setStatusMsg(CALIBRATING, completeMsg);

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
