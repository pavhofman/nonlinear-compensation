% compensation running
% generating buffer-length of compensation reference
for channelID = 1:columns(buffer)
  measuredPeaksCh = measuredPeaks(:, :, channelID);
  distortPeaksCh = distortPeaks(:, :, channelID);
  fundPeaksCh = fundPeaks(:, :, channelID);
  if hasAnyPeak(measuredPeaksCh) && hasAnyPeak(fundPeaksCh)
    ref = genCompenReference(fundPeaksCh, distortPeaksCh, measuredPeaksCh, fs, startingT, rows(buffer));
    if find(isna(ref))
      printf('ERROR - compensation signal contains NA values, investigate!');
    else
      buffer(:, channelID) += ref;
    endif
  endif
endfor

% advancing startingT to next cycle
startingT += rows(buffer) * 1/fs;
