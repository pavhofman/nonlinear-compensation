% Generates compensation reference (distortion peaks with inverted phase). Supports single and dual frequencies
function compenSignal = genCompenReference(fundLevelsCh, distortPeaksCh, measuredPeaksCh, fs, startingT, samplesCnt)
  % consts
  persistent PI2 = 2 * pi;

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
  t = linspace(startingT, startingT + (samplesCnt - 1) * step, samplesCnt);
    
  distortFreqs = distortPeaksCh(:, 1);
  origDistortGains = distortPeaksCh(:, 2);
  origDistortPhases = distortPeaksCh(:, 3);
  % current phase distortion = original distortion phase + additional phase accumulated in timeOffset
  currentDistortPhases = origDistortPhases + PI2 * distortFreqs * timeOffset;
  % inverted phases
  compenDistortPhases = currentDistortPhases - pi;
  compenDistortGains = origDistortGains * scale;
  % compensation signal for this distortion
  compenSignals = cos(PI2 * distortFreqs * t + compenDistortPhases) .* compenDistortGains;
  % adding all rows
  compenSignal = sum(compenSignals, 1);
  % output in rows
  compenSignal = transpose(compenSignal);
end