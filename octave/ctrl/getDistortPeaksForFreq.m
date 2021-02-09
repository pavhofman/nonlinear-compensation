% if not found, returns empty
function distortPeaks = getDistortPeaksForFreq(freq, complAllPeaksCh, distortFreqs)
  global PEAKS_START_IDX;
  % index of freq in distortFreqs
  % support for nonInteger freqs
  freqID = find(round(distortFreqs) == round(freq));
  if ~isempty(freqID)
    % all rows
    distortPeaks = complAllPeaksCh(:, PEAKS_START_IDX + freqID - 1);
  else
    distortPeaks = [];
  end
end