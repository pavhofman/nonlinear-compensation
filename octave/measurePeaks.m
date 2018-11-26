% Determining fundamental and distortion peaks in buffer.
function [freqs, fundPeaks, distortPeaks] = measurePeaks(buffer, fs)
  [fundPeaks, distortPeaks, errorMsg, x, y] = getHarmonics(buffer, fs);

  printf('Determined fundamental peaks:\n');
  disp(fundPeaks);
  printf('Determined distortion peaks:\n');
  disp(distortPeaks);

  % freqs read from first channel only
  freqs = fundPeaks(:, 1, 1);
endfunction
