% input - peaks in absolute values and radians
% returns:
%   printablePeaks [ frequency , amplitude_in_dB, angle_in_degrees ]
%
function printablePeaks = convertPeaksToPrintable(peaks)
  printablePeaks = repmat(peaks, 1);
  printablePeaks(:,2, :) = 20 * log10(printablePeaks(:,2, :));
  printablePeaks(:,3, :) = mod(printablePeaks(:,3, :) * 180/pi, 360);
endfunction
