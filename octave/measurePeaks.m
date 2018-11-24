% Determining fundamental and distortion peaks in buffer.
% The decision between fundamental and distorion freqs is performed on first channel for now
function [freqs, fundPeaks, distortPeaks] = measurePeaks(buffer, fs)
  [fundPeaks, distortPeaks, errorMsg, x, y] = getHarmonics(buffer, fs);

  printf('Determined fundamental peaks:\n');
  disp(fundPeaks);
  printf('Determined distortion peaks:\n');
  disp(distortPeaks);

  % first column
  freqs = fundPeaks(:, 1);
endfunction
