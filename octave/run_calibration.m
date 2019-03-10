% calibration buffer is updated every cycle to avoid waiting for fill-up
calBuffer = [calBuffer; buffer];
currentSize = rows(calBuffer);

if (currentSize < calibrationSize)
  % not enough data, cannot run calibration
  if (statusContains(CALIBRATING))
    setStatusResult(CALIBRATING, NOT_FINISHED_RESULT);
  endif
else
  % purging old samples from analysis buffer to cut calBuffer to calibrationSize     
  calBuffer = calBuffer(currentSize - calibrationSize + 1: end, :);
  
  if (statusContains(CALIBRATING))
    % running the actual calibration with calBuffer
    [result, runID, sameFreqsCounter, msg] = calibrate(calBuffer, prevFundPeaks, fs, calFreqs, jointDeviceName, calExtraCircuit, restartCal);
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
      if contCal
        restartCal = true;
      else
        source 'stopCalibration.m';
      endif
    endif
  endif
endif

% remember for next round - using peaks calculated by analysis which uses the same procedure
prevFundPeaks = measuredPeaks;