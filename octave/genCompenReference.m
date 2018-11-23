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
  scale = currFundAmpl / origFundAmpl;
  step = 1/fs;
  t = linspace(startingT, startingT + (samplesCnt - 1) * step, samplesCnt)';

  for i = (1:length(distortPeaks))
    origDistortGain = distortPeaks(i, 2);
    if (origDistortGain > 1e-8)
      distortFreq = distortPeaks(i, 1);
      distortFreqRatio = distortFreq/measFreq;
      origDistortPhase = distortPeaks(i, 3);
      % current phase distortion
      currentDistortPhase = origDistortPhase + currFundPhaseShift * distortFreqRatio;
      % inverted phase
      compenDistortPhase = currentDistortPhase - pi;
      compenDistortGain = origDistortGain * scale;
      % compensation signal for this distortion
      compenSignal += cos(2*pi * distortFreq * t + compenDistortPhase) * compenDistortGain;
     endif
  endfor
endfunction
