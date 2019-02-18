% Generates compensation reference (distortion peaks with inverted phase). Supports single and dual frequencies
function compenSignal = genCompenReference(fundLevelsCh, distortPeaksCh, measuredPeaksCh, fs, startingT, samplesCnt)
  % first harmonics = zero
  compenSignal = zeros(samplesCnt, 1);
  % for now only single fundamental frequency
  measFreq = measuredPeaksCh(1, 1);
  origFundAmpl = fundLevelsCh(1, 2);
  currFundAmpl = measuredPeaksCh(1, 2);
  
  % time offset between current time and calibration time within single period of the signal
  % we need peaks format (phase always = 0)
  fundPeaksCh = [fundLevelsCh, zeros(rows(fundLevelsCh), 1)];
  timeOffset = determineTimeOffset(fundPeaksCh, measuredPeaksCh);
  
  scale = currFundAmpl / origFundAmpl;
  step = 1/fs;
  t = linspace(startingT, startingT + (samplesCnt - 1) * step, samplesCnt)';
  pi2 = 2 * pi;
  for i = (1:rows(distortPeaksCh))
    origDistortGain = distortPeaksCh(i, 2);
    distortFreq = distortPeaksCh(i, 1);
    origDistortPhase = distortPeaksCh(i, 3);
    % current phase distortion = original distortion phase + additional phase accumulated in timeOffset
    currentDistortPhase = origDistortPhase + pi2 * distortFreq * timeOffset;
    % inverted phase
    compenDistortPhase = currentDistortPhase - pi;
    compenDistortGain = origDistortGain * scale;
    % compensation signal for this distortion
    compenSignal += cos(pi2 * distortFreq * t + compenDistortPhase) * compenDistortGain;     
  endfor
endfunction