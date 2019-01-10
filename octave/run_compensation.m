% compensation running
% generating buffer-length of compensation reference
for channelID = 1:columns(buffer)
  measuredPeaksCh = measuredPeaks(:, :, channelID);
  fundPeaksCh = fundPeaks(:, :, channelID);
  if hasAnyPeak(measuredPeaksCh) && hasAnyPeak(fundPeaksCh)
    buffer(:, channelID) += genCompenReference(fundPeaksCh, distortPeaks(:, :, channelID), measuredPeaksCh, fs, startingT, rows(buffer));
  endif
endfor

% advancing startingT to next cycle
startingT += rows(buffer) * 1/fs;
