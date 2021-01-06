% shift all distort phases to time zero (i.e. where all fund phases = 0)
% fundPeaksCh not empty!
function distortPeaksCh = phasesAtZeroTimeCh(fundPeaksCh, distortPeaksCh)  
  zeroPhaseFundPeaksCh = fundPeaksCh;
  % zero phase, keep rest
  zeroPhaseFundPeaksCh(:, 3) = 0;
  
  timeOffset = determineTimeOffset(zeroPhaseFundPeaksCh, fundPeaksCh);
  
  % all distortions must be rotated timeOffset ahead
  for i = (1:rows(distortPeaksCh))
    distortFreq = distortPeaksCh(i, 1);
    distortPhase = distortPeaksCh(i, 3);
    % zero-time phase distortion = distortion phase - phase accumulated in timeOffset
    zeroTimeDistortPhase = distortPhase - 2 * pi * distortFreq * timeOffset;
    distortPeaksCh(i, 3) = zeroTimeDistortPhase;
  end
end