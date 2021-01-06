% introduce distortion to buffer
if ~isempty(distortHarmAmpls)
  % default value
  result = FAILING_RESULT;
  msg = '';
  for channelID = 1:channelCnt
    measuredPeaksCh = measuredPeaks{channelID};
    if hasAnyPeak(measuredPeaksCh)
      % distort
      % scaling to 1 for the chebyshev filters to work correctly!
      % this works correctly only for single tones
      avgAmpl = mean(measuredPeaksCh(:, 2));
      bufferCh = buffer(:, channelID) / avgAmpl;
      
      % adjusting distortion levels to account for signal level, converting from dB to abs values
      % note - db2mag(NA) fails, we have to skip this
      scaledLevels = zeros(1, length(distortHarmAmpls));
      existIDs = find(~isna(distortHarmAmpls));
      % only levels at existIDs
      scaledLevels(existIDs) = distortHarmAmpls(existIDs) / avgAmpl;
      
      distortPoly = genDistortPoly(scaledLevels);

      % distorting with distortPoly
      bufferCh = polyval(distortPoly, bufferCh);
      % scaling back to original amplitude
      bufferCh *= avgAmpl;
      % copying distorted channel back to buffer
      buffer(:, channelID) = bufferCh;
      % one channel already means OK
      result = RUNNING_OK_RESULT;
    end
  end
  % clipping to <-1, 1>
  buffer(buffer > 1) = 1;
  buffer(buffer < -1) = -1;
  
  if result == FAILING_RESULT
    msg = 'No channels distorted due to no fundamentals';
  end
  setStatusResult(DISTORTING, result);
  setStatusMsg(DISTORTING, msg);
end
