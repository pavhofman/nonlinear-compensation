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
    end
  else
    % even one channel on non-compensation means status failure
    cause = cell();
    if ~hasAnyPeak(measuredPeaksCh)
      cause{end + 1} = 'measured fundPeaks';
    end
    if ~hasAnyPeak(fundLevelsCh)
      cause{end + 1} = 'fund levels';
    end
    if ~hasAnyPeak(distortPeaksCh)
      cause{end + 1} = 'distortPeaks';
    end
    writeLog('DEBUG',  'No %s available for CH%d, compensation being skipped', strjoin(cause, ' + '), channelID);
    result = FAILING_RESULT;
    % resetting calfile
    compenCalFiles{channelID} = '';
    if hasAnyPeak(measuredPeaksCh) && ~hasAnyPeak(fundLevelsCh)
      % incoming signal, yet not fundLevels from calfile - no valid calibration available (either missing file or outdated calibration)
      msg = sprintf("%s No valid calib. for CH%d.", msg, channelID);
    end
  end
end

setStatusResult(COMPENSATING, result);
setStatusMsg(COMPENSATING, msg);