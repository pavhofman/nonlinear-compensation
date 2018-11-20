% compensation running
% generating buffer-length of compensation reference
for i = 1:columns(buffer)
  ampl = measuredParams(i, 1);
  phase = measuredParams(i, 2);
  buffer(:, i) += genCompenReference(fundPeaks(:, :, i), distortPeaks(:, :, i), phase, ampl, fs, startingT, rows(buffer));
endfor

% advancing startingT to next cycle
startingT += rows(buffer) * 1/fs;
