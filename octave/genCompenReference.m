% Generates compensation reference (distortion peaks with inverted phase). Supports only single fundamental frequency, for now.
function compenSignal = genCompenReference(fundPeaks, distortPeaks, measuredPeaks, fs, startingT, samplesCnt)
  % first harmonics = zero
  compenSignal = zeros(samplesCnt, 1);
  % for now only single fundamental frequency
  measFreq = measuredPeaks(1, 1);
  origFundAmpl = fundPeaks(1, 2);
  origFundPhase = fundPeaks(1, 3);
  
  currFundAmpl = measuredPeaks(1, 2);
  currFundPhase = measuredPeaks(1, 3);
  
  currFundPhaseShift = currFundPhase - origFundPhase;
  % we need the phase shift within interval <0, 2*pi>
  if (currFundPhaseShift < 0)
    currFundPhaseShift += 2 * pi;
  endif
  % time offset between current time and calibration time within single period of the signal
  timeOffset = currFundPhaseShift/(2 * pi * measFreq);

  scale = currFundAmpl / origFundAmpl;
  step = 1/fs;
  t = linspace(startingT, startingT + (samplesCnt - 1) * step, samplesCnt)';

  for i = (1:length(distortPeaks))
    origDistortGain = distortPeaks(i, 2);
    if (origDistortGain > 1e-8)
      distortFreq = distortPeaks(i, 1);
      origDistortPhase = distortPeaks(i, 3);
      % current phase distortion = original distortion phase + additional phase accumulated in timeOffset
      currentDistortPhase = origDistortPhase + 2 * pi * distortFreq * timeOffset;
      % inverted phase
      compenDistortPhase = currentDistortPhase - pi;
      compenDistortGain = origDistortGain * scale;
      % compensation signal for this distortion
      compenSignal += cos(2*pi * distortFreq * t + compenDistortPhase) * compenDistortGain;
     endif
  endfor
endfunction
