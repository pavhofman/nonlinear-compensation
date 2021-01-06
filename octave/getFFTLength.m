% finding optimal FFT length which best fits all fundamentals in measuredPeaksCh.
% Possible values are between fs/4 and maxSamples
function newLength = getFFTLength(fs, measuredPeaksCh, maxSamples)

  freqs = measuredPeaksCh(:, 1);

  % starting from fs/4
  minSamples = round(fs/(2 * 2));
  newBinCounts = minSamples:maxSamples;
  newBinWidths = fs/2 ./ newBinCounts;
  newBinIDs = round(freqs ./ newBinWidths);

  newBinFreqs = newBinIDs .* newBinWidths;
  squaredDiffs = (newBinFreqs - freqs).^2;
  [minVal, minID] = min(sum(squaredDiffs, 1));
  newLength = newBinCounts(minID) * 2;

  % checking
  % bestBinIDs = newBinIDs(:, minID);
  % bestBinFreq = newBinFreqs(:, minID);
  % errorDetFreqs = abs(bestBinFreq - freqs);
  % dbError = 20*log10(errorDetFreqs ./ freqs);
end