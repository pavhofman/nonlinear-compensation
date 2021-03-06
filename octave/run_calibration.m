% calibration buffer is updated every cycle to avoid waiting for fill-up
calBuffer = [calBuffer; buffer];
currentSize = rows(calBuffer);

if (currentSize < calBufferSize)
  % not enough data, cannot run calibration
  if (statusContains(CALIBRATING))
    setStatusResult(CALIBRATING, NOT_FINISHED_RESULT);
  end
else
  % purging old samples from analysis buffer to cut calBuffer to calBufferSize
  calBuffer = calBuffer(currentSize - calBufferSize + 1: end, :);
  
  if (statusContains(CALIBRATING))
    % running the actual calibration with calBuffer
    [result, runID, correctRunsCounter, msg] = calibrate(calBuffer, measuredPeaks, fs, calRequest, chMode, restartCal, nonInteger);
    setStatusResult(CALIBRATING, result);

    % building complete status infomessage
    % correctRunsCounter - row = channel
    completeMsg = sprintf('%d - %d/%d %s', correctRunsCounter(1), correctRunsCounter(2), runID, msg);
    setStatusMsg(CALIBRATING, completeMsg);

    restartCal = false;
    if isResultFinished(result)
      % end of calibration

      if isResultOK(result)
        % new calfile, instruct analysis to reload
        % NOTE - reloading calfiles makes sense only when calibration generates same calfiles as compensation is instructed to use
        % which often is not the case
        % Nevertheless relading calfiles makes no damage, let's keep it here
        reloadCalFiles = true;
      end
            
      if calRequest.contCal || (~isResultOK(result) && ~isempty(calRequest.calFreqReq));
        % restarting calibration if continuous calibration OR some calibration frequency/level was requested  while calibration failed (i.e. freqs or levels not reached)
        restartCal = true;
      else
        source 'stop_calibration.m';
      end
    end
  end
end