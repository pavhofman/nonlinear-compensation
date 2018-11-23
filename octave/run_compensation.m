% compensation running
% generating buffer-length of compensation reference
for i = 1:columns(buffer)  
  buffer(:, i) += genCompenReference(fundPeaks(:, :, i), distortPeaks(:, :, i), measuredPeaks(:, :, i), fs, startingT, rows(buffer));
endfor

% advancing startingT to next cycle
startingT += rows(buffer) * 1/fs;
