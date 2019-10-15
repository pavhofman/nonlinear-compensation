% compensation running
% generating buffer-length of compensation reference
result = RUNNING_OK_RESULT;
msg = '';
for channelID = getActiveChannelIDs(chMode, channelCnt)
  measuredPeaksCh = measuredPeaks{channelID};
  distortPeaksCh = distortPeaks{channelID};
  fundLevelsCh = fundLevels{channelID};
  if hasAnyPeak(measuredPeaksCh) && hasAnyPeak(fundLevelsCh) && hasAnyPeak(distortPeaksCh)
    ref = genCompenReference(fundLevelsCh, distortPeaksCh, measuredPeaksCh, fs, startingTs{channelID}, rows(buffer));
    if find(isna(ref))
      writeLog('ERROR',  'Compensation signal contains NA values, investigate!');
    else
      buffer(:, channelID) += ref;
    endif
  else
    % even one channel on non-compensation means status failure
    writeLog('DEBUG',  'No peaks available, compensation being skipped');
    result = FAILING_RESULT;
    % resetting calfile
    compenCalFiles{channelID} = '';
    if hasAnyPeak(measuredPeaksCh) && ~hasAnyPeak(fundLevelsCh)
      % incoming signal, yet not fundLevels from calfile - no calfile found
      msg = [msg ' ' 'No calib. file for CH' num2str(channelID) '.'];
    endif
  endif
endfor

setStatusResult(COMPENSATING, result);
setStatusMsg(COMPENSATING, msg);
% advancing startingsTs to next cycle
startingTs = cellfun(@(x) x + rows(buffer) * 1/fs, startingTs,'un',0);