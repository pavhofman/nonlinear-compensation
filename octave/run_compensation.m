% compensation running
% generating buffer-length of compensation reference
for channelID = 1:columns(buffer)  
  buffer(:, channelID) += genCompenReference(fundPeaks(:, :, channelID), distortPeaks(:, :, channelID), measuredPeaks(:, :, channelID), fs, startingT, rows(buffer));
endfor

% advancing startingT to next cycle
startingT += rows(buffer) * 1/fs;
