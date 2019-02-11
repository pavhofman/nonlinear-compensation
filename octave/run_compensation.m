% compensation running
% generating buffer-length of compensation reference
result = RUNNING_OK_RESULT;
msg = '';
for channelID = 1:columns(buffer)
  measuredPeaksCh = measuredPeaks{channelID};
  distortPeaksCh = distortPeaks{channelID};
  fundPeaksCh = fundPeaks{channelID};
  if hasAnyPeak(measuredPeaksCh) && hasAnyPeak(fundPeaksCh) && hasAnyPeak(distortPeaksCh)
    ref = genCompenReference(fundPeaksCh, distortPeaksCh, measuredPeaksCh, fs, startingT, rows(buffer));
    if find(isna(ref))
      printf('ERROR - compensation signal contains NA values, investigate!');
    else
      buffer(:, channelID) += ref;
    endif
  else
    % even one channel on non-compensation means status failure
    result = FAILING_RESULT;
    % resetting calfile
    compenCalFiles{channelID} = '';
    if hasAnyPeak(measuredPeaksCh) && ~hasAnyPeak(fundPeaksCh)
      % incoming signal, yet not fundPeaks from calfile - no calfile found
      msg = [msg ' ' 'No calib. file for CH' num2str(channelID) '.'];
    endif
  endif
endfor

setStatusResult(COMPENSATING, result);
setStatusMsg(COMPENSATING, msg);
% advancing startingT to next cycle
startingT += rows(buffer) * 1/fs;
